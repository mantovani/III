package III::Spider::Terra;

use III::Spider;
use Moose::Role;
use XML::Simple;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use Encode;

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://rss.terra.com.br/0,,EI12879,00.xml'
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
    my $self    = shift;
    my $content = $self->spider->agent->get( $self->link );
    my $xml     = XMLin($content);
    $self->itens($xml);
}

sub itens {
    my ( $self, $xml ) = @_;
    my @itens = @{ $xml->{channel}->{item} };
    foreach my $item (@itens) {

        my $content = $self->spider->agent->get( $item->{link} );
        $self->parser_news(
            $content,
            {
                title       => decode( 'utf8', $item->{title} ),
                source_link => $item->{link}
            }
        );
    }
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    if ( $tree->as_HTML =~ m{<dt>(.+?)</dt>} ) {
        $infs->{author} = $1;
    }

    $infs->{category} = 'Tecnologia';
    $infs->{sub_title} =
      $tree->findvalue('//div[@class="img-article fontsize p1 printing"]/p');
    $infs->{source} = $self->source;
    $infs->{text}   = $tree->findvalue('//div[@id="SearchKey_Text1"]');

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
