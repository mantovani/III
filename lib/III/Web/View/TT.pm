package III::Web::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    {
        TEMPLATE_EXTENSION => '.tt',
        render_die         => 1,
        DEFAULT_ENCODING   => 'utf-8',
        INCLUDE_PATH       => [
            III::Web->path_to( 'root', 'src' ),
            III::Web->path_to( 'root', 'lib' )
        ],
        WRAPPER => 'site/wrapper',
        TIMER   => 0
    }
);

=head1 NAME

III::Web::View::TT - TT View for III::Web

=head1 DESCRIPTION

TT View for III::Web.

=head1 SEE ALSO

L<III::Web>

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
