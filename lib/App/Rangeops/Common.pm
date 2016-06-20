package App::Rangeops::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp;
use Graph;
use List::MoreUtils;
use Path::Tiny;
use YAML::Syck;

use AlignDB::IntSpan;
use App::RL::Common;

sub build_info {
    my $line_refs = shift;
    my $info_of   = shift;

    if ( !defined $info_of ) {
        $info_of = {};
    }

    for my $line ( @{$line_refs} ) {
        for my $part ( split /\t/, $line ) {
            my $info = App::RL::Common::decode_header($part);
            next unless App::RL::Common::info_is_valid($info);

            if ( !exists $info_of->{$part} ) {
                $info_of->{$part} = $info;
            }
        }
    }

    return $info_of;
}

sub sort_links {
    my $line_refs = shift;
    my $numeric   = shift;

    my @lines = @{$line_refs};

    #----------------------------#
    # Cache info
    #----------------------------#
    my $info_of =  build_info( \@lines );

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
