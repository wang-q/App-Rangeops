package App::Rangeops::Command::merge;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow Sereal => 1;
use MCE::Candy;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'merge overlapped ranges via overlapping graph';

sub opt_spec {
    return (
        [   "coverage|c=f",
            "When larger than this ratio, merge ranges, default is [0.9]",
            { default => 0.9 }
        ],
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [   "parallel|p=i",
            "Run in parallel mode. Default is [1].",
            { default => 50 },
        ],
        [ "verbose|v", "Verbose mode.", ],
    );
}

sub usage_desc {
    my $self = shift;
    my $desc = $self->SUPER::usage_desc;    # "%c COMMAND %o"
    $desc .= " <infiles>";
    return $desc;
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        $self->usage_error("This command need one or more input files.");
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".merge.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $graph_of_chr  = {};
    my $info_of_range = {};
    for my $file ( @{$args} ) {
        my @lines = Path::Tiny::path($file)->lines( { chomp => 1 } );
        for my $line (@lines) {
            for my $part ( split /\t/, $line ) {
                my $info = App::RL::Common::decode_header($part);
                next unless App::RL::Common::info_is_valid($info);

                my $chr = $info->{chr};
                if ( !exists $graph_of_chr->{$chr} ) {
                    $graph_of_chr->{$chr} = Graph->new( directed => 0 );
                }

                my $range = App::RL::Common::encode_header( $info, 1 );
                if ( !$graph_of_chr->{$chr}->has_vertex($range) ) {
                    $graph_of_chr->{$chr}->add_vertex($range);
                    $info->{intspan} = AlignDB::IntSpan->new;
                    $info->{intspan}->add_pair( $info->{start}, $info->{end} );
                    $info_of_range->{$range} = $info;
                    print STDERR "Add range $range\n" if $opt->{verbose};
                }
            }
        }
    }

    #----------------------------#
    # Coverages
    #----------------------------#
    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;

        my $chr = $chunk_ref->[0];
        my $wid = MCE->wid;

        my $g      = $graph_of_chr->{$chr};
        my @ranges = sort $g->vertices;
        my @edges;
        for my $i ( 0 .. $#ranges ) {
            my $range_i = $ranges[$i];
            printf STDERR " " x 4 . "Range %d / %d\t%s\n", $i, $#ranges,
                $range_i
                if $opt->{verbose};
            my $set_i = $info_of_range->{$range_i}{intspan};
            for my $j ( $i + 1 .. $#ranges ) {
                my $range_j = $ranges[$j];
                my $set_j   = $info_of_range->{$range_j}{intspan};

                my $i_set = $set_i->intersect($set_j);
                if ( $i_set->is_not_empty ) {
                    my $coverage_i = $i_set->size / $set_i->size;
                    my $coverage_j = $i_set->size / $set_j->size;
                    if (    $coverage_i >= $opt->{coverage}
                        and $coverage_j >= $opt->{coverage} )
                    {
                        push @edges, [ $ranges[$i], $ranges[$j] ];
                        printf STDERR " " x 8
                            . "Merge with Range %d / %d\t%s\n",
                            $j, $#ranges, $range_j
                            if $opt->{verbose};
                    }
                }
            }
        }
        printf "Gather %d edges\n", scalar @edges if $opt->{verbose};

        MCE->gather( $chr, \@edges );
    };
    MCE::Flow::init {
        chunk_size  => 1,
        max_workers => $opt->{parallel},
    };
    my %edge_of = mce_flow $worker, ( sort keys %{$graph_of_chr} );
    MCE::Flow::finish;

    for my $chr ( sort keys %{$graph_of_chr} ) {
        print STDERR " " x 4 . "Add edges to chromosome [$chr]\n"
            if $opt->{verbose};
        for my $edge ( @{ $edge_of{$chr} } ) {
            $graph_of_chr->{$chr}->add_edge( @{$edge} );
        }
    }

    #----------------------------#
    # Merging
    #----------------------------#
    my @lines;
    for my $chr ( sort keys %{$graph_of_chr} ) {
        my $g  = $graph_of_chr->{$chr};
        my @cc = $g->connected_components;

        # filter cc with single range
        @cc = grep { scalar @{$_} > 1 } @cc;

        for my $c (@cc) {
            printf "\n" . " " x 4 . "Merge %s ranges\n", scalar @{$c}
                if $opt->{verbose};
            my $chr       = $info_of_range->{ $c->[0] }{chr};
            my $merge_set = AlignDB::IntSpan->new;
            my @strands;
            my ( $strand, $change );
            for my $range ( @{$c} ) {
                my $set = $info_of_range->{$range}{intspan};
                $merge_set->merge($set);
                push @strands, $info_of_range->{$range}{strand};
            }
            @strands = List::MoreUtils::PP::uniq(@strands);
            if ( @strands == 1 ) {
                $strand = $strands[0];
                $change = 0;
            }
            else {
                $strand = "+";
                $change = 1;
            }
            my $merge_range = "$chr($strand):" . $merge_set->runlist;

            for my $range ( @{$c} ) {
                next if $range eq $merge_range;

                my $range_change = 0;
                if ($change) {
                    my $range_strand = $info_of_range->{$range}{strand};
                    if ( $range_strand ne $strand ) {
                        $range_change = 1;
                    }
                }

                my $line = sprintf "%s\t%s\t%d", $range, $merge_range,
                    $range_change;
                push @lines, $line;
                print " " x 8 . "$line\n" if $opt->{verbose};
            }
        }
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = \*STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} "$_\n" for @lines;

    close $out_fh;
}

1;
