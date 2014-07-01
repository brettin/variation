use File::Basename;
use strict;
use Getopt::Long; 
use Pod::Usage;

my $help = 0;

my $fastq_dir = 'fastq';
my $build_dir = "/mnt/data/biosamples/SAMN01828242/build";
my $align_dir = "/mnt/data/biosamples/SAMN01828242/align";
my $REFDB = "/mnt/data/reference";
my $REFGENOME = "Mycobacterium_tuberculosis_H37Rv";
my $ANNPE = "/usr/local/bin/2.1.78.pe.ann";
my $ANNSE = "/usr/local/bin/2.1.78.se.ann";
my $THREADS = 4;


GetOptions(
        'h'     => \$help,
	'bd=s'  => \$build_dir,
	'ad=s'  => \$align_dir,
	'ref'   => \$REFGENOME,
	'annpe=s' => \$ANNPE,
	'annse=s' => \$ANNSE,
	't=i'     => \$THREADS,
	'refdb=s' => \$REFDB,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help;


my (@end1, @end2, );
foreach my $fastq (`ls $fastq_dir/*.fastq`) {
  push @end1, $fastq if $fastq =~ /_1.fastq/;
  push @end2, $fastq if $fastq =~ /_2.fastq/;
}
map chomp, @end1;
map chomp, @end2;

# do a bit of error checking
if (@end1 != @end2) {
  die "could not find matching pe files in fastq_dir: $fastq_dir";
}

print "processing files ", join ", ", @end1, @end2, "\n";

# this should be parallel
for (my $i=0; $i<@end1; $i++) {

  # get the basename of each pe set
  my $name1 = fileparse($end1[$i], ("_1.fastq", "_1.fastq.gz"));
  my $name2 = fileparse($end2[$i], ("_2.fastq", "_2.fastq.gz"));
  if ($name1 ne $name2) {
    print "files don't match $end1[$i] $end2[$i]\n";
    next;
  }

  my $cmd1 = "MosaikAligner -in build/$name1.mkb -out align/$name1.mka ";
  $cmd1.= "-ia $REFDB/$REFGENOME.dat -annpe $ANNPE -annse $ANNSE ";
  $cmd1.="-p $THREADS";

  print $cmd1, "\n";

  unless (!system $cmd1 ) {
    print "failed running $cmd1\n$!"; 
    next;
  }
}





=pod

=head1  NAME

mosaik_aling.pl

=head1  SYNOPSIS

Arguements and defaults


 my $fastq_dir = 'fastq';
 my $build_dir = "/mnt/data/biosamples/SAMN01828242/build";
 my $align_dir = "/mnt/data/biosamples/SAMN01828242/align";
 my $REFDB = "/mnt/data/reference";
 my $REFGENOME = "Mycobacterium_tuberculosis_H37Rv";
 my $ANNPE = "/usr/local/bin/2.1.78.pe.ann";
 my $ANNSE = "/usr/local/bin/2.1.78.se.ann";
 my $THREADS = 4;

=head1  DESCRIPTION

Wrapper for the MosaikAlign program.

=head1  OPTIONS

=over

=item   -h

Basic usage documentation

=item	-bd

The location of the output of the MosaikBuild command (build_dir).

=item	-ad

The location of the directory to put the bam files (align_dir).

=item	-annpe=s

ANNPE,

=item	-annse=s

ANNSE,

=item	-t

Number of threads that the aligner should use.

=item	-ref

The filename of the reference genome (prefix only).

=item	-refdb

Path to the directory containing the reference genome.

=back

=head1  AUTHORS

[% kb_author %]

=cut
