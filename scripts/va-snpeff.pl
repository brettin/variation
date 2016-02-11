#!/usr/bin/env perl

use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use JSON;
use Bio::KBase::Handle qw(decode_handle);

use strict;

my ($help, $ref_db, $vcf_file, $output_file, );
$help   = 0;

GetOptions(
  'h'     => \$help,
	'vcf=s' => \$vcf_file,
	'rdh=s'  => \$ref_db,
	'o=s'   => \$output_file,
	
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ! $ref_db ) or ( ! $vcf_file ) ;

# decode the reference db handle
my $json_handle = decode_handle($ref_db);
my $perl_handle = decode_json($json_handle);
my $tarball = $perl_handle->{file_name};
my $ref_db_dir = $1 if $tarball =~ /(\S+)\.tar/;
die "could not parse ref_db_dir from $tarball" unless $ref_db_dir;

# fetch the reference db tarball from shock
open  H, ">$tarball.handle" or die "can not write handle to disk";
print H $json_handle;
close H;

!system("kbhs-download", "-handle", "$tarball.handle", "-o", "$perl_handle->{file_name}")
  or die "failed to execute kbhs-download", $?;
!system("tar", "-xvf", $perl_handle->{file_name})
  or die "can not untar $perl_handle->{file_name}", $?;
my $ref_genome = "$ref_db_dir";
-e $ref_genome && -d $ref_genome
  or die "could not find snpeff reference genome named $ref_genome";
print "snpeff_ref_genome: $ref_genome\n";

my $cmd = "snpEff.sh eff -v -lof $ref_genome $vcf_file > $output_file";
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
