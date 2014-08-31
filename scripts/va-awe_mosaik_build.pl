#!/usr/bin/env perl

# use Proc::ParallelLoop;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Getopt::Long; 
use Pod::Usage;
use strict;

my $man  = 0;
my $help = 0;
my ($fastq_dir, $build_dir, $file_suffix_1, $file_suffix_2);
my (@end1, @end2, @outfiles, );

# the suffix on the mate pair files used to construct basename
$file_suffix_1 = '_1.fastq';
$file_suffix_2 = '_2.fastq';

GetOptions(
        'h'     => \$help,
	'fd=s'  => \$fastq_dir,
	'bd=s'  => \$build_dir,
	'fs1=s' => \$file_suffix_1,
	'fs2=s' => \$file_suffix_2,
	'fq1=s'  => \@end1,
	'fq2=s'  => \@end2,
	'o=s'   => \@outfiles,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( (! $build_dir) and (! @outfiles))
                    or ( (! $fastq_dir) and ( ( ! @end1 ) or ( ! @end2 ) ) ) ;


if( @end1 and @end2 ) {
  @end1 = split(/,/,join(',',@end1));
  @end2 = split(/,/,join(',',@end2));
    if ( @outfiles ) {
      @outfiles = split(/,/,join(',',@outfiles));
    }
}

elsif ($fastq_dir) {
  foreach my $fastq (`ls $fastq_dir/*.fastq`, `ls $fastq_dir/*.fastq.gz`) {
    push @end1, $fastq if $fastq =~ /$file_suffix_1/;
    push @end2, $fastq if $fastq =~ /$file_suffix_2/;
  }
  map chomp, @end1;
  map chomp, @end2;
}
else {
  die "something wrong with arguement checking logic";
}

if (@end1 != @end2) {
  die "could not find matching pe files in fastq_dir: $fastq_dir";
}

if ($build_dir and (! -d $build_dir )) {
  make_path($build_dir, { verbose => 1 });
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
  $cmd1.= "-out $build_dir/$name1.mkb" if $build_dir;
  $cmd1.= "-out $outfiles[$i]" if @outfiles;
  push @cmds, $cmd1;
}


# pareach [ @cmds ], sub {
#   my $cmd = shift;
#   run_command($cmd);
# }, {"Max_Workers"=>4};

foreach my $cmd (@cmds) {
  run_command($cmd);
}

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


=head2	Directory based input and output

=item    -bd

The directory where the Mosaik build files are written.

=item    -fd

The directory where the fastq files are. All files ending with
suffix1 or suffix2 will be processed. Each file must have a mate.
Each mate pari should be named the same up to the suffix.
The output file(s) will be named with the suffix stripped off.
Known valid suffixes are _1.fastq and _2.fastq.

=item    -fs1

The suffix on the first file of the mate pair. The default is '_1.fastq'.

=item    -fs2

The suffix on the second file of the mate pair. The default is '_2.fastq'.


=head2	File based input and output

=item	-fq1

A list of fastq files representing 1 end of a mate pair.

=item	-fq2

A list of fastq files representing the other end of the mate pair.
The order of the files in -fq2 muust pair with the order in -fq1.
Either the -o or the -bd options can be used for the output files.

=item	-o

A list of output file names. This only works if -fq1 and -fq2 are set.
The order of the files in -o will map to the order of the files in
-fq1 and -fq2. An error is thrown if the number of output files does
not equal the number of input pairs.

=back

=head1  AUTHORS

[% kb_author %]

=cut
