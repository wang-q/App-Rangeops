package App::Rangeops::Command::replace;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract =>
    'replace ranges within links and incorporate hit strands';

sub opt_spec {
    return (
        [   "replace|r=s",
            "Two-column tsv file, normally produced by command merge."
        ],
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
    );
}

sub usage_desc {
    return "rangeops sort [options] <infile> <merge.tsv>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc
        .= "\t<infiles> are bi/multilaterial links files, with or without hit strands\n";
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
    my $info_of_range = {};
    my $replace       = {};
    if ( $opt->{replace} ) {
        for my $line ( App::Rangeops::Common::read_lines( $opt->{replace} ) ) {
            my @parts = split /\t/, $line;
            if ( @parts == 2 ) {
                $replace->{ $parts[0] } = $parts[1];
                for my $part (@parts) {
                    if ( !exists $info_of_range->{$part} ) {
                        $info_of_range->{$part}
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
            if ( !exists $info_of_range->{$part} ) {
                $info_of_range->{$part} = App::RL::Common::decode_header($part);
            }

            if ( exists $replace->{$part} ) {
                my $original = $part;
                my $replaced = $replace->{$part};

                # create new hash from reference
                # don't touch anything of $info_of_range
                my %new = %{ $info_of_range->{$replaced} };
                $new{strand} = $info_of_range->{$original}{strand};

                my $new_part = App::RL::Common::encode_header( \%new );
                push @new_parts, $new_part;
            }
            else {
                push @new_parts, $part;
            }
        }
        my $new_line = join "\t", @new_parts;

        # incorporating
        if ( @new_parts == 3 ) {
            my $info_0 = $info_of_range->{ $new_parts[0] };
            my $info_1 = $info_of_range->{ $new_parts[1] };

            if (    App::RL::Common::info_is_valid($info_0)
                and App::RL::Common::info_is_valid($info_1) )
            {
                my $third = pop @new_parts;    # now @new_parts == 2

                if ( $third eq "+" or $third eq "-" ) {
                    my %new_0 = %{$info_0};
                    my %new_1 = %{$info_1};

                    my @strands = ($third);
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

                    @new_parts = (
                        App::RL::Common::encode_header( \%new_0 ),
                        App::RL::Common::encode_header( \%new_1 )
                    );
                    $new_line = join "\t", @new_parts;
                }
            }
        }

        # skip identical ranges
        if ( @new_parts == 2 ) {
            my $info_0 = $info_of_range->{ $new_parts[0] };
            my $info_1 = $info_of_range->{ $new_parts[1] };

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
