#!/usr/bin/env perl


use File::Basename;
use Getopt::Long; 
use Pod::Usage;
use strict;

my ( $help, $reference_genome, $outfile, $hash_size, $kd, $mem, );
$help = 0;
$hash_size = 15;

GetOptions(
        'h'     => \$help,
	'rg=s'  => \$reference_genome,
	'o=s'   => \$outfile,
	'hs=i'  => \$hash_size,
	'kd'    => \$kd,
	'mem=i' => \$mem,
) or pod2usage(0);	
pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
) if $help  or ( ! $reference_genome ) or ( ! $outfile );

die "could not find reference genome $reference_genome" unless -e $reference_genome;


print "processing file $reference_genome\n";

### Command line information for build-jump-database (mosaik-jump).
# $(PWD)/Mycobacterium_tuberculosis_H37Rv_15_keys.jmp: $(PWD)/Mycobacterium_tuberculosis_H37Rv.dat
#         @echo -e  "Executing task: build-jump-database...\c"
#         @$(MOSAIK-JUMP_PATH)/MosaikJump \
#         -out $(PWD)/Mycobacterium_tuberculosis_H37Rv_15 \
#         -ia $(PWD)/Mycobacterium_tuberculosis_H37Rv.dat \
#         -hs 15 \
#         >> $(STDOUT) \
#         2>> $(STDERR)
#         @echo -e  "completed successfully."

my ($basename, $path, $suffix) = fileparse($reference_genome, ".mkb");
if ( ! $outfile ) { $outfile = $path . $basename . "_" . $hash_size . ".jmp"; }

my @params = (
	"-ia",
	$reference_genome,
	"-out",
	$outfile,
	"-hs",
	$hash_size,
);

# memory allocation not working correctly in vagrant vm:
push @params, "-kd" if $kd;
push @params, ("-mem", $mem) if $mem;

my $cmd = "MosaikJump " . join ( " ", @params );
run_command($cmd);


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

 mosaik_build_jump.pl

=head1  SYNOPSIS

 mosaik_build_jump.pl -rg <reference genome> -o <output file name> 
 mosaik_build_jump.pl -rg <reference genome> -o <output file name> -kd
 mosaik_build_jump.pl -rg <reference genome> -o <output file name> -mem <int in Gigs>

=head1  DESCRIPTION

 Wrapper to run the bam util tool dedup on sorted bam files.

=head1  OPTIONS

=over

=item    -h

 Basic usage documentation.

=item	-rg

 The reference genome produced by mosaik build.

=item	-o

 The fullname of the ouput jump database.

=item	-kd (optional)

 Keep the keys database on disk. This is needed for some reason when using vagrant.

=item	-mem (optional)

 The amount of memory used when sorting hashes (default 2). Is an Integer.

=back

=head1  AUTHORS

=cut
