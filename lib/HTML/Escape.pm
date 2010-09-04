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
);
our %EXPORT_TAGS = (
    all  => \@EXPORT_OK,
);


# load the guts
my $pp = $ENV{HTML_ESCAPE_PP} || $ENV{PERL_NO_XS};

my $backend;
if(!exists $INC{'HTML/Escape/PP.pm'}) {
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

HTML::Escape - Type-based HTML escaping to implement safe HTML builders/templates

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

HTML::Escape provides blah blah blah.

The idea of type-based escaping is originated from Text::MicroTemplate.

=head1 INTERFACE

=head2 Exportable functions

=head3 B<< mark_raw($str :Any) :RawString >>

=head3 B<< unmark_raw($str :Any) :Str >>

=head3 B<< html_escape($str :Any) :RawString >>

=head3 B<< html_escape_force($str :Any) :RawString >>

=head3 C<< html_concat($str0 :Any, ... :Any) :RawString >>

=head3 C<< html_join($separator :Any, ... :Any) :RawString >>

=head2 Constants

=head3 HTML::Escape::BACKEND()

Represents the backend, namely C<XS> or C<PP>.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

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
