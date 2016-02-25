#!/usr/bin/env perl -w

my $DEBUG = 1;
my $TEST  = 0;

use strict;
use File::Basename;
use File::Spec;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use MIME::Base64;

use SHOCK::Client;
use AWE::Client;
use AWE::Job;
use AWE::Workflow;
use AWE::Task;
use AWE::TaskInput;
use AWE::TaskOutput;

use Bio::KBase::Variation::VariationConstants qw(:all);
use Bio::KBase::AuthToken;

my $help = 0;
my ($fastq_dir, $build_dir, $file_suffix_1, $file_suffix_2);
my ($ref_db, $ref_genome, $ref_name, $aweurl, $shockurl, $shocktoken, );
my (@end1, @end2, );

# the suffix on the mate pair files used to construct basename
$file_suffix_1 = '_1.fastq.gz';
$file_suffix_2 = '_2.fastq.gz';

# these are mosaik specific parameters
my ($annpe, $annse, $threads, );
$annpe         = annpe;
$annse         = annse;
$threads       = mthreads;

print "annpe = $annpe\n";
print "annse = $annse\n";
print "threads = $threads\n";

# these are the default shock and awe urls
$aweurl = aweurl;
$shockurl = shockurl;

print "aweurl = $aweurl\n";
print "shockurl = $shockurl\n";

GetOptions(
        'h'     => \$help,
        'fd=s'  => \$fastq_dir,
        'fs1=s' => \$file_suffix_1,
        'fs2=s' => \$file_suffix_2,
	'rd=s'  => \$ref_db,
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
			( ! $ref_db )
		       );

# any paramater validation needed
die "fastq_dir not a directory" unless -d $fastq_dir;
$fastq_dir =~ s/\/+$//;
my($filename, $directories, $suffix) = fileparse($ref_db, qr/\.[^.]*/);

# if a auth token isn't passed in, try to get one
$shocktoken = Bio::KBase::AuthToken->new()->{token} unless $shocktoken;

# allow the reference genome data to stored in shock
print "checking reference db $ref_db if is handle\n";
if ( $suffix =~ /\.handle$/ ) {
  $ref_db = read_handle( $ref_db );
  $ref_name = $filename;
  $ref_name =~ s/\.tar//;
  print "ref_db handle: $ref_db\n" if $DEBUG;
  print "ref_name: $ref_name\n" if $DEBUG;
}
else {
  die "the reference database command line parameter doesn;t look " .
      "like a shock handle based on the file suffix";
} 

foreach my $fastq ( glob "$fastq_dir/*" ) {
  push @end1, $fastq if $fastq =~ /$file_suffix_1/;
  push @end2, $fastq if $fastq =~ /$file_suffix_2/;
}
die "no file suffixes $file_suffix_1 or $file_suffix_2 found in $fastq_dir" unless @end1 > 0 or @end2 > 0;
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

# upload fastq files and remember the ids
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
	"project"=> "PATRIC3",
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
	$newtask->command('va-mosaik_build ' . '-fq1 @' . $input1->[0] .
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
  $newtask->command('va-mosaik_align -mkb @' . $name . '.mkb ' . 
	  ' -rdh ' . encode_base64($ref_db, "") . ' -t ' . $threads .
	  ' -annpe ' . $annpe . ' -annse ' . $annse
  );
  $newtask->description('Align reads to reference genome');
  $newtask->environ({public => {'KB_AUTH_TOKEN' => $shocktoken}});

  # add input and output nodes for mosaik align task
	my $align_input = new AWE::TaskInput('reference' => $build_output);
	my $align_output = new AWE::TaskOutput("$name.bam", $shockurl);
	$newtask->addInput($align_input);
	$newtask->addOutput($align_output);

	# create bamtools sort task
	$newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('va-bamtools_sort ' . ' -bam @' . $name . '.bam');
	$newtask->description('Sort bam file');

	# add input and output nodes for bamtools sort task
	my $sort_input = new AWE::TaskInput('reference' => $align_output);
	my $sort_output = new AWE::TaskOutput("$name.sorted.bam", $shockurl);
	$newtask->addInput($sort_input);
	$newtask->addOutput($sort_output);

	# create bamutil dedup tmask
	$newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('va-bamutil_dedup ' . ' -bam @' . $name . '.sorted.bam');
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


# create freebayes task
my $vcf_file =   (File::Spec->splitdir($fastq_dir))[-1] . "_" . $ref_name  . '.vcf';

my $newtask = $workflow->addTask(new AWE::Task());
$newtask->environ({public => {'KB_AUTH_TOKEN' => $shocktoken}});
$newtask->command('va-freebayes_run ' . ' -rdh ' . encode_base64($ref_db, "") . 
		  ' -bam @' . join(' -bam @', @dedup_files) . ' -o ' . $vcf_file
		 );
$newtask->description("Call SNPs with freebayes");

# add input and output nodes for freebayes task
$newtask->addInput(@freebayes_inputs);
my $freebayes_output = new AWE::TaskOutput($vcf_file, $shockurl);
$newtask->addOutput($freebayes_output);

# create snpeff task output filename
my $snpeff_vcf_file = $ref_name . '_snpeff.vcf';

# create snpeff task
my $newtask = $workflow->addTask(new AWE::Task());
$newtask->environ({public => {'KB_AUTH_TOKEN' => $shocktoken}});
$newtask->command('va-snpeff ' . ' -rdh ' . encode_base64($ref_db, "") . ' -vcf @' . $vcf_file . 
		  ' -o ' . $snpeff_vcf_file );
$newtask->description("Annotate variants with snpEff");

# add input and output nodes for snpeff task
my $snpeff_input = new AWE::TaskInput('reference' => $freebayes_output);
my $snpeff_output = new AWE::TaskOutput($snpeff_vcf_file, $shockurl);
$newtask->addInput($snpeff_input);
$newtask->addOutput($snpeff_output);

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





sub read_handle {
  my ($perl_scalar, $json_string, $json_obj);

  open F, "<$_[0]" or die "can not read file $_[0]";
  while(<F>) {
    chomp;
    $json_string .= $_;
  }
  close F;
  
  # complaign if it look like base64
  warn "look like base 64" if $json_string =~ /^[A-Za-z0-9+\/\n]+$/;
  
  # need a better way to validate the json_text
  print "json_string: ", $json_string, "\n" if $DEBUG;
  $json_obj = JSON->new->allow_nonref;
  $perl_scalar = $json_obj->decode( $json_string ) or die "cannot decode json_text: $json_string";

  return $json_string;
}


=pod

=head1	NAME

=head1	SYNOPSIS

 submit.pl -fd <fastq_dir> -su <shock_url> -au <awe_url>

=head1	DESCRIPTION

 This reads in a set of illumina paired end reads and submits them
 to an awe workflow that identifies SNPs and produces a vcf file.

=head1	OPTIONS

        'h'     => \$help,	Prints a help message.
        'rd=s'  => \$ref_db,	The reference database described below.
        'fd=s'  => \$fastq_dir,	The directory where the fastq files are.
        'fs1=s' => \$file_suffix_1,	The suffix on the first of the fastq pair.
        'fs2=s' => \$file_suffix_2,	The suffix on the second of the fastq pair.
        'su=s'  => \$shockurl,	The url of the shock server including proto.
        'au=s'  => \$aweurl,	The url of the awe server including protocol.
        'st=s'  => \$shocktoken,	Your shock token.

==head1 NOTES

 design notes

 The reference database is going to be referenced as a file
 or a directory. The file will contain a shock handle. The
 directory will contain the necessary reference db files.

 The shock handle will resolve to a tarball that when untarred,
 will contail all necessary reference files for the pipeline.
 This includes a fasta file, fai file, and snpeff db.

 The reference genome command line option is expected to be a
 handle that has been base64 encoded. 

 The handle resolves to a tarball that has been stored in shock.

 The reference database is represented as a directory in the
 filesystem that is created when the tarball is unpacked.

 The directory name of the reference database is expected to be used
 also in the naming of the files under that directory.

 Here is an example for Bacteroides_fragilis_NCTC_9343_uid57639

=item tarball stored in shock

 Bacteroides_fragilis_NCTC_9343_uid57639.tar

=item unpacked tarball in filesystem

 Bacteroides_fragilis_NCTC_9343_uid57639/
 Bacteroides_fragilis_NCTC_9343_uid57639/Bacteroides_fragilis_NCTC_9343_uid57639.mkb
 Bacteroides_fragilis_NCTC_9343_uid57639/Bacteroides_fragilis_NCTC_9343_uid57639.fna
 Bacteroides_fragilis_NCTC_9343_uid57639/Bacteroides_fragilis_NCTC_9343_uid57639/
 Bacteroides_fragilis_NCTC_9343_uid57639/Bacteroides_fragilis_NCTC_9343_uid57639/snpEffectPredictor.bin
 Bacteroides_fragilis_NCTC_9343_uid57639/Bacteroides_fragilis_NCTC_9343_uid57639.fna.fai

  start here

 only this script will have access to the handle file.
 this script will have to read the handle file into
 a jason string.

 each task that requires a reference database will need
 to download the tarball and unpack it. the downloading
 and unpacking will have to take place in the task script.

 the task script therefore needs to accept the handle
 json string or a directory path as a command line option.



=head1	AUTHORS

=cut
