package App::Rangeops::Command::create;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'create blocked fas files from range links';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "genome|g=s", "Reference genome file.", { required => 1 }, ],
    );
}

sub usage_desc {
    return "rangeops create [options] <infiles>";
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
            = Path::Tiny::path( $args->[0] )->absolute . ".fas";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my @links;
    my $info_of = {};
    for my $file ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($file) ) {
            my @parts;
            for my $part ( split /\t/, $line ) {
                my $info = App::RL::Common::decode_header($part);
                next unless App::RL::Common::info_is_valid($info);

                push @parts, $part;
                $info_of->{$part} = $info;
            }
            push @links, join( "\t", @parts );
        }
    }
    @links = List::MoreUtils::PP::uniq(@links);

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

    for my $link (@links) {
        my @ranges = split /\t/, $link;
        for my $range (@ranges) {
            my $info = $info_of->{$range};
            my $location = sprintf "%s:%d-%d", $info->{chr}, $info->{start},
                $info->{end};
            my $seq = App::Rangeops::Common::get_seq_faidx( $opt->{genome},
                $location );
            if ( defined $info->{strand} and $info->{strand} ne "+" ) {
                $seq = App::Fasops::Common::revcom($seq);
            }
            print {$out_fh} ">$range\n";
            print {$out_fh} "$seq\n";
        }
        print {$out_fh} "\n";
    }

    close $out_fh;
}

1;
