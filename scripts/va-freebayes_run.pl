#!/usr/bin/env perl

use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use JSON;
use Bio::KBase::Handle qw(decode_handle);
use strict;

my ($help, $ploidy, $ref_db, $ref_genomee, $align_dir, @bams, $output_file);
$help   = 0;
$ploidy = 1;
@bams   = ();

GetOptions(
        'h'     => \$help,
	'rdh=s'  => \$ref_db,
	'ad=s'  => \$align_dir,
	'bam=s' => \@bams,
	'o=s'   => \$output_file,
	'p=i'   => \$ploidy,
	
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ! $ref_db ) or ( ! $output_file )
                    or ( ( ! $align_dir ) and ( ! @bams ) );

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
my $ref_genome = "$ref_db_dir/$ref_db_dir.fna";
-e $ref_genome
  or die "could not find reference genome named $ref_genome";
print "ref_genome: $ref_genome\n";


my ($oname, $opath) = fileparse($output_file); 

open BAMS, ">$opath/bamfiles" or die "can not open $opath/bamfiles";

if ( @bams ) {
  @bams = split( /,/, join( ',', @bams ) );
}
elsif ( -d $align_dir ) {
  @bams = glob "$align_dir/*.sorted.bam";
}
else {
  die "Houston, we have a problem. No align_dir or list of bam files";
}
print BAMS join ("\n", @bams);
close BAMS;


print "processing files: ", join(", ", @bams), " against $ref_genome\n";

foreach my $bam ( @bams ) {
  run_command("samtools index $bam") unless -e "$bam.bai";
}

my $cmd = "freebayes -f $ref_genome ";
$cmd   .= "-p $ploidy ";
$cmd   .= "-L " . $opath . "bamfiles ";
$cmd   .= "-v $output_file ";




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

freebayes_run.pl

=head1  SYNOPSIS

 freebayes_run.pl -rdh <base64 encoded handle> -ad <dir where sorted bam files reside>   -o <output file>
 freebayes_run.pl -rdh <base64 encoded handle>> -bam <comma separated list of bam files> -o <output file>

=head1  DESCRIPTION

Wrapper to execute freebayes on a set of sorted bam files.

=head1  OPTIONS

=over

=item    -h

 Basic usage documentation.

=item	-rdh

 Base64 encoded shock handle. The shock handle resoves to a tarball that contains a reference database. When unpacked, the top level directory contains the reference genome in fasta format. The name of the top level directory must be the same as the base name for the reference genome fasta file, and the fasta genome file must end in .fna.

=item	-ad

 Alignment directory that contains the sorted bam files.

=item	-bam

 Comma separated list of sorted bam files with no whitespaces.

=item	-o

 Fullname of the output file.

=back

=head1  AUTHORS

=cut
