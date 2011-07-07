#
# This software is copyright (c) 2011 by pp .
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::SkipUnknown;
BEGIN {
  $Dist::Zilla::Plugin::Git::Check::VERSION = '0.001';
}
# ABSTRACT: skip files marked unknown

use Git::Wrapper;

use Moose;
with 'Dist::Zilla::Role::FilePruner';

use Moose::Autobox;



has skipprefix => (is => 'ro', required => 1, default => '');
# -- public methods

sub prune_files {
    my $self = shift ;
    my $git  = Git::Wrapper->new( '.' ) ;
    my @output ;

    # fetch current branch
    my $status = $git->status ;

    my %skipped ;

    my $s = $self->skipprefix ;
    my @regex;
    foreach my $ff ( $status->get( 'unknown' ) ) {
        my $x = $ff->from ;
        $x =~ s/^$s// ;
        $skipped{ $x } = 1 ;
        push @regex, $x if $x =~ m!/$!;
        }
        my $rgx= '^('.join('|',@regex).')';
#    use Data::Dumper ;
#    print STDERR Dumper \%skipped , $rgx;

    for my $file ( $self->zilla->files->flatten ) {
        $self->log_debug(["checking [%s]",$file->name]);
        my $res = $file->name =~ /$rgx/;
        $res++ if $skipped{ $file->name } ;
        next unless $res;

        $self->log( [ 'git skipped %s', $file->name ] ) ;

        $self->zilla->prune_file( $file ) ;
        }

    return 0 ;
    }
__PACKAGE__->meta->make_immutable ;
no Moose ;

1 ;

