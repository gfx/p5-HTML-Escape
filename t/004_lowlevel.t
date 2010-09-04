#!perl -w

use strict;
use Test::More;

use HTML::Escape qw(:all);

ok ref(html_escape('')), RAW_STRING_CLASS;
ok ${ html_escape('<foo>') }, '&lt;foo&gt;';

done_testing;
