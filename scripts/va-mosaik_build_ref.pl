#!/usr/bin/env perl

use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use strict;

my $man  = 0;
my $help = 0;
my ($fasta_reference, $output_reference_file);

GetOptions(
        'h'     => \$help,
	'fr=s'  => \$fasta_reference,
	'o=s'   => \$output_reference_file,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or (!$fasta_reference) or (!$output_reference_file);


print "processing file $fasta_reference\n";

my $cmd = "MosaikBuild -fr $fasta_reference -oa $output_reference_file ";
run_command($cmd);

sub run_command {
  my $cmd = shift or die "no command passed to run_command";

  print "running $cmd\n";

  unless (!system $cmd ) {
    print "failed running $cmd\n$!";
    next;
  }
}







=pod

=head1  NAME

mosaik_build_reference.pl

=head1  SYNOPSIS

 mosaik_build_reference.pl -fr <fasta_reference_genome> -o <output_reference_file>
 mosaik_build_ref.pl -fr /reference/Mycobacterium_tuberculosis_H37Rv.fasta -o /reference/Mycobacterium_tuberculosis_H37Rv.rsa

=head1  DESCRIPTION

Wrapper to execute MoaikBuild on a fasta reference genome.

=head1  OPTIONS

=over

=item    -h

Basic usage documentation.

=back

=head1  AUTHORS

[% kb_author %]

=cut
