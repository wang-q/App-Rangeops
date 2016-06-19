package App::Rangeops::Command::connect;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'connect bilaterial links into multilateral ones';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "verbose|v",   "Verbose mode.", ],
    );
}

sub usage_desc {
    return "rangeops connect [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infiles> are bilaterial links files without hit strands\n";
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
            = Path::Tiny::path( $args->[0] )->absolute . ".cc.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $graph = Graph->new( directed => 0 );
    my $info_of = {};    # info of ranges
    for my $file ( @{$args} ) {
        for my $line ( App::Rangeops::Common::read_lines($file) ) {
            my @parts;
            for my $part ( split /\t/, $line ) {

                my $info = App::RL::Common::decode_header($part);
                next unless App::RL::Common::info_is_valid($info);

                if ( !exists $info_of->{$part} ) {
                    $info_of->{$part} = $info;
                }

                push @parts, $part;
            }

            # all ranges will be converted to positive strands
            next unless @parts == 2;

            my %new_0 = %{ $info_of->{ $parts[0] } };
            my %new_1 = %{ $info_of->{ $parts[1] } };

            my @strands;
            my $hit_strand = "+";
            {
                push @strands, $new_0{strand};
                push @strands, $new_1{strand};
                @strands = List::MoreUtils::PP::uniq(@strands);

                if ( @strands != 1 ) {
                    $hit_strand = "-";
                }

                $new_0{strand} = "+";
                $new_1{strand} = "+";
            }

            my $range_0 = App::RL::Common::encode_header( \%new_0, 1 );
            $info_of->{$range_0} = \%new_0;
            my $range_1 = App::RL::Common::encode_header( \%new_1, 1 );
            $info_of->{$range_1} = \%new_1;

            # add range
            for my $range ( $range_0, $range_1 ) {
                if ( !$graph->has_vertex($range) ) {
                    $graph->add_vertex($range);
                    print STDERR "Add range $range\n" if $opt->{verbose};
                }
            }

            # add edge
            if ( !$graph->has_edge( $range_0, $range_1 ) ) {
                $graph->add_edge( $range_0, $range_1 );
                $graph->set_edge_attribute( $range_0, $range_1, "strand", $hit_strand );

                print STDERR join "\t", @parts, "\n" if $opt->{verbose};
                printf STDERR "Nodes %d \t Edges %d\n",
                    scalar $graph->vertices, scalar $graph->edges
                    if $opt->{verbose};
            }
            else {
                print STDERR " " x 4 . "Edge exists, next\n" if $opt->{verbose};
            }
        }

        print STDERR "==>" . "Finish processing [$file]\n" if $opt->{verbose};
    }

    #----------------------------#
    # Create cc
    #----------------------------#
    my @lines;
    for my $cc ( $graph->connected_components ) {
        my @ranges = @{$cc};
        my $copy   = scalar @ranges;

        next if $copy == 1;

        print STDERR "Copy number of this cc is $copy\n" if $opt->{verbose};

        my $line = join "\t", @ranges;
        push @lines, $line;
    }

    #----------------------------#
    # Sort
    #----------------------------#
    my @sorted_lines = @{ App::Rangeops::Common::sort_links( \@lines, $info_of,
            $opt->{numeric} ) };

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = \*STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} "$_\n" for @sorted_lines;

    close $out_fh;
}

1;
