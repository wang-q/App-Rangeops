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

1;
