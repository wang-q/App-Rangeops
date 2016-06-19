use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help merge)] );
like( $result->stdout, qr{merge}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(merge t/I.links.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 6, 'line count' );
like( $result->stdout, qr{13327\-17227}, 'runlist exists' );

done_testing();
