use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help create)] );
like( $result->stdout, qr{create}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(create xt/I.connect.tsv -g xt/genome.fa -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
like( $result->stdout, qr{tgtgtgggtgtggtgtgg}m, 'revcom sequences' );

done_testing();
