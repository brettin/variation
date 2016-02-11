#!/usr/bin/env perl

use File::Basename;
use File::Path qw(make_path remove_tree);
use MIME::Base64;
use JSON;
use strict;
use Getopt::Long; 
use Pod::Usage;
use Bio::KBase::Handle qw(decode_handle);

my $help = 0;
my ($build_dir, @mkbs, $align_dir, $ref_db);

my $annpe = "/usr/local/bin/2.1.78.pe.ann";
my $annse = "/usr/local/bin/2.1.78.se.ann";
my $threads = 4;

GetOptions(
  'h'     => \$help,
	'ad=s'  => \$align_dir,
	'rdh=s'  => \$ref_db,
	'mkb=s' => \@mkbs,
	'annpe=s' => \$annpe,
	'annse=s' => \$annse,
	't=i'     => \$threads,
) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help 
		    or ( !$ref_db )
        or ( !@mkbs );

@mkbs = split( /,/, join( ',', @mkbs ) );

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
my $ref_genome = "$ref_db_dir/$ref_db_dir.mkb";
-e $ref_genome
  or die "could not find reference genome named $ref_genome";
print "ref_genome: $ref_genome\n";

# set up the alignments output directory
if ( $align_dir and (! -d $align_dir )) {
  make_path($align_dir, { verbose => 1 });
}
else {
  $align_dir = '.';
}

print "processing files ", join ", ", @mkbs, "\n";

# this could be parallelized
my @cmds = ();

for (my $i=0; $i<@mkbs; $i++) {
  my ($name, $path, $suffix) = fileparse $mkbs[$i], '.mkb';
  my $cmd1 = "MosaikAligner -in $mkbs[$i] ";
  $cmd1   .= "-out $align_dir/$name ";
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

 mosaik_align.pl -mkb <comma separeated list of mkb files> -rdh <handle file name>

=head1  DESCRIPTION

Wrapper for the MosaikAlign program. Takes as input a reference genome that has been fomatted using mosaik_build (or MosaikBuild directly) and either a directory containing the set of mosaik build files or a comma separated (no whitespaces) list of mosaik build files.

  'rg=s'  => \$ref_db,
  'mkb=s' => \@mkbs,
  'annpe=s' => \$annpe,
  'annse=s' => \$annse,
  't=i'     => \$threads,

=head1  OPTIONS

=over

=item   -h

 Basic usage documentation

=item	-mkb

 A comma separated (no whitespaces) list of the MosaikBuild files.
 Either this option, or the -bd option is required. Bot can not be used.

=item	-ad

 The location of the directory to put the bam files (align_dir).
 Default location is the current working directory.

=item	-rdh

 The reference genome database handle. This should be file that
contains a shock handle that resolves to a tarball that contains the
reference genome that will be used by the read mapper. See below for
further details.

   1. The reference genome is contained in a directory
   2. The directory is named as the basename of the reference genome
      file
   3. The reference genome file suffix is .mkb
   4. The handle resolves to a tarball of the above directory

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
