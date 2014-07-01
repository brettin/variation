use lib qw(/home/ubuntu/perl5/lib/perl5/);
use File::Basename;
use Proc::ParallelLoop;
use Getopt::Long; 
use Pod::Usage;
use strict;

my $man  = 0;
my $help = 0;

# These will ultimately become command line parameters.

# the directory where the mate pair fastq files reside.
my $fastq_dir = '/mnt/data/biosamples/SAMN01828242/fastq';
my $build_dir = '/mnt/data/biosamples/SAMN01828242/build';

# the suffix on the mate pair files used to construct basename
my $file_suffix_1 = '_1.fastq';
my $file_suffix_2 = '_2.fastq';

GetOptions(
        'h'     => \$help,
	'fd=s'  => \$fastq_dir,
	'bd=s'  => \$build_dir,
	'fs1=s' => \$file_suffix_1,
	'fs2=s' => \$file_suffix_2,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help;


my (@end1, @end2, );
foreach my $fastq (`ls $fastq_dir/*.fastq`) {
  push @end1, $fastq if $fastq =~ /$file_suffix_1/;
  push @end2, $fastq if $fastq =~ /$file_suffix_2/;
}
map chomp, @end1;
map chomp, @end2;

if (@end1 != @end2) {
  die "could not find matching pe files in fastq_dir: $fastq_dir";
}

print "processing files ", join ", ", @end1, @end2, "\n";

my @cmds = ();
for (my $i=0; $i<@end1; $i++) {

  # get the basename of each pe set
  my $name1 = fileparse($end1[$i], ($file_suffix_1, "$file_suffix_1.gz"));
  my $name2 = fileparse($end2[$i], ($file_suffix_2, "$file_suffix_2.gz"));
  if ($name1 ne $name2) {
    die "files don't match $end1[$i] $end2[$i]\n";
  }

  # -mfl is median fragment length. 
  my $cmd1 = "MosaikBuild -q $end1[$i] -q2 $end2[$i] -st illumina -mfl 500 ";
  $cmd1.= "-out $build_dir/$name1.mkb";
  push @cmds, $cmd1;
}


pareach [ @cmds ], sub {
  my $cmd = shift;
  run_command($cmd);
}, {"Max_Workers"=>4};


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

mosaik_build.pl

=head1  SYNOPSIS

mosaik_build.pl -fd fastq_dir -bd build_dir -fs1 file_suffix_1 -fs2 file_suffix_2

=head1  DESCRIPTION

Wrapper to execute MoaikBuild on s set of paired end fastq or fastq.gz files.

A basic directory structure is assumed:

BIOSAMPLE_ID \ fastq
             \ build
             \ align

=head1  OPTIONS

=over

=item    -h

Basic usage documentation.

=item    -bd

The directory where the Mosaik build files are written.

=item    -fd

The directory where the fastq files are. All files ending with
suffix1 or suffix2 will be processed. Each file must have a mate.

=item    -fs1

The suffix on the first file of the mate pair. The default is '_1.fastq'.

=item    -fs2

The suffix on the second file of the mate pair. The default is '_2.fastq'.

=back

=head1  AUTHORS

[% kb_author %]

=cut
