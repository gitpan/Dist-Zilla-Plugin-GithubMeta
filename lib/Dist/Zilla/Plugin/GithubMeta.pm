package Dist::Zilla::Plugin::GithubMeta;
BEGIN {
  $Dist::Zilla::Plugin::GithubMeta::VERSION = '0.14';
}

# ABSTRACT: Automatically include GitHub meta information in META.yml

use strict;
use warnings;
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use MooseX::Types::URI qw[Uri];
use Cwd;
use IPC::Cmd qw[can_run];

use namespace::autoclean;

has 'homepage' => (
  is => 'ro',
  isa => Uri,
  coerce => 1,
);

has 'remote' => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub {  [ 'origin' ]  },
);

has 'issues' => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'user' => (
  is  => 'rw',
  isa => 'Str',
  predicate => '_has_user',
);

has 'repo' => (
  is  => 'rw',
  isa => 'Str',
  predicate => '_has_repo',
);

sub mvp_multivalue_args { qw(remote) }

sub _acquire_repo_info {
  my ($self) = @_;

  return if $self->_has_user and $self->_has_repo;

  return unless _under_git();
  return unless can_run('git');

  my $git_url;
  for my $remote (@{ $self->remote }) {
    next unless $git_url = $self->_url_for_remote($remote);
    last if $git_url =~ /github\.com/; # Not a Github repository
    undef $git_url;
  }

  return unless $git_url;

  my ($user, $repo) = $git_url =~ m{
    github\.com              # the domain
    [:/] ([^/]+)             # the username (: for ssh, / for http)
    /    ([^/]+?) (?:\.git)? # the repo name
    $
  }ix;

  return unless defined $user and defined $repo;

  $self->user($user) unless $self->_has_user;
  $self->repo($repo) unless $self->_has_repo;
}

sub metadata {
  my $self = shift;

  $self->_acquire_repo_info;

  return unless $self->_has_user and $self->_has_repo;

  my $gh_url  = sprintf 'http://github.com/%s/%s', $self->user, $self->repo;
  my $bug_url = "$gh_url/issues";

  my $home_url = $self->homepage ? $self->homepage->as_string : $gh_url;

  return {
    resources => {
      homepage   => $home_url,
      repository => {
        type => 'git',
        url  => $gh_url,
        web  => $gh_url,
      },
      ($self->issues ? (bugtracker => { web => $bug_url }) : ()),
    }
  };
}

sub _url_for_remote {
  my ($self, $remote) = @_;
  my ($url) = `git remote show -n $remote` =~ /URL: (.*)$/m;

  return $url;
}

sub _under_git {
  return 1 if -e '.git';
  my $cwd = getcwd;
  my $last = $cwd;
  my $found = 0;
  while (1) {
    chdir '..' or last;
    my $current = getcwd;
    last if $last eq $current;
    $last = $current;
    if ( -e '.git' ) {
       $found = 1;
       last;
    }
  }
  chdir $cwd;
  return $found;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[1 is the loneliest number];


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::GithubMeta - Automatically include GitHub meta information in META.yml

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  # in dist.ini

  [GithubMeta]

  # to override the homepage

  [GithubMeta]
  homepage = http://some.sort.of.url/project/

  # to override the github remote repo (defaults to 'origin')
  [GithubMeta]
  remote = github

=head1 DESCRIPTION

Dist::Zilla::Plugin::GithubMeta is a L<Dist::Zilla> plugin to include GitHub L<http://github.com> meta
information in C<META.yml>.

It automatically detects if the distribution directory is under C<git> version control and whether the
C<origin> is a GitHub repository and will set the C<repository> and C<homepage> meta in C<META.yml> to the
appropriate URLs for GitHub.

Based on L<Module::Install::GithubMeta> which was based on
L<Module::Install::Repository> by Tatsuhiko Miyagawa

=head2 ATTRIBUTES

=over

=item C<remote>

The GitHub remote repo can be overriden with this attribute. If not
provided, it defaults to C<origin>.  You can provide multiple remotes to
inspect.  The first one that looks like a GitHub remote is used.

=item C<homepage>

You may override the C<homepage> setting by specifying this attribute. This
should be a valid URL as understood by L<MooseX::Types::URI>.

=item C<issues>

If true, a bugtracker URL will be added to the distribution metadata for the
project's GitHub issues page.

=item C<user>

If given, the C<user> parameter overrides the username found in the GitHub
repository URL.  This is useful if many people might release from their own
workstations, but the distribution metadata should always point to one user's
repo.

=item C<repo>

If give, the C<repo> parameter overrides the repository name found in the
GitHub repository URL.

=back

=head2 METHODS

=over

=item C<metadata>

Required by L<Dist::Zilla::Role::MetaProvider>

=back

=for Pod::Coverage   mvp_multivalue_args

=head1 SEE ALSO

L<Dist::Zilla>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams, Tatsuhiko Miyagawa and Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

