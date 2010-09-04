#!perl -w

use strict;
use Test::More;

use HTML::Escape qw(:all);

my $a = [];
is html_escape(undef), undef;
is html_escape($a),    $a;

is $a . mark_raw('&'), $a . '&';
is mark_raw('&') . $a, '&' . $a;

done_testing;
