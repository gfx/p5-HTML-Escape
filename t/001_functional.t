#!perl -w

use strict;
use Test::More;

use HTML::Escape qw(:all);

is html_escape(q{<foobar>}),   q{&lt;foobar&gt;};
is html_escape(q{<<>>&&''""}), q{&lt;&lt;&gt;&gt;&amp;&amp;&apos;&apos;&quot;&quot;};

my $s = html_escape('<foo>');
$s .= " ";
$s .= "<bar>";
is $s, "&lt;foo&gt; &lt;bar&gt;";

my $t = $s->clone();
$t .= " <baz>";
is $s, "&lt;foo&gt; &lt;bar&gt;";
is $t, "&lt;foo&gt; &lt;bar&gt; &lt;baz&gt;";

is qq{"$s"}, "&quot;&lt;foo&gt; &lt;bar&gt;&quot;";

$s = html_escape "<foo>";
is $s,             "&lt;foo&gt;";
is $s . $s,        "&lt;foo&gt;" x 2;
is $s,             "&lt;foo&gt;";

$s = html_escape "<foo>";
$s .= $s;
is $s,            ("&lt;foo&gt;" x 2) or die "Oops";

$s = html_escape "<foo>";
is $s . $s . $s,   "&lt;foo&gt;" x 3;


$s = "<br />";
html_concat $s, "<foo>";
is $s, "&lt;br /&gt;&lt;foo&gt;";
is html_escape($s), "&lt;br /&gt;&lt;foo&gt;";

$s = mark_raw "<br />";
html_concat $s, "<foo>";
is $s, "<br />&lt;foo&gt;";
is html_escape($s), "<br />&lt;foo&gt;";

my $x = "<br />";
$s = "";
html_concat $s, $x;
is $s, "&lt;br /&gt;";
is html_escape($s), "&lt;br /&gt;";
is $x, "<br />";
is html_escape($s), "&lt;br /&gt;";

$s = "<br />";
$s .= html_escape("<foo>");
is $s, "&lt;br /&gt;&lt;foo&gt;";
is html_escape($s), "&lt;br /&gt;&lt;foo&gt;";

$s = mark_raw "<br />";
$s .= html_escape("<foo>");
is $s, "<br />&lt;foo&gt;";
is html_escape($s), "<br />&lt;foo&gt;";

is html_join('foo'), '', 'the first argument is separator';

is html_join('',             "<foo>"), "&lt;foo&gt;";
is html_join('', html_escape "<foo>"), "&lt;foo&gt;";
is html_join('', mark_raw    "<foo>"),    "<foo>";

is html_join(q{|}, mark_raw("<p>"), "<foo>", " ", "<bar>", mark_raw("</p>")),
   qq{<p>|&lt;foo&gt;| |&lt;bar&gt;|</p>};

$s = mark_raw '<br />';
is html_escape($s), '<br />';
is html_escape( html_escape($s) ), '<br />';
is html_escape( mark_raw($s) ),   '<br />';
is html_escape( unmark_raw($s) ), '&lt;br /&gt;';
is $s, '<br />';

is html_escape_force('<foo>'),          '&lt;foo&gt;';
is html_escape_force(mark_raw '<foo>'), '&lt;foo&gt;';

done_testing;
