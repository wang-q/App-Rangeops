package App::Rangeops::Command::sort;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'sort links and ranges within links';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "numeric|n",   "Sort chromosome names numerically.", ],
    );
}

sub usage_desc {
    return "rangeops sort [options] <infiles>";
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
            = Path::Tiny::path( $args->[0] )->absolute . ".sort.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my @lines;
    my $info_of_range = {};
    for my $file ( @{$args} ) {
        for my $line ( App::Rangeops::Common::read_lines($file) ) {
            for my $part ( split /\t/, $line ) {
                my $info = App::RL::Common::decode_header($part);
                next unless App::RL::Common::info_is_valid($info);

                push @lines, $line;    # May produce duplicated lines
                if ( !exists $info_of_range->{$part} ) {
                    $info_of_range->{$part} = $info;
                }
            }
        }
    }
    @lines = List::MoreUtils::PP::uniq(@lines);

    #----------------------------#
    # Sort within links
    #----------------------------#
    for my $line (@lines) {
        my @parts = split /\t/, $line;
        my @invalids = grep { !exists $info_of_range->{$_} } @parts;
        my @ranges   = grep { exists $info_of_range->{$_} } @parts;

        # chromosome strand
        @ranges = map { $_->[0] }
            sort { $a->[1] cmp $b->[1] }
                map { [ $_, $info_of_range->{$_}{strand} ] } @ranges;

        # start point on chromosomes
        @ranges = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_, $info_of_range->{$_}{start} ] } @ranges;

        # chromosome name
        if ( $opt->{numeric} ) {
            @ranges = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map { [ $_, $info_of_range->{$_}{chr} ] } @ranges;
        }
        else {
            @ranges = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map { [ $_, $info_of_range->{$_}{chr} ] } @ranges;
        }

        $line = join "\t", ( @ranges, @invalids );
    }

    #----------------------------#
    # Sort by first range's chromosome order among links
    #----------------------------#
    {
        # after swapping, remove dups again
        @lines = sort @lines;
        @lines = List::MoreUtils::PP::uniq(@lines);

        # strand
        @lines = map { $_->[0] }
            sort { $a->[1] cmp $b->[1] }
                map {
                    my $first = ( split /\t/ )[0];
                    [ $_, $info_of_range->{$first}{strand} ]
                } @lines;

        # start
        @lines = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map {
            my $first = ( split /\t/ )[0];
            [ $_, $info_of_range->{$first}{start} ]
            } @lines;

        # chromosome name
        if ( $opt->{numeric} ) {
            @lines = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of_range->{$first}{chr} ]
                } @lines;
        }
        else {
            @lines = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of_range->{$first}{chr} ]
                } @lines;
        }
    }

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
