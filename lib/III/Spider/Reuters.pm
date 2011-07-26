package III::Spider::Reuters;

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
            'Tecnologia' =>
              'http://br.reuters.com/news/archive/internetNews?date=today',
            Mundo => 'http://br.reuters.com/news/archive/worldNews?date=today',
            Economia =>
              'http://br.reuters.com/news/archive/businessNews?date=today',
            Esportes =>
              'http://br.reuters.com/news/archive/sportsNews?date=today',
        };
    },
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Reuters' );

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
    my $tree  = HTML::TreeBuilder::XPath->new_from_content($html);
    my @itens = $tree->findnodes('//div[@class="module"]/div//a[1]');
    foreach my $item (@itens) {
        my $content =
          $self->spider->agent->get( $item->attr('href') . '?sp=true' );
        $self->parser_news(
            $content,
            {
                title       => $item->as_text,
                source_link => 'http://br.reuters.com' . $item->attr('href'),
                category   => $category->{category},
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    my $text = $tree->findnodes('//div[@id="resizeableText"]')->[0];

    return unless $text;

    my $text_author = $text->as_text;
    if ( $text_author =~ s/\(Por\s(.+)\)// ) {
        $infs->{author} = $1;
    }

    $text =~ s/.+?\-\s(.+)/$1/;

    $infs->{category} = $infs->{category};
    $infs->{source}   = $self->source;
    $infs->{text}     = $text->as_text;
    $infs->{content}  = $self->html_clean->clean( $text->as_HTML );

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }

    $self->spider->store($infs);
    $tree->delete;
}

42;
