#!perl -w
use strict;
use Benchmark qw(:all);

use HTML::Escape;
use HTML::Escape::PP;
use HTML::Entities qw(encode_entities);

#use Test::More tests => 2;

my $str = do {
    open my $in, '<', $0 or die $!;
    local $/;
    <$in>;
};

#is HTML::Escape::PP::html_escape($str), HTML::Escape::html_escape($str);
#is encode_entities($str),               HTML::Escape::html_escape($str);

cmpthese timethese -1, {
    'H::Escape(XS)' => sub {
        my $s = HTML::Escape::html_escape($str);
     },
    'H::Escape(PP)' => sub {
        my $s = HTML::Escape::PP::html_escape($str);
     },
    'H::Entities' => sub {
        my $s = encode_entities($str);
     },
};
