#!/usr/bin/env perl

# Recommend using bamtools over samtools because the
# @RG (read region) header is properly managed with
# bamtool merge.


# These will ultimately become command line parameters.
# The directory where the bam files reside.
# The bamtool executable.
# The prefix used to name output, can include a path.
my $bam_dir = '/mnt/data/biosamples/SAMN01828242/align';
my $samtools = '/usr/local/bin/bamtool';
my $samlibs = '/usr/local/lib';


my $stdout = "$prefix.stdout";
my $stderr = "$prefix.stderr";
$ENV{LD_LIBRARY_PATH} = "$samlibs:$ENV{LD_LIBRARY_PATH}";


foreach my $sorted_bam (`ls $bam_dir/*.sorted.bam`) {
  push @sorted_bams, $sorted_bam;
}
map chomp, @sorted_bams;
print "processing files ", join ", ", @sorted_bams, "\n";


if (! @sorted_bams) {
  die "could not find bam files in $bam_dir";;
}


my $bammerge_params = "-out sorted.merged.bam ";
for (my $i=0; $i<@sorted_bams; $i++) {
	$bammerge_params .= "-in $sorted_bams[$i] ";
}
my $cmd = "time bamtools merge $bammerge_params >> $stdout 2>> $stderr";

my $rv = run_command($cmd);



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
