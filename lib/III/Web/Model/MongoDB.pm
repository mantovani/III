package III::Web::Model::MongoDB;

use Moose;
BEGIN { extends 'Catalyst::Model::MongoDB' }

__PACKAGE__->config(
    host           => 'localhost',
    port           => '27017',
    dbname         => 'iii',
    collectionname => '',
    gridfs         => '',
);

sub all_categorys {
    shift->c('category')->query( {}, { sort_by => { category => 1 } } );
}

sub last_by_category {
    my ( $self, $category ) = @_;
    $self->c('news')->query( { category => $category },
        { limit => 10, sort_by => { timestamp => -1 } } );
}

=head1 NAME

III::Web::Model::MongoDB - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<III::Web>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
