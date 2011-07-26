#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst;    # Complain loudly if you don't have
                                  # Catalyst::Devel installed or haven't said
                                  # 'make dist' to create a standalone tarball.

name 'III-Web';
all_from 'lib/III/Web.pm';

requires 'Catalyst::Runtime' => '5.80032';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Plugin::Unicode';
requires 'Text::Unaccent';
requires 'DateTime';
requires 'Lingua::PT::UnConjugate';
requires 'URI::Encode';
requires 'Catalyst::View::XML::Feed';

# Backend
requires 'MongoDB';
requires 'Redis';
requires 'Digest::MD5';
requires 'WWW::Mechanize';
requires 'TryCatch';
requires 'Catalyst::Model::MongoDB';
requires 'HTML::Strip';
requires 'Scalar::Util';
requires 'HTML::Cleaner';

requires
  'Config::General';  # This should reflect the config file format you've chosen
                      # See Catalyst::Plugin::ConfigLoader for supported formats
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
