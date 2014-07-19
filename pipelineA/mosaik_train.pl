#!/usr/bin/env perl
use strict;
use Getopt::Long; 
use Pod::Usage;

my ($help, $align_dir, @bams, $fragment);
$fragment = 1000;

GetOptions(
	'h'		=> \$help,
	'ad=s'		=> \$align_dir,
	'bams=s'	=> \@bams,
) or pod2usage(0);

pod2usage(-exitstatus 	=> 0,
	-output 	=> \*STDOUT,
	-verbose 	=> 1,
	-noperldoc 	=> 1,
) if $help or ( (!@bams) and (!$align_dir) );



if (@bams) {
	@bams = split (/,/,join(',',@bams));
	map chomp, @bams;
}
elsif ($align_dir) {
	foreach my $bam (glob "$align_dir/*.sorted/bam") {
		push @bams, $bam;
	}
}
else {
	die "houston, we have a problem";
}
my $in = join (' ', @bams);

system("bamtools", "merge", "-in", "$in", "-out", "merged.bam");

system("bamtools", "convert", "-format", "sam", "-noheader", 
	"-in", "merged.bam", "-out", "merged.sam");

system("bash", "-c", "xc_pe gold.sam merged.sam > merged.xc.sam");

system("train_mq", "-i", "merged.xc.xam", "-o", "merged.pe.ann", "-p", "-f", $fragment, "-e", "o.0015");



=pod

=head1	NAME

mosaik_train.pl

=head1	SYNOPSIS

mosaik_train.pl -bams "file1.bam,file2.bam,file3.bam" 

=head1	DESCRIPTION

Wrapper around the Mosaik programs train_mq and xc_pe to retrain the neural net.

=head1	OPTIONS

	-h
	-bams
	-ad

=cut
