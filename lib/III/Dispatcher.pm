package III::Dispatcher;

use Moose;
with 'MooseX::Traits';

sub init {
    my ( $self, $spider ) = @_;
    my $execute =
      III::Dispatcher->with_traits( 'III::Spider::' . $spider )->new;
    $execute->init;
}

sub init_all {
    my $self = shift;
    opendir my $dir, 'lib/III/Spider/' or die $!;
    while ( my $spider = readdir($dir) ) {
        next if $spider =~ /^\.|Role/;
        $spider =~ s/\.pm//;
		print "$spider\n";
        $self->init($spider);
    }
}

42;
