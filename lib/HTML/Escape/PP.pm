package HTML::Escape::PP;
use strict;
use warnings;
use warnings FATAL =>'recursion';

use Carp ();

sub RAW_STRING_CLASS() { 'HTML::Escape::RawString' }

sub install {
    no warnings;
    *HTML::Escape::mark_raw          = \&mark_raw;
    *HTML::Escape::unmark_raw        = \&unmark_raw;
    *HTML::Escape::html_escape       = \&html_escape;
    *HTML::Escape::html_concat       = \&html_concat;
    *HTML::Escape::html_join         = \&html_join;
    *HTML::Escape::RAW_STRING_CLASS  = \&RAW_STRING_CLASS;

    @HTML::Escape::RawString::ISA    = qw(HTML::Escape::PP::RawString);
}

my %escape = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
);

my $metachars = sprintf '[%s]', join '', map { quotemeta } keys %escape;

my $RAW_CLASS = RAW_STRING_CLASS;

sub mark_raw {
    my($str) = @_;
    if(defined $str) {
        return ref($str) eq $RAW_CLASS
            ? $str
            : bless \$str, $RAW_CLASS;
    }
    return $str; # undef
}

sub unmark_raw {
    my($str) = @_;
    return ref($str) eq $RAW_CLASS
        ? ${$str}
        :   $str;
}

sub html_escape {
    my($s) = @_;
    return $s if
        ref($s) eq $RAW_CLASS
        or !defined($s);

    $s =~ s/($metachars)/$escape{$1}/xmsgeo;
    return bless \$s, $RAW_CLASS;
}

sub html_concat {
    my $r;
    if(ref($_[0]) eq $RAW_CLASS) {
        $r = shift;
    }
    else {
        $r = \$_[0];
        shift;
    }

    foreach my $s(@_) {
        if(ref($s) eq $RAW_CLASS) {
            ${$r} .= ${$s};
        }
        else {
            (my $escaped = $s) =~ s/($metachars)/$escape{$1}/xmsgeo;
            ${$r} .= $escaped;
        }
    }
    return $r;
}

sub html_join {
    my $sep = html_escape(shift);

    my $r = mark_raw('');
    if(@_) {
        html_concat($r, shift);
        foreach my $s(@_) {
            html_concat($r, $sep, $s);
        }
    }
    return $r;
}

package HTML::Escape::PP::RawString;

use overload
    '""'     => 'as_string',
    '.='     => 'concat',
    '.'      => 'clone_and_concat',

    '='      => 'clone',
    fallback => 1,
;

sub new {
    my($class, $s) = @_;
    if(ref $class) {
        croak("You cannot call $RAW_CLASS->new() as an instance method")
    }
    if($class ne $RAW_CLASS) {
        croak("You cannot extend $RAW_CLASS");
    }
    if(@_ < 2) {
        $s = '';
    }
    if(ref($s) eq $RAW_CLASS) {
        $s = ${$s};
    }
    return bless(\$s, $RAW_CLASS);
}

sub as_string {
    return ${$_[0]};
}

sub clone {
    my $s = ${$_[0]};
    return bless(\$s, $RAW_CLASS);
}

sub clone_and_concat { # infix:<.=>
    my($lhs, $rhs, $reversed) = @_;
    if($reversed) {
        ($lhs, $rhs) = ($rhs, $lhs);

        $lhs = HTML::Escape::html_escape($lhs);
    }
    else {
        $lhs = $lhs->clone();
    }
    return HTML::Escape::html_concat($lhs, $rhs);
}

sub concat { # infix:<.>
    my($lhs, $rhs, $reversed) = @_;
    if($reversed) {
        ($lhs, $rhs) = ($rhs, $lhs);

        if(ref($lhs) ne $RAW_CLASS) {
            $_[0] = $lhs = mark_raw($lhs);
        }
    }
    return HTML::Escape::html_concat($lhs, $rhs);
}

package HTML::Escape::PP;
1;
__END__

=head1 NAME

HTML::Escape::PP - Pure Perl guts for HTML::Escape

=cut
