package III::Spider::DGABC;

use III::Spider;
use Moose::Role;
use XML::Simple;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use Encode;

with 'III::Spider::Role';

has 'link' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            Economia =>
              'http://home.dgabc.com.br/canais/rss/caderno.asp?caderno=3',
        };
    },
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'DGABC' );

sub init {
    my $self = shift;
    $self->all_news;
}

sub all_news {
    my $self = shift;
    foreach my $go_link ( keys %{ $self->link } ) {
        my $content = $self->spider->agent->get( $self->link->{$go_link} );
        my $xml     = XMLin($content);
        $self->itens( $xml, { category => $go_link } );
    }
}

sub itens {
    my ( $self, $xml, $category ) = @_;

    my @itens = @{ $xml->{channel}->{item} };
    foreach my $item (@itens) {

        my $content = $self->spider->agent->get( $item->{link} );
        $self->parser_news(
            $content,
            {
                title       => decode( 'utf8', $item->{title} ),
                source_link => $item->{link},
                category    => $category->{category},
            }
        );
    }
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;

    # - Retirando tag em
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);
    $infs->{author} = $1;
    $infs->{source} = $self->source;

    my $text = $tree->findnodes('//div[@id="HOTWordsTxt"]')->[0];

    return unless ($text);

    $infs->{content} = $self->html_clean( '<p>' . $text->as_HTML . '</p>' );
    $infs->{text}    = $text->as_text;

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }

    $self->spider->store($infs);
    $tree->delete;
}

42;
