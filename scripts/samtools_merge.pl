#!/usr/bin/env perl

use lib qw(/home/ubuntu/perl5/lib/perl5/);
use File::Basename;
use Proc::ParallelLoop;

# These will ultimately become command line parameters.
# the directory where the bam files reside.
my $bam_dir = '/mnt/data/biosamples/SAMN01828242/align';

my $samtools = '/usr/local/bin/samtools';

# the maxMem and Max_Workers needs to be balanced. The
# the default mem setting is 500M and Max_Workers is
# set to 4.

foreach my $bam (`ls $bam_dir/*.bam`) {
  # skip bam file if it is already sorted
  next if $bam =~ /sorted.bam$/;
  push @bams, $bam;
}
map chomp, @bams;


# do a bit of error checking
if (! @bams) {
  die "could not find bam files in $bam_dir";;
}

print "processing files ", join ", ", @bams, "\n";

for (my $i=0; $i<@bams; $i++) {

  # results in header from last bam file being used.
  my $cmd1 = "$samtools view -H $bams[$i] > $bam_dir/inh.sam";
  my $rv = run_command($cmd1);
  die "failed getting header with cmd: $cmd" if ($rv != 0);

  my $cmd = "$samtools sort -@ 4 -m 500M $bams[$i] $bams[$i].sorted";
  my $rv = run_command($cmd);
  $failed += $rv;

  # add to current list of sorted bam files to merge
  $file_list .= "$bams[$i].sorted.bam ";
}


# merge if no sort commands failed
if ($failed == 0) {
  my $cmd = "samtools merge -@ 4 -h $bam_dir/inh.sam $bam_dir/merged.bam $file_list";
  my $rv = run_command($cmd);
}

sub run_command {
  my $cmd = shift or die "no command passed to run_command";
  my $failed_cmds = 0;

  print "running $cmd\n";
  unless (!system $cmd ) {
    print "failed running $cmd\n$!";
    $failed_cmds++
  }

  return $failed_commands;
}
