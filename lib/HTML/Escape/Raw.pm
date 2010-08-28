package HTML::Escape::RawString;
# This is a placeholder to autoloaders
require HTML::Escape;
__END__

=head1 NAME

HTML::Escape::RawString - Raw string type for HTML::Escape

=head1 DESCRIPTION

=head1 INTERFACE

=head2 Methods

=head3 B<< HTML::Escape::RawString->new($str :Str) :RawString >>

=head3 B<< $raw_str->as_string() :String >>

Implementation of C<< operator:<""> >>.

=head3 B<< $raw_str->clone() :RawString >>

Returns a clone of I<$raw_str>.

=head3 B<< $raw_str->clone_and_concat() :RawString >>

Implementation of C<< operator:<.> >>.

=head3 C<< $raw_str->concat() :RawString >>

Implementation of C<< operator:<.=> >>.

=cut
