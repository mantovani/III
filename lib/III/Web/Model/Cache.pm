package III::Web::Model::Cache;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use Cache::Memcached::Fast;

has 'cache' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        new Cache::Memcached::Fast(
            {
                servers         => [ { address => 'localhost:11211', }, ],
                namespace       => 'iii:',
                connect_timeout => 0.2,
                io_timeout      => 0.5,
                close_on_error  => 1,
                compress_threshold => 100_000,
                compress_ratio     => 0.9,
                compress_methods   => [
                    \&IO::Compress::Gzip::gzip,
                    \&IO::Uncompress::Gunzip::gunzip
                ],
                max_failures      => 3,
                failure_timeout   => 2,
                ketama_points     => 150,
                nowait            => 1,
                hash_namespace    => 1,
                serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
                utf8              => ( $^V ge v5.8.1 ? 1 : 0 ),
                max_size          => 512 * 1024,
            }
        );
    }
);

=head1 NAME

III::Web::Model::Cache - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

mantovani,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
