package III::Spider::BBC;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use utf8;

with 'III::Spider::Role';

has 'links' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            Mundo  => 'http://www.bbc.co.uk/portuguese/topicos/internacional/',
            Economia => 'http://www.bbc.co.uk/portuguese/topicos/economia/',
            'Ciência' =>
              'http://www.bbc.co.uk/portuguese/topicos/ciencia_e_tecnologia/',
            'Saúde' => 'http://www.bbc.co.uk/portuguese/topicos/saude/',
        };
    },
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'BBC' );

sub init {
    my $self = shift;
    $self->all_news;
}

sub all_news {
    my $self = shift;
    foreach my $link ( keys %{ $self->links } ) {
        my $content = $self->spider->agent->get( $self->links->{$link} );
        $self->itens( $content, { category => $link } );
    }
}

sub itens {
    my ( $self, $html, $category ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($html);
    my @itens =
      $tree->findnodes('//div/div/div[@class="content"]/ul/li//h2/a[1]');
    foreach my $item (@itens) {
        my $content = $self->spider->agent->get( $item->attr('href') );
        $self->parser_news(
            $content,
            {
                source_link => 'http://www.bbc.co.uk' . $item->attr('href'),
                category    => $category->{category},
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{title}    = $tree->findvalue('//div[@class="g-container"]/h1');
    $infs->{author}   = $tree->findvalue('//div[@class="person-info"]/p[1]');
    $infs->{category} = $infs->{category};
    $infs->{source}   = $self->source;
    my $text = $tree->findnodes('//div[@class="bodytext"]')->[0];
    return unless $text;
    $infs->{text}    = $text->as_text;
    $infs->{content} = $self->html_clean( $text->as_HTML );

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
