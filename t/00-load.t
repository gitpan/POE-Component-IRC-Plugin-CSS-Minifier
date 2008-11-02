#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
    use_ok('POE::Component::CSS::Minifier');
	use_ok( 'POE::Component::IRC::Plugin::CSS::Minifier' );
}

diag( "Testing POE::Component::IRC::Plugin::CSS::Minifier $POE::Component::IRC::Plugin::CSS::Minifier::VERSION, Perl $], $^X" );
