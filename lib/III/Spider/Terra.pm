package III::Spider::Terra;

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
            Tecnologia => 'http://rss.terra.com.br/0,,EI12879,00.xml',
            Esportes   => 'http://rss.terra.com.br/0,,EI1137,00.xml',
            Games      => 'http://rss.terra.com.br/0,,EI1702,00.xml',
            Cinema     => 'http://rss.terra.com.br/0,,EI1176,00.xml',
            Economia => 'http://br.invertia.com/rss/economia/pt-br/feedrss.xml',
            Mundo    => 'http://rss.terra.com.br/0,,EI294,00.xml',
        };
    },
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Terra' );

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
    $self->erase_tag( $tree, $_ ) for ( '//em', '//a[@class="textolinkbold"]' );
    if ( $tree->as_HTML =~ m{<dt>(.+?)</dt>} ) {
        $infs->{author} = $1;
    }

    $infs->{sub_title} =
      $tree->findvalue('//div[@class="img-article fontsize p1 printing"]/p');
    $infs->{source} = $self->source;

    my $text = $tree->findnodes('//div[@id="SearchKey_Text1"]')->[0];
    return unless ($text);

    if ( $infs->{category} =~ /Economia/ ) {
        $self->erase_tag( $text, './/a' );
    }
    $self->erase_tag( $text, './/dl' );

    $infs->{content} = $self->html_clean->clean( $text->as_HTML );
    $infs->{text}    = $text->as_text;

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }

    $self->spider->store($infs);
    $tree->delete;
}

42;
