#!/usr/bin/perl

use strict;
use warnings;

use III::Dispatcher;
use Getopt::Long;

my $dp = III::Dispatcher->new;

chomp( my $spider = $ARGV[0] );
if ( $spider =~ /todos/ ) {
    $dp->init_all;
}
else {
	my $spiders = spiders();
    if ( $spiders->{$spider} ) { $dp->init($spider) }
    else {
        print qq{"$spider" não encontrado.\n};
    }
}

=head2 spiders

Returns the spiders avaliables.

=cut

sub spiders {
    my $files = {};
    opendir( my $dir, 'lib/III/Spider' ) or die;

    while ( my $file = readdir($dir) ) {
        $file =~ s/\.pm//;
        if ( $file !~ /^\.|Role/ ) { $files->{$file} = 1 }
    }
    return $files;
}
