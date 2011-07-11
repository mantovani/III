package III::Spider::Folha;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use utf8;

has 'links' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            'Ciência' => 'http://www1.folha.uol.com.br/ciencia/',
            Mundo      => 'http://www1.folha.uol.com.br/mundo/',
            Economia   => 'http://www1.folha.uol.com.br/mercado/',
        };
    },
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Folha' );

sub init {
    my $self = shift;
    $self->all_news;
}

sub all_news {
    my $self = shift;
    foreach my $link ( keys %{ $self->links } ) {
        my $content = $self->spider->agent->get( $self->links->{$link} );
        $self->itens( $content, { categoria => $link } );
    }
}

sub itens {
    my ( $self, $html, $categoria ) = @_;
    my $tree  = HTML::TreeBuilder::XPath->new_from_content($html);
    my @itens = $tree->findnodes('//div[@id="newslist"]//a');
    foreach my $item (@itens) {
        my $content = $self->spider->agent->get( $item->attr('href') );
        $self->parser_news(
            $content,
            {
                title       => $item->as_text,
                source_link => $item->attr('href'),
                categoria   => $categoria->{categoria},
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{author}   = $tree->findvalue('//div[@id="articleBy"]');
    $infs->{category} = $infs->{categoria};
    $infs->{source}   = $self->source;
    $infs->{text}     = $tree->findvalue('//div[@id="articleNew"]/p');

    return if length( $infs->{text} ) < 20;

    if ( $tree->exists('//p[@class="wideVideoPlayer"]') ) {
        my $video = $tree->findnodes('//p[@class="wideVideoPlayer"]')->[0];
        $infs->{text} .= $video->as_HTML;
    }

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
