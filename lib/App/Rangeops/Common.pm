package App::Rangeops::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp;
use Graph;
use IO::Zlib;
use List::MoreUtils;
use Path::Tiny;
use Tie::IxHash;
use YAML::Syck;

use AlignDB::IntSpan;
use App::RL::Common;

sub read_lines {
    my $filename = shift;

    if ( lc $filename eq "stdin" ) {
        my @lines;
        while (<STDIN>) {
            chomp;
            push @lines, $_;
        }
        return @lines;
    }
    else {
        return Path::Tiny::path($filename)->lines( { chomp => 1 } );
    }
}

sub sort_links {
    my $lines_ref = shift;
    my $info_of   = shift;
    my $numeric   = shift;

    my @lines = @{$lines_ref};

    #----------------------------#
    # Sort within links
    #----------------------------#
    for my $line (@lines) {
        my @parts = split /\t/, $line;
        my @invalids = grep { !exists $info_of->{$_} } @parts;
        my @ranges   = grep { exists $info_of->{$_} } @parts;

        # chromosome strand
        @ranges = map { $_->[0] }
            sort { $a->[1] cmp $b->[1] }
            map { [ $_, $info_of->{$_}{strand} ] } @ranges;

        # start point on chromosomes
        @ranges = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, $info_of->{$_}{start} ] } @ranges;

        # chromosome name
        if ($numeric) {
            @ranges = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map { [ $_, $info_of->{$_}{chr} ] } @ranges;
        }
        else {
            @ranges = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map { [ $_, $info_of->{$_}{chr} ] } @ranges;
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
            [ $_, $info_of->{$first}{strand} ]
            } @lines;

        # start
        @lines = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map {
            my $first = ( split /\t/ )[0];
            [ $_, $info_of->{$first}{start} ]
            } @lines;

        # chromosome name
        if ($numeric) {
            @lines = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of->{$first}{chr} ]
                } @lines;
        }
        else {
            @lines = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of->{$first}{chr} ]
                } @lines;
        }
    }

    #----------------------------#
    # Sort by copy number among links (desc)
    #----------------------------#
    {
        @lines = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map { [ $_, scalar( split /\t/ ) ] } @lines;
    }

    return \@lines;
}

1;
