package App::Rangeops::Command::clean;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract =>
    'replace ranges within links, incorporate hit strands and remove nested links';

sub opt_spec {
    return (
        [   "replace|r=s",
            "Two-column tsv file, normally produced by command merge."
        ],
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
    );
}

sub usage_desc {
    return "rangeops clean [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc
        .= "\t<infiles> are bilaterial links files, with or without hit strands\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        my $message = "This command need one or more input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".replace.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $info_of = {};    # info of ranges
    my $replace = {};
    if ( $opt->{replace} ) {
        for my $line ( App::Rangeops::Common::read_lines( $opt->{replace} ) ) {
            my @parts = split /\t/, $line;
            if ( @parts == 2 ) {
                $replace->{ $parts[0] } = $parts[1];
                for my $part (@parts) {
                    if ( !exists $info_of->{$part} ) {
                        $info_of->{$part}
                            = App::RL::Common::decode_header($part);
                    }
                }
            }
        }
    }

    #----------------------------#
    # Replacing and incorporating
    #----------------------------#
    my @lines;
    for my $line ( App::Rangeops::Common::read_lines( $args->[0] ) ) {
        my @new_parts;

        # replacing
        for my $part ( split /\t/, $line ) {

            # valid or invalid parts
            if ( !exists $info_of->{$part} ) {
                $info_of->{$part} = App::RL::Common::decode_header($part);
            }

            if ( exists $replace->{$part} ) {
                my $original = $part;
                my $replaced = $replace->{$part};

                # create new hash from reference
                # don't touch anything of $info_of_range
                my %new = %{ $info_of->{$replaced} };
                $new{strand} = $info_of->{$original}{strand};

                my $new_part = App::RL::Common::encode_header( \%new, 1 );
                push @new_parts, $new_part;
            }
            else {
                push @new_parts, $part;
            }
        }
        my $new_line = join "\t", @new_parts;

        # incorporating
        if ( @new_parts == 3 or @new_parts == 2 ) {
            my $info_0 = $info_of->{ $new_parts[0] };
            my $info_1 = $info_of->{ $new_parts[1] };

            if (    App::RL::Common::info_is_valid($info_0)
                and App::RL::Common::info_is_valid($info_1) )
            {
                my @strands;

                if ( @new_parts == 3 ) {
                    if ( $new_parts[2] eq "+" or $new_parts[2] eq "-" ) {
                        push @strands, pop(@new_parts);    # new @new_parts == 2
                    }
                }

                if ( @new_parts == 2 ) {

                    my %new_0 = %{$info_0};
                    my %new_1 = %{$info_1};

                    push @strands, $new_0{strand};
                    push @strands, $new_1{strand};

                    @strands = List::MoreUtils::PP::uniq(@strands);
                    if ( @strands == 1 ) {
                        $new_0{strand} = "+";
                        $new_1{strand} = "+";
                    }
                    else {
                        $new_0{strand} = "+";
                        $new_1{strand} = "-";
                    }

                    my $range_0 = App::RL::Common::encode_header( \%new_0, 1 );
                    $info_of->{$range_0} = \%new_0;
                    my $range_1 = App::RL::Common::encode_header( \%new_1, 1 );
                    $info_of->{$range_1} = \%new_1;

                    @new_parts = ( $range_0, $range_1 );
                    $new_line = join "\t", @new_parts;
                }
            }
        }

        # skip identical ranges
        if ( @new_parts == 2 ) {
            my $info_0 = $info_of->{ $new_parts[0] };
            my $info_1 = $info_of->{ $new_parts[1] };

            if (    App::RL::Common::info_is_valid($info_0)
                and App::RL::Common::info_is_valid($info_1) )
            {
                if (    $info_0->{chr} eq $info_1->{chr}
                    and $info_0->{start} == $info_1->{start}
                    and $info_0->{end} == $info_1->{end} )
                {
                    $new_line = undef;
                }
            }
        }

        push @lines, $new_line;
    }
    @lines = grep {defined} List::MoreUtils::PP::uniq(@lines);

    #----------------------------#
    # Remove nested links
    #----------------------------#
    # now all @lines (links) are without hit strands
    my %to_remove;
    my $vicinity = 5;
    for my $idx ( 0 .. $#lines - $vicinity ) {

        for my $i ( 0 .. $vicinity - 1 ) {
            for my $j ( $i .. $vicinity - 1 ) {
                my $line_i = $lines[ $idx + $i ];
                my ( $range0_i, $range1_i ) = split /\t/, $line_i;

                my $line_j = $lines[ $idx + $j ];
                my ( $range0_j, $range1_j ) = split /\t/, $line_j;

                next
                    if $info_of->{$range0_i}{chr} ne $info_of->{$range0_j}{chr};
                next
                    if $info_of->{$range1_i}{chr} ne $info_of->{$range1_j}{chr};

                my $intspan0_i = AlignDB::IntSpan->new;
                $intspan0_i->add_pair( $info_of->{$range0_i}{start},
                    $info_of->{$range0_i}{end} );
                my $intspan1_i = AlignDB::IntSpan->new;
                $intspan1_i->add_pair( $info_of->{$range1_i}{start},
                    $info_of->{$range1_i}{end} );

                my $intspan0_j = AlignDB::IntSpan->new;
                $intspan0_j->add_pair( $info_of->{$range0_j}{start},
                    $info_of->{$range0_j}{end} );
                my $intspan1_j = AlignDB::IntSpan->new;
                $intspan1_j->add_pair( $info_of->{$range1_j}{start},
                    $info_of->{$range1_j}{end} );

                if (    $intspan0_i->larger_than($intspan0_j)
                    and $intspan1_i->larger_than($intspan1_j) )
                {
                    $to_remove{$line_j}++;
                }
                elsif ( $intspan0_j->larger_than($intspan0_i)
                    and $intspan1_j->larger_than($intspan1_i) )
                {
                    $to_remove{$line_i}++;
                }
            }
        }
    }
    @lines = grep { !exists $to_remove{$_} } @lines;

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

    print {$out_fh} "$_\n" for @lines;

    close $out_fh;
}

1;
