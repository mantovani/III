package III::Spider::Terra;

use III::Spider;
use Moose::Role;
use XML::Simple;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use Encode;

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
        $self->itens( $xml, { categoria => $go_link } );
    }
}

sub itens {
    my ( $self, $xml, $categoria ) = @_;
    my @itens = @{ $xml->{channel}->{item} };
    foreach my $item (@itens) {

        my $content = $self->spider->agent->get( $item->{link} );
        $self->parser_news(
            $content,
            {
                title       => decode( 'utf8', $item->{title} ),
                source_link => $item->{link},
                categoria   => $categoria->{categoria},
            }
        );
    }
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;

    # - Retirando tag em
    $news =~ s#<em>.+?</em>##ig;
    $news =~
s#<a href=" http://videostore.terra.com.br/Web/AluguelECompra " class="textolinkbold">.+?</a>##ig;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    if ( $tree->as_HTML =~ m{<dt>(.+?)</dt>} ) {
        $infs->{author} = $1;
    }

    $infs->{category} = $infs->{categoria};
    $infs->{sub_title} =
      $tree->findvalue('//div[@class="img-article fontsize p1 printing"]/p');
    $infs->{source} = $self->source;
    $infs->{text}   = $tree->findvalue('//div[@id="SearchKey_Text1"]');

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }

    return unless ( $infs->{text} );

    $self->spider->store($infs);
    $tree->delete;
}

42;
