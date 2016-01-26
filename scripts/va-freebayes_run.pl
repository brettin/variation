#!/usr/bin/env perl

use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use strict;

my ($help, $ploidy, $fasta_reference, $align_dir, @bams, $output_file);
$help   = 0;
$ploidy = 1;
@bams   = ();

GetOptions(
        'h'     => \$help,
	'rg=s'  => \$fasta_reference,
	'ad=s'  => \$align_dir,
	'bam=s' => \@bams,
	'o=s'   => \$output_file,
	'p=i'   => \$ploidy,
	
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ! $fasta_reference ) or ( ! $output_file )
                    or ( ( ! $align_dir ) and ( ! @bams ) );

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


print "processing files: ", join(", ", @bams), " against $fasta_reference\n";

foreach my $bam ( @bams ) {
  run_command("samtools index $bam") unless -e "$bam.bai";
}

my $cmd = "freebayes -f $fasta_reference ";
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

 freebayes_run.pl -rg <fasta reference genome> -ad <dir where sorted bam files reside>   -o <output file>
 freebayes_run.pl -rg <fasta reference genome> -bam <comma separated list of bam files> -o <output file>

=head1  DESCRIPTION

Wrapper to execute freebayes on a set of sorted bam files.

=head1  OPTIONS

=over

=item    -h

 Basic usage documentation.

=item	-rg

 Reference genome in fasta format.

=item	-ad

 Alignment directory that contains the sorted bam files.

=item	-bam

 Comma separated list of sorted bam files with no whitespaces.

=item	-o

 Fullname of the output file.

=back

=head1  AUTHORS

=cut
