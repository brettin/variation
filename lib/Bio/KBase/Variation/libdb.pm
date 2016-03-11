package Bio::KBase::Variation::libdb;
use Bio::KBase::Variation::VariationConstants qw(p3dataurl);

use IPC::Run qw(run timeout);
use JSON;
use Template;
use Cwd;
use File::Basename;
use File::Temp qw(tempdir);
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

our $data_url = p3dataurl;
our $samtools_exe = "$ENV{KB_RUNTIME}/samtools/bin/samtools";
-e $samtools_exe or die "samtools_exe does not exist, check KB_RUNTIME";

my ($name,$path,$suffix) = fileparse( $INC{"Bio/KBase/Variation/libdb.pm"} );
our $snpeff_config_tt =  $path . "snpEff.config.tt";;
our $dbpath = "/tmp/reference";
our $dbpath = tempdir( "snpeff-XXXXXX", DIR => "/tmp");

print "using $data_url as the data url\n";
print "using $dbpath as the refdb base dir\n";
print "using $snpeff_config_tt as the snpeff.config template\n";

sub variation_build_db {
  my $gid = shift or die "must provide genome id";

  # create database directory in $dbpath
  my $json_text = get_json_genome($gid);
  my $perl_scalar = decode_json($json_text);
  my $genome_name = $perl_scalar->{genome_name};
  $genome_name =~ s/\s/_/g;
  my $data_dir = $dbpath . "/$genome_name";
  !system("mkdir", "-p", $data_dir)
    or die "can not mkdir $data_dir";

  # get genome data from patric
  my $fasta = get_fasta($gid);
  my $gff = get_gff($gid);

  #  snpeff directory
  # snpeff_write_config( $gid, $data_dir );
  # snpeff_build_reference( $gid, $fasta, $gff, $data_dir );

  snpeff_write_config( $genome_name, $data_dir );
  snpeff_build_reference( $genome_name, $fasta, $gff, $data_dir );

  # write genome.fna
  write_to_file($fasta, "$data_dir/$genome_name.fna");
  
  # write genome.mkb
  my @cmd = ("MosaikBuild", "-fr", "$data_dir/$genome_name.fna", "-oa", "$data_dir/$genome_name.mkb");
  my ($out, $err) = run_cmd(\@cmd);

  # write genome.fai
  build_fasta_index("$data_dir/$genome_name.fna");

  # upload to shock
  my $handle = upload_dir_to_shock($data_dir);
  return $handle;
}




# creates a tarball and uploads to shock returning
# the handle file name.
sub upload_dir_to_shock {
  my $data_dir = shift or die "must provide data dir";
  -d $data_dir or die "data_dir is not a directory";
  my $oridir = cwd();
  my $dirname  = dirname($data_dir);
  my $basename = basename($data_dir);

  chdir $dirname or die "can not chdir to $dirname";
  my @cmd = ("tar", "-cvf", "$basename.tar", $basename);
  my ($out, $err) = run_cmd(\@cmd);

  @cmd = ("kbhs-upload", "-i", "$basename.tar", "-o", "$basename.tar.handle");
  my ($out, $err) = run_cmd(\@cmd);

  chdir $oridir or die "can not chdir to $oridir";
  return $dirname . "/" . $basename . ".tar.handle";
}


# $data_dir is used as the data.dir property in snpeff.config
# $gid is patric genome id

sub snpeff_write_config {
  my $gid = shift or die "must provide genome id";
  my $data_dir = shift or die "must provide data dir";
  -d $data_dir or die "data dir is not a valid directory";

  my $json_text = get_json_genome($gid);
  my $perl_scalar = decode_json($json_text);
  my $genome_name = $perl_scalar->{genome_name};
  $genome_name =~ s/\s/_/g;

  my %data = ( 'data_dir'     => '.', 
	'lof_ignoreProteinCodingAfter' => "0.95",
	'lof_ignoreProteinCodingBefore' => "0.05",
	'genome_entry'   => "$gid.genome : $perl_scalar->{genome_name}",
	);
  my $tt = Template->new({ABSOLUTE => 1});
  $tt->process($snpeff_config_tt, \%data, "$data_dir/snpEff.config") or die $tt->error;
}

sub build_fasta_index {
  my $file_name = shift or die "must provide a file name";
  -e $file_name or die "$filename doesn't exist";

  my @cmd = ("$samtools_exe", "faidx", $file_name);
  my ($out, $err) = run_cmd(\@cmd);
  -e "$file_name.fai" or die "could not find fasta index";
}

sub snpeff_build_reference {
  my $gid = shift or die "must provide a genome id";
  my $fasta = shift or die "must provide fasta";
  my $gff = shift or die "must provide gff";
  my $data_dir = shift or die "must provide a data dir";
  -d $data_dir or die "data dir is not a valid directory";

  my $ver = $gid;

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

1;
