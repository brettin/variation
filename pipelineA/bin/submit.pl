#!/usr/bin/env perl -w

my $TEST=1;

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
my ($shockurl, $shocktoken, );
my (@end1, @end2, );

# the suffix on the mate pair files used to construct basename
$file_suffix_1 = '_1.fastq.gz';
$file_suffix_2 = '_2.fastq.gz';

GetOptions(
        'h'     => \$help,
        'fd=s'  => \$fastq_dir,
        'fs1=s' => \$file_suffix_1,
        'fs2=s' => \$file_suffix_2,
	'su=s'  => \$shockurl,
	'st=s'  => \$shocktoken,

) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if $help or ( ! $fastq_dir );


foreach my $fastq ( glob "$fastq_dir/*" ) {
  push @end1, $fastq if $fastq =~ /$file_suffix_1/;
  push @end2, $fastq if $fastq =~ /$file_suffix_2/;
}
die "problem matching paired end files" unless @end1 == @end2;

map chomp, @end1;
map chomp, @end2;


# task files in array of pairs, obtained by parsing your directory structure
# @task_files = [ [fileX1, fileX2], [fileY1, fileY2],[fileZ1, fileZ2]];

my @task_files = ();
for ( my $i = 0; $i < @end1; $i++ ) {
  die "problem matching paired end files" 
    unless basename( $end1[$i], $file_suffix_1 ) eq basename( $end2[$i], $file_suffix_2 );
  push @task_files, [ $end1[$i], $end2[$i] ];
}

print Dumper \@task_files if $TEST;


# upload files and remember the ids

my $shock = new SHOCK::Client($shockurl, $shocktoken) unless $TEST;
my @task_nodes=[];

foreach my $pair (@task_files) {

  my $id_pair =[];

  foreach my $file (@$pair)  {

    my $node_obj = $shock->upload(file => $file) unless $TEST;

    # This is for testing w/o a network
    $node_obj->{data}->{id} = rand scalar(time) if $TEST;

    die "failed shock upload of $file" unless (defined $node_obj);
    unless ( defined($node_obj->{'data'}) ) {
      print STDERR Dumper($node_obj);
      die "no data field found";
    }

    my $node_id = $node_obj->{'data'}->{'id'};
    unless (defined($node_id)) {
	print STDERR Dumper($node_obj);
	die "no node id found";
    }

    push(@{$id_pair}, [basename($file), $node_id]);

  }
  push(@task_nodes, $id_pair);
}

print Dumper \@task_nodes if $TEST;

# ------------------------------
# create workflow

my $workflow = new AWE::Workflow(
	"pipeline"=> "variation",
	"name"=> "MosaikFreebayesV1",
	"project"=> "KBase",
	"user"=> "kbase-user",
	"clientgroups"=> "some client group",
	"noretry"=> JSON::true
);

print Dumper $workflow if $TEST;


my @summary_inputs=();
for (my $i = 0 ; $i < @task_nodes ; ++$i) {
	my $pair = $task_nodes[$i];
	my ($input1, $input2) = @{$pair};

	my $newtask = $workflow->addTask(new AWE::Task());
	$newtask->command('task.pl @'.$input1->[0].' @'.$input2->[0]);
	
	# add input nodes
	foreach my $input (@{$pair}) {
		$newtask->addInput(new AWE::TaskInput(
			'node' => $input->[1],
			'host' => $shockurl,
			'filename' => $input->[0])
			);
	}

	# create output node
	my $output_reference =
		$newtask->addOutput(
			new AWE::TaskOutput(
				"outputfile.fna",   ### THIS CAUSES AN ERROR CAUSE IT'S NOT UNIQUE
				$shockurl
				)
			);

	# create input node for the last task (which is not yet created), and store it in array
	push (@summary_inputs, new AWE::TaskInput('reference' => $output_reference));
}

print Dumper $workflow if $TEST;

# create and add last summary task
my $newtask = $workflow->addTask(new AWE::Task());

$newtask->command('something.pl ...');
$newtask->addInput(@summary_inputs); # these input nodes connect this task with the previous tasks

$newtask->addOutput(new AWE::TaskOutput("final result filename", $shockurl));

print Dumper $newtask if $TEST;

my $json = JSON->new;

# print "AWE job:\n".$json->pretty->encode( $workflow->getHash() )."\n";

print "submit job to AWE server...\n";
exit;

my $awe = new AWE::Client;

my $submission_result = $awe->submit_job('json_data' =>
$json->encode($workflow->getHash()));

my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";


print "result from AWE server:\n".$json->pretty->encode(
$submission_result )."\n";

=pod

=head1	NAME

=head1	SYNOPSIS

 submit.pl -fd <fastq_dir> -su <shock_url>

=head1	DESCRIPTION

=head1	OPTIONS

        'h'     => \$help,
        'fd=s'  => \$fastq_dir,
        'fs1=s' => \$file_suffix_1,
        'fs2=s' => \$file_suffix_2,
        'su=s'  => \$shockurl,
        'st=s'  => \$shocktoken,

=head1	AUTHORS

=cut
