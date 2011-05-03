
use strict;
use warnings;

BEGIN { require 5.008005; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Automatically include GitHub meta information in META.yml',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>, Ricardo SIGNES <rjbs@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Dist-Zilla-Plugin-GithubMeta',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::Plugin::GithubMeta',
  'PREREQ_PM' => {
    'Dist::Zilla' => '4.101582',
    'Dist::Zilla::Role::MetaProvider' => '4.101582',
    'IPC::Cmd' => '0.58',
    'Moose' => '1.07',
    'MooseX::Types::URI' => '0.02'
  },
  'VERSION' => '0.12',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



