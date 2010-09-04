package HTML::Escape;
use 5.008_001;
use strict;

our $VERSION = '0.0001';

use parent qw(Exporter);
our @EXPORT_OK   = qw(
    mark_raw
    unmark_raw
    html_escape
    html_escape_force
    html_concat
    html_join
    RAW_STRING_CLASS
);
our %EXPORT_TAGS = (
    all  => \@EXPORT_OK,
);

my $backend;
if(!exists $INC{'HTML/Escape/PP.pm'}) {
    my $pp = $ENV{HTML_ESCAPE_PP};
    defined($pp) or $pp = $ENV{PERL_NO_XS};
    if(!$pp) {
        eval {
            require XSLoader;
            XSLoader::load(__PACKAGE__, $VERSION);
            $backend = 'XS';
        };
        die $@ if $@ && ( defined($pp) && $pp eq '0' ); # force XS
    }

    if(!defined(&html_escape)) {
        require 'HTML/Escape/PP.pm';
        $backend = 'PP';
    }
}

if($backend eq 'PP') {
    HTML::Escape::PP->install();
}

sub BACKEND() { $backend }

1;
__END__

=head1 NAME

HTML::Escape - Type-based HTML escaping for HTML generators

=head1 VERSION

This document describes HTML::Escape version 0.0001.

=head1 SYNOPSIS

    use HTML::Escape qw(:all);

    my $html = '';
    html_concat $html, "<foo>";
    # $html is '&lt;foo&gt;';
    html_concat $html, mark_raw("<br />");
    # $html is '&lt;foo&gt;<br />

=head1 DESCRIPTION

HTML::Escape provides HTML escaping mechanism which is useful for HTML
generators, namely, HTML templates and HTML form builders.

The idea of type-based escaping is originated from Text::MicroTemplate,
written by Oku, Kazuho.

=head1 INTERFACE

=head2 Exportable functions

=head3 B<< mark_raw($str :Any) :RawString >>

=head3 B<< unmark_raw($str :Any) :Str >>

=head3 B<< html_escape($str :Any) :RawString >>

=head3 B<< html_escape_force($str :Any) :RawString >>

=head3 C<< html_concat($str0 :Any, ... :Any) :RawString >>

=head3 C<< html_join($separator :Any, ... :Any) :RawString >>

=head3 C<< RAW_STRING_CLASS >>

Returns the raw string class for low-level manipulations.

=head2 Internal functions

=head3 C<HTML::Escape::BACKEND()>

Represents the backend, namely C<XS> or C<PP>.

=head1 INTERNALS

A C<RawString> is just a scalar reference to a normal string blessed with
C<HTML::Escape::RawString::RAW_STRING_CLASS> so that you can create it by
the following code:

    my $str = 'foo';
    my $raw = bless \$str, RAW_STRING_CLASS; # OK

and/or you can get the normal string from the raw string via scalar
dereferencing:

    my $raw = mark_raw('foo');
    my $str = ${$raw}; # OK

=head1 DEPENDENCIES

Perl 5.8.1 or later.

If you have a C compiler, the XS backend will be used.
Otherwise the PP backend will be used.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Text::MicroTemplate>

L<Text::Xslate>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
