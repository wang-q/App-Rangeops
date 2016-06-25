use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help create)] );
like( $result->stdout, qr{create}, 'descriptions' );

done_testing();
