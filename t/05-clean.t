use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help clean)] );
like( $result->stdout, qr{clean}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(clean t/I.links.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{I\(-\):13327-17227}, 'negative first chromosome' );

$result = test_app( 'App::Rangeops' => [qw(clean t/I.sort.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 13, 'line count' );
like( $result->stdout, qr{223003-229357}, 'runlist exists' );

$result = test_app( 'App::Rangeops' => [qw(clean t/I.sort.tsv -r t/I.merge.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
unlike( $result->stdout, qr{223003-229357}, 'runlist merged' );

done_testing();
