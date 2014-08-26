#!/usr/bin/env perl

use strict;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Getopt::Long; 
use Pod::Usage;

my ($help, $align_dir, @bams, $threads);
$threads = 1;
$help = 0;

GetOptions(
        'h'       => \$help,
	'ad=s'    => \$align_dir,
	'bam=s'   => \@bams,
	't=i'     => \$threads,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ( ! $align_dir ) and ( ! @bams ) );


if ( @bams ) {
  @bams = split( /,/, join( ',', @bams ) );
}
elsif ( -d $align_dir ) {
  foreach my $bam ( glob( "$align_dir/*.bam" ) ) {
    push @bams, $bam;
  }
}
else {
  die "Houston, we have a problem (no bams and no build_dir)";
}


print "processing files: ", join ", ", @bams, "\n";


# this should be parallel

my @cmds = ();

for ( my $i = 0; $i < @bams; $i++ ) {

  my ($basename, $path) = fileparse( $bams[$i], ".bam" );

  my $cmd = "bamtools sort ";
  $cmd .= "-in $bams[$i] ";
  $cmd .= " -out " . $path . "$basename.sorted.bam "; 
  push @cmds, $cmd;
}

foreach my $cmd ( @cmds ) {
  print "running command: $cmd\n";
  unless ( ! system( $cmd ) ) {
    print "failed running $cmd\n$!"; 
    next;
  }
}





=pod

=head1  NAME

bamtools_sort.pl

=head1  SYNOPSIS

 bamtools_sort.pl -ad <align_dir where bam files are
 bamtools_sort.pl -bam <comma separeated list of bam files>

 Arguements

 Either the alignment dir that contains the unsorted bam files
 or a comma separated list of bam files is required.

 Outputs are the sorted bam files named by replacing the
 .bam suffix with .sorted.bam.


=head1  DESCRIPTION

Wrapper for the MosaikAlign program. It takes as input either
a directory containing some number of bam files, or a comma
separated list of bam files. It sorts each of the bam files
and places the sorted bamfiles in the same directory as the
input bam file with the suffix .bam replaced with .sorted.bam

=head1  OPTIONS

=over

=item   -h

 Basic usage documentation

=item	-ad

 A directory where the unsorted bam files exist. The sorted bam 
 files will also be written to this directory.

=item	-bam

 A comma separated list of bam files with no whitespaces. The sorted
 bam files will be placed in the same directory as the input unsorted
 bam file.

=back

=head1  AUTHORS

[% kb_author %]

=cut
