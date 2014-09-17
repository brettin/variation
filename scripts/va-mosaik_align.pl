#!/usr/bin/env perl

use File::Basename;
use File::Path qw(make_path remove_tree);
use strict;
use Getopt::Long; 
use Pod::Usage;

my $help = 0;
my ($build_dir, @mkbs, $align_dir, @outfiles, $ref_genome);

my $annpe = "/usr/local/bin/2.1.78.pe.ann";
my $annse = "/usr/local/bin/2.1.78.se.ann";
my $threads = 4;

# required build_dir, align_dir, ref_genome
GetOptions(
        'h'     => \$help,
	'bd=s'  => \$build_dir,
	'ad=s'  => \$align_dir,
	'rg=s'  => \$ref_genome,
	'mkb=s' => \@mkbs,
	'o=s'   => \@outfiles,
	'annpe=s' => \$annpe,
	'annse=s' => \$annse,
	't=i'     => \$threads,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ((!$align_dir) and (!@outfiles))
		    or (!$ref_genome)
	            or ( (! $build_dir ) and ( ! @mkbs ) );

die "ref_genome $ref_genome does not exist" unless -e $ref_genome;

if ( $align_dir and (! -d $align_dir )) {
  make_path($align_dir, { verbose => 1 });
}


if ( @mkbs ) {
  @mkbs = split( /,/, join( ',', @mkbs ) );
  if ( @outfiles ) {
    @outfiles = split( /,/, join( ',', @outfiles ) );
  }
}
elsif ( -d $build_dir ) {
  foreach my $mkb ( glob( "$build_dir/*.mkb" ) ) {
    push @mkbs, $mkb;
  }
}
else {
  die "Houston, we have a problem (no mkbs and no build_dir)";
}


print "processing files ", join ", ", @mkbs, "\n";


# this should be parallel
my @cmds = ();

for (my $i=0; $i<@mkbs; $i++) {
  my ($name, $path) = fileparse $mkbs[$i];

  my $cmd1 = "MosaikAligner -in $mkbs[$i] ";
  $cmd1   .= "-out $align_dir/$name " if $align_dir;
  $cmd1   .= "-out $outfiles[$i] " if @outfiles and ! $align_dir;
  $cmd1   .= "-ia $ref_genome -annpe $annpe -annse $annse ";
  $cmd1   .="-p $threads";

  print $cmd1, "\n";

  push @cmds, $cmd1;

  unless (!system $cmd1 ) {
    print "failed running $cmd1\n$!"; 
    next;
  }
}





=pod

=head1  NAME

mosaik_aling.pl

=head1  SYNOPSIS

 mosaik_align.pl -bd <build_dir> -ad <align_dir> -rg <reference_genome>
 mosaik_align.pl -mkb <comma separeated list of mkb files> -rg <reference_genome>

=head1  DESCRIPTION

Wrapper for the MosaikAlign program. Takes as input a reference genome that has been fomatted using mosaik_build (or MosaikBuild directly) and either a directory containing the set of mosaik build files or a comma separated (no whitespaces) list of mosaik build files.

=head1  OPTIONS

=over

=item   -h

 Basic usage documentation

=item	-bd

 The location of the output of the MosaikBuild command (build_dir).
 Either this option, or the -mkb option is required. Both can not be used.

=item	-mkb

 A comma separated (no whitespaces) list of the MosaikBuild files.
 Either this option, or the -bd option is required. Bot can not be used.

=item	-ad

 The location of the directory to put the bam files (align_dir).

=item	-rg

 The reference genome to align to. This should include the path. This
 is the output file created by mosaik_build_ref.pl

=item	-annpe

 The neural net training file for paired end reads. The default is
 /usr/local/bin/2.1.78.pe.ann

=item	-annse

 The neural net training file for single end reads. The default is
 /usr/local/bin/2.1.78.se.ann

=item	-t

 Number of threads that the aligner should use. The default is 1.

=back

=head1  AUTHORS


=cut
