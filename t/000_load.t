#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'HTML::Escape' }

diag sprintf "Testing HTML::Escape/%s (%s)",
    $HTML::Escape::VERSION,
    HTML::Escape::BACKEND();

