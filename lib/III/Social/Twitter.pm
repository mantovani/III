package III::Social::Twitter;

use Moose::Role;

use Net::Twitter;
use XML::Simple;

use constant spider_nome => 'Twitter';

use utf8;

our $VERSION = '0.1';

has 'twitter' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        return Net::Twitter->new(
            traits          => [qw/API::REST OAuth API::Search/],
            consumer_key    => 'AZuJskRgsnPOEtHLeSnRA',
            consumer_secret => 'rPZV84dk5pDDL69nciuYsf8NzCNHos76udB5dkWgIXk',
        );
    }
);

sub search {
    my ( $self, $search_palavra ) = @_;

    my $results = eval {
        $self->twitter->search(
            $search_palavra,
            {
                page => 1,
                lang => 'pt',
                rpp  => 100,
            }
        );
    };

    if ($@) {
        $self->logger->error($@);
        return;
    }

    last unless @{ $results->{'results'} };

    return $results;
}

1;
