use IPC::Run qw(run timeout);
use JSON;
use Template;

use Exporter qw(import);
our @EXPORT = qw(variation_build_db);
our @EXPORT_OK = qw( 
  snpeff_write_config
  snpeff_build_reference
  get_json_genome
  get_fasta
  get_gff
  write_to_file
  run_cmd
);
our %EXPORT_TAGS = ( 
  all => [ 
    'snpeff_write_config', 
    'snpeff_build_reference',
    'get_json_genome',
    'get_fasta',
    'get_gff',
    'write_to_file',
    'run_cmd',
  ]
);


# patric variables
our $data_url = "https://www.patricbrc.org/api";
# our $gid = "272559.17";
# our $genome_name = "Bacteroides_fragilis_NCTC_9343";

# variation variables (this is where snpeff expects to find $ver)
# our $data_dir = "/tmp/reference";

# snpeff variables
# our $snpeff_config = "/tmp/snpEff/snpEff.config";
# our $ver = 'p3.' . $gid;
our $snpeff_config_tt = '/home/ubuntu/tom/dev_container/modules/variation/scripts/snpEff.config.tt';


sub variation_build_db {
  my $gid = shift or die "must provide genome id";

  # create database directory
  my $json_text = get_json_genome($gid);
  my $perl_scalar = decode_json($json_text);
  my $genome = $perl_scalar->{genome_name};
  $genome =~ s/\s/_/g;
  my $base = "/tmp/reference";
  my $data_dir = $base . "/$genome";
  !system("mkdir", "-p", $data_dir)
    or die "can not mkdir $data_dir";

  # get genome data from patric
  my $fasta = get_fasta($gid);
  my $gff = get_gff($gid);

  # create snpeff directory
  snpeff_write_config( $gid, $data_dir );
  snpeff_build_reference( $gid, $fasta, $gff, $data_dir );

  # write genome.fna
  write_to_file($fasta, "$data_dir/$genome.fna");
  
  # write genome.mkb
  my @cmd = ("MosaikBuild", "-fr", "$data_dir/$genome.fna", "-oa", "$data_dir/$genome.mkb");
  my ($out, $err) = run_cmd(\@cmd);

  # write genome.fai
  build_fasta_index("$data_dir/$genome.fna");
  # tar
  # upload to shock
}

sub snpeff_write_config {
  my $gid = shift or die "must provide genome id";
  my $data_dir = shift or die "must provide data dir";
  -d $data_dir or die "data dir is not a valid directory";

  my $ver = 'p3.' . $gid;
  my $json_text = get_json_genome($gid);
  my $perl_scalar = decode_json($json_text);
  my $genome_name = $perl_scalar->{genome_name};
  $genome_name =~ s/\s/_/g;

  my %data = ( 'data_dir'     => $data_dir,
               'lof_ignoreProteinCodingAfter' => "0.95",
               'lof_ignoreProteinCodingBefore' => "0.05",
               'genome_entry'   => "$ver.genome : $perl_scalar->{genome_name}",
             );
  my $tt = Template->new({ABSOLUTE => 1});
  $tt->process($snpeff_config_tt, \%data, "$data_dir/snpEff.config") or die $tt->error;
}

sub build_fasta_index {
  my $file_name = shift or die "must provide a file name";
  -e $file_name or die "$filename doesn't exist";

  my @cmd = ("samtools", "faidx", $file_name);
  my ($out, $err) = run_cmd(\@cmd);
  -e "$file_name.fai" or die "could not find fasta index";
}

sub snpeff_build_reference {
  my $gid = shift or die "must provide a genome id";
  my $fasta = shift or die "must provide fasta";
  my $gff = shift or die "must provide gff";
  my $data_dir = shift or die "must provide a data dir";
  -d $data_dir or die "data dir is not a valid directory";

  my $ver = "p3." . $gid;

  print "making dir $data_dir/$ver" , "\n";
  !system ( "mkdir", "-p", "$data_dir/$ver" )
    or die "cannot make dir";

  write_to_file($fasta, "$data_dir/$ver/sequences.fa");
  write_to_file($gff, "$data_dir/$ver/genes.gff");

  my $cwd = getcwd;
  chdir "$data_dir"  or die "can not chdir to $tmp_dir";
  my @cmd = ("snpEff.sh", "build", "-c", "$data_dir/snpEff.config", "-gff3", "-v", $ver);
  my ($out, $err) = run_cmd(\@cmd);
  chdir $cwd;
}

sub get_json_genome {
  my $gid = shift or die "must provide a genome id";
  my $accept_header = "accept: application/json";
  my $url = $data_url . "/genome/$gid";
  my @cmd = ( "curl", "-s", "-H", $accept_header , $url);
  my ($out, $err) = run_cmd(\@cmd);
  return $out;
}

sub get_fasta {
  my $gid = shift or die "must provide a genome id";
  my $accept_header = "accept: application/dna+fasta";
  my $url = $data_url . "/genome_sequence/?eq(genome_id,$gid)&limit(10000)";
  my @cmd = ("curl", "-s", "-H", $accept_header, $url);
  my ($out, $err) = run_cmd(\@cmd);
  return $out;
}

sub get_gff {
  my $gid = shift or die "must provide a genome id";
  my $accept_header = "accept: application/gff";
  my $url = $data_url . "/genome_feature/?and(eq(annotation,PATRIC),eq(genome_id,$gid))&limit(10000)";
  my @cmd = ("curl", "-s", "-H", $accept_header, $url);
  my ($out, $err) = run_cmd(\@cmd);
  return $out;
}

sub write_to_file {
  my ($str, $filename) = @_;
  open F, ">$filename" or die "can not open $filename";
  print "writing to $filename ", substr($str, 0, 24), "\n";
  print F $str;
  close F;
}

sub run_cmd {
  my ($cmd) = @_;
  my ($out, $err);
  print "running ", join " ", @$cmd, "\n";
  run($cmd, '>', \$out, '2>', \$err)
    or die "Error running cmd=@$cmd, stdout:\n$out\nstderr:\n$err\n";
  return ($out, $err);
}

sub unpackage_refdb {}

sub reference_genome_fasta {}

sub reference_genome_snpeff {}

sub reference_genome_mkb {}

1;
