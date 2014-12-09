#!/usr/bin/env perl

use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use strict;

my ($help, $snpeff_reference, $vcf_file, $output_file, );
$help   = 0;

GetOptions(
        'h'     => \$help,
	'vcf=s'   => \$vcf_file,
	'rg=s'  => \$snpeff_reference,
	'o=s'   => \$output_file,
	
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ! $snpeff_reference ) or ( ! $vcf_file ) ;


my $cmd = "snpEff.sh eff -v -lof $snpeff_reference $vcf_file > $output_file";
print "COMMAND $cmd\n";


run_command($cmd);

sub run_command {
  my $cmd = shift or die "no command passed to run_command";

  print "running command: $cmd\n";

  unless (!system $cmd ) {
    print "failed running $cmd\n$!";
  }
}







=pod

=head1  NAME

snpeff.pl

=head1  SYNOPSIS

 snpeff.pl -vcf SAMN02567719_Mycobacterium_tuberculosis_H37Rv_uid170532.vcf  \
           -rg Mycobacterium_tuberculosis_H37Rv_uid170532                    \
           -o SAMN02567719_Mycobacterium_tuberculosis_H37Rv_uid170532_snpEff.vcf


 The reference genome that is used to align the reads to must have the same name
 as the snpeff database reference genome.

 The name of the reference genome manifests in the CHROM field of the vcf file.
 The name of the snpeff database reference genome is found using snpEff dump command.

=head1  DESCRIPTION

Wrapper to execute snpEff on a vcf file against an annotated reference. The annotated
reference should be the same genome as the reference that was used in the alignments.

=head1  OPTIONS

=over

=item    -h

 Basic usage documentation.

=item	-vcf

 The input vcf file. The value of the CHROM field should match exactly the chromosome
 name in the snpEEff database (see the snpEff dump subocmmand).

=item	-rg

 Reference genome as a snpEff database.

=item	-o

 Fullname of the output file.

=back

=head1  AUTHORS

=cut
