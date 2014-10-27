#!/usr/bin/env perl -w

my $DEBUG=0;
my $TEST=0;

use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

use SHOCK::Client;
use AWE::Client;
use AWE::Job;
use AWE::Workflow;
use AWE::Task;
use AWE::TaskInput;
use AWE::TaskOutput;

my $man  = 0;
my $help = 0;
my ($fastq_dir, $build_dir, $file_suffix_1, $file_suffix_2);
my ($ref_genome, $aweurl, $shockurl, $shocktoken, );
my (@end1, @end2, );

# the suffix on the mate pair files used to construct basename
$file_suffix_1 = '_1.fastq.gz';
$file_suffix_2 = '_2.fastq.gz';

# these are mosaik specific parameters
my ($annpe, $annse, $threads, );
$annpe         = '/kb/runtime/bin/2.1.78.pe.ann';
$annse         = '/kb/runtime/bin/2.1.78.se.ann';
$threads       = 6;

GetOptions(
        'h'     => \$help,
        'fd=s'  => \$fastq_dir,
        'fs1=s' => \$file_suffix_1,
        'fs2=s' => \$file_suffix_2,
	'rg=s'  => \$ref_genome,
	'au=s'  => \$aweurl,
	'su=s'  => \$shockurl,
	'st=s'  => \$shocktoken,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or (( ! $fastq_dir ) or 
			( ! $shockurl )  or
			( ! $aweurl )    or
			( ! $ref_genome )
		       );


foreach my $fastq ( glob "$fastq_dir/*" ) {
  push @end1, $fastq if $fastq =~ /$file_suffix_1/;
  push @end2, $fastq if $fastq =~ /$file_suffix_2/;
}
die "problem matching paired end files" unless @end1 == @end2;

map chomp, @end1;
map chomp, @end2;


# task_files is an array of 2 element arrays.
# each 2 element array holds a mate pair of fastq files.

my @task_files = ();
for ( my $i = 0; $i < @end1; $i++ ) {
  die "problem matching paired end files" 
    unless basename( $end1[$i], $file_suffix_1 ) eq basename( $end2[$i], $file_suffix_2 );
  push @task_files, [ $end1[$i], $end2[$i] ];
}

print Dumper \@task_files if $DEBUG;

# upload files and remember the ids
# id_pair is a 2 element array containing the filename and node id
# task_nodes is a list of id_pairs

my $shock = new SHOCK::Client($shockurl, $shocktoken) unless $TEST;
my @task_nodes;

foreach my $pair (@task_files) {
  my $id_pair;

  foreach my $file (@$pair)  {
    my $node_obj = $shock->upload(file => $file) unless $TEST;

    # This is for testing w/o a network
    $node_obj->{data}->{id} = rand scalar(time) if $TEST;

    unless ( defined($node_obj->{'data'}) ) {
      print Dumper($node_obj) if $DEBUG;
      die "no data field found";
    }

    my $node_id = $node_obj->{'data'}->{'id'};
    unless (defined($node_id)) {
	print Dumper($node_obj) if $DEBUG;
	die "no node id found";
    }

    push(@{$id_pair}, [basename($file), $node_id]);

  }
  push(@task_nodes, $id_pair);
}

print Dumper \@task_nodes if $DEBUG;

# create a workflow
my $workflow = new AWE::Workflow(
	"pipeline"=> "variation",
	"name"=> "MosaikFreebayesV1",
	"project"=> "KBase",
	"user"=> "kbasetest",
	"clientgroups"=> "kbase",
	"noretry"=> JSON::true
);

print Dumper $workflow if $DEBUG;

my @freebayes_inputs;
my @dedup_files;

for (my $i = 0 ; $i < @task_nodes ; ++$i) {
	my $pair = $task_nodes[$i];
	my ($input1, $input2) = @{$pair};
	my ($name,$path,$suffix) = fileparse($input1->[0],($file_suffix_1, $file_suffix_2));
	print "BASENAME: ", $name, "\n" if $DEBUG;

	# create mosaik build task
	my $newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('va-awe_mosaik_build ' . '-fq1 @' . $input1->[0] .
			  ' -fq2 @' . $input2->[0] . ' -o ' . $name . '.mkb'
			 );
	$newtask->description('Create mosaik files for paired end fastq files');
	$newtask->environ({'foo' => 'bar'});	

	# add input nodes for mosaik build task
	foreach my $input (@{$pair}) {
		$newtask->addInput(new AWE::TaskInput(
			'node' => $input->[1],
			'host' => $shockurl,
			'filename' => $input->[0])
			);
	}

	# create output node for mosaik build task
	my $build_output =
		$newtask->addOutput(
			new AWE::TaskOutput(
				$name.'.mkb',
				$shockurl
				)
			);

        # create mosaik align task
        $newtask = $workflow->addTask(new AWE::Task());
        $newtask->command('va-awe_mosaik_align -mkb @' . $name . '.mkb -o ' . 
			  $name . ' -rg ' . $ref_genome . ' -t ' . $threads .
			  ' -annpe ' . $annpe . ' -annse ' . $annse
			 );
        $newtask->description('Align reads to reference genome');
        $newtask->environ({'REF_DB_PATH' => '/mnt/reference/mosaik'});

        # add input and output nodes for mosaik align task
	my $align_input = new AWE::TaskInput('reference' => $build_output);
	my $align_output = new AWE::TaskOutput("$name.bam", $shockurl);
	$newtask->addInput($align_input);
	$newtask->addOutput($align_output);

	# create bamtools sort task
	$newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('va-awe_bamtools_sort ' . ' -bam @' . $name . '.bam');
	$newtask->description('Sort bam file');

	# add input and output nodes for bamtools sort task
	my $sort_input = new AWE::TaskInput('reference' => $align_output);
	my $sort_output = new AWE::TaskOutput("$name.sorted.bam", $shockurl);
	$newtask->addInput($sort_input);
	$newtask->addOutput($sort_output);

	# create bamutil dedup tmask
	$newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('va-awe_bamutil_dedup ' . ' -bam @' . $name . '.sorted.bam');
	$newtask->description('Mark duplicates in bam file');

	# add input and output nodes for bamutil dedup task
	my $dedup_input = new AWE::TaskInput('reference' => $sort_output);
	my $dedup_output = new AWE::TaskOutput("$name.sorted.dedup.bam", $shockurl);
	$newtask->addInput($dedup_input);
	$newtask->addOutput($dedup_output);

	# create input node for the last task
	push (@dedup_files, "$name.sorted.dedup.bam");
	push (@freebayes_inputs, new AWE::TaskInput('reference' => $dedup_output));
}

print Dumper $workflow if $DEBUG;

# find reference genome fasta file for freebayes
my $ref_genome_fasta;
my ($filename, $path, $suffix) = fileparse($ref_genome,  qr/\.[^.]*/);
if    (-e "$path/$filename.fa")  {$ref_genome_fasta = "$path/$filename.fa"; }
elsif (-e "$path/$filename.fasta") {$ref_genome_fasta = "$path/$filename.fasta" }
else {die "can not find fasta reference genome for $ref_genome by ",
	  "dropping the suffix ($suffix) and adding .fasta or .fa";}

# create freebayes task
my $newtask = $workflow->addTask(new AWE::Task());
my $vcf_file =   $fastq_dir . "_" . $ref_genome . '.vcf';;
$newtask->command('va-awe_freebayes_run ' . ' -rg ' . $ref_genome_fasta . 
		  ' -bam @' . join(' -bam @', @dedup_files) . ' -o ' . $vcf_file
		   );
$newtask->description("Call SNPs with freebayes");

# add input and output nodes for freebayes task
$newtask->addInput(@freebayes_inputs);
$newtask->addOutput(new AWE::TaskOutput("out.vcf", $shockurl));

# submit the workflow to the awe server
my $json = JSON->new;
print $json->pretty->encode( $workflow->getHash() ), "\n" if $DEBUG;

my $awe = new AWE::Client($aweurl, $shocktoken);
print "setting aweurl to $aweurl\n" if $DEBUG;
$awe->{awe_url} = $aweurl;

exit if $TEST;

my $json_workflow = $json->encode($workflow->getHash());
my $submission_result = $awe->submit_job('json_data' => $json_workflow);
my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";

print $job_id, "\n";
if (open F, ">$job_id") {
	my $pretty_workflow = $json->pretty->encode( $workflow->getHash() );
	print F $pretty_workflow;
	close F;
}

print "result from AWE server:\n".$json->pretty->encode($submission_result )."\n" if $DEBUG;

=pod

=head1	NAME

=head1	SYNOPSIS

 submit.pl -fd <fastq_dir> -su <shock_url> -au <awe_url>

=head1	DESCRIPTION

 This reads in a set of illumina paired end reads and submits them
 to an awe workflow that identifies SNPs and produces a vcf file.

=head1	OPTIONS

        'h'     => \$help,	Prints a help message.
	'rg=s'  => \$ref_genome,	The reference genome to align to.
        'fd=s'  => \$fastq_dir,	The directory where the fastq files are.
        'fs1=s' => \$file_suffix_1,	The suffix on the first of the fastq pair.
        'fs2=s' => \$file_suffix_2,	The suffix on the second of the fastq pair.
        'su=s'  => \$shockurl,	The url of the shock server including proto.
	'au=s'  => \$aweurl,	The url of the awe server including protocol.
        'st=s'  => \$shocktoken,	Your shock token.

=head1	AUTHORS

=cut
