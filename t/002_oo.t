#!perl -w

use strict;
use Test::More;

use HTML::Escape qw(:all);

my $s = HTML::Escape::RawString->new();

$s->concat("<foo>");
is $s, "&lt;foo&gt;";
$s->concat( mark_raw("<br />") );
is $s, "&lt;foo&gt;<br />";

$s->concat("<bar>");
is $s, "&lt;foo&gt;<br />&lt;bar&gt;";
$s->concat( mark_raw("<br />") );
is $s, "&lt;foo&gt;<br />&lt;bar&gt;<br />";

is html_escape($s), "&lt;foo&gt;<br />&lt;bar&gt;<br />";

is $s->as_string,   "&lt;foo&gt;<br />&lt;bar&gt;<br />";

$s = HTML::Escape::RawString->new("&amp;");
is $s->as_string, "&amp;";
is $s->clone_and_concat(" &"), "&amp; &amp;";
is $s->as_string, "&amp;";

$s = HTML::Escape::RawString->new("&amp;");
is $s->as_string, "&amp;";
is $s->concat(" &"), "&amp; &amp;";
is $s->as_string, "&amp; &amp;";

done_testing;
