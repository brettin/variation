#!/usr/bin/env perl
use strict;
use Bio::KBase::Variation::libdb qw(variation_build_db run_cmd);
use Bio::KBase::Variation::VariationConstants qw(aweurl shockurl);
use Bio::KBase::AuthToken;
use JSON;

my $fastqdir = shift or die "must provide fastqdir";
my $p3_genome_id = shift or die "must provide PATRIC genome id";
my $tok = Bio::KBase::AuthToken->new() or die "token undefined";
my $handle = variation_build_db($p3_genome_id);

!system("va-awe_submit", "-rd", "$handle", "-fd", "$fastqdir",
        "-jf", "$$.jobid", "-st",  "$tok->{token}")
  or die "could not execute va-awe_submit -rd $handle -fd ",
         "$fastqdir -jf $$.jobid -st $tok->{token}";
my $jid = `cat $$.jobid`;
chomp $jid;

# wait for the job to finish
my $state;
do {
  sleep 5;
  $state = `awe-job_state $jid`;
  die "could not get state for job $jid" unless $state;
  die "job $jid bad state" if $state =~ /suspend/;
  die "job $jid deleted" if $state =~ /deleted/;
  print $jid, "\t", $state, "\n";
} until ($state =~ /complete/);

# get the urls to the results
my @data_urls = split /\n/, `awe-data_urls $jid`;

my @auth_header = ("-H", "Authorization: OAuth $tok->{token}")  if $tok->{token};
my @curl = ("curl", "-s", @auth_header, '-X', 'GET', );

# download the results
foreach (@data_urls) { 
  my ($url, $outfile) = split /\t/;
  my @cmd = ( @curl, '-o', $outfile, $url);
  !system(@cmd) or die "could not execute ", join " ", @cmd;
}
