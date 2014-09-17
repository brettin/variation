#!/usr/bin/env perl


use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use strict;


my ($help, $align_dir, @sorted_bams, @outfiles, );
$help = 0;
@sorted_bams = ();


GetOptions(
        'h'     => \$help,
	'ad=s'  => \$align_dir,
	'bam=s' => \@sorted_bams,
	'o=s'   => \@outfiles,
) or pod2usage(0);	
pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
) if $help  or ( ( ! $align_dir ) and ( ! @sorted_bams ) );


if ( @sorted_bams ) {
  @sorted_bams = split( /,/, join( ',', @sorted_bams ) );
  if ( @outfiles ) {
    @outfiles = split( /,/, join( ',', @outfiles ) );
  }
}
elsif ( -d $align_dir ) {
  @sorted_bams = glob "$align_dir/*.sorted.bam";
  map chomp, @sorted_bams;
}
else {
  die "Houston, we have a problem. No align_dir or list of bam files";
}


print "processing files ", join ", ", @sorted_bams, "\n";
foreach ( @sorted_bams ) { die "$_ does not exist\n" unless -e $_; }

my (@cmds);
for (my $i=0; $i<@sorted_bams; $i++) {
  my ($basename, $path, $suffix) = fileparse($sorted_bams[$i], ".bam");
  my @params = ( "--in",
		 $sorted_bams[$i],
		 "--out",
               );
  if    ( $align_dir ) { push @params, $path . "$basename.dedup.bam" }
  elsif ( @outfiles )  { push @params, $outfiles[$i] }
  else                 { push @params, $path . "$basename.dedup.bam" }
 
  my $cmd = "bam dedup " . join ( " ", @params );
  push @cmds, $cmd;
}

# this can be parallized
foreach my $cmd (@cmds) {
  run_command($cmd);
}


sub run_command {
  my $cmd = shift or die "no command passed to run_command";

  print "running: $cmd\n";

  unless (!system $cmd ) {
    print "failed running $cmd\n$!";
  }
  print "success: $cmd\n";
}




=pod

=head1  NAME

 bamutil_dedup.pl

=head1  SYNOPSIS

 bamutil_dedup.pl -ad <dir where sorted bam files reside>
 bamutil_dedup.pl -bam <comma separated list of sorted bam files>

=head1  DESCRIPTION

 Wrapper to run the bam util tool dedup on sorted bam files.

=head1  OPTIONS

=over

=item    -h

 Basic usage documentation.

=item	-ad

 Alignment directory that contains the sorted bam files. The sorted
 bam files must be named with a .sorted.bam suffix.

=item	-bam

 Comma separated list of sorted bam files with no whitespaces. Takes
 precidence over -ad.

=item	-o

 Fullname of the output file. Same order as input files. Not used if
 -ad option is used.

=back

=head1  AUTHORS

=cut
