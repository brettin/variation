### Full Run - Minimal Command Set ###

mosaik_build.pl -fq1 /vagrant/data/biosample/SAMN02628526/SRR1180141_1.fastq.gz,/vagrant/data/biosample/SAMN02628526/SRR1183064_1.fastq.gz -fq2 /vagrant/data/biosample/SAMN02628526/SRR1180141_2.fastq.gz,/vagrant/data/biosample/SAMN02628526/SRR1183064_2.fastq.gz -bd /vagrant/data/biosample/SAMN02628526/build

mosaik_align.pl -mkb /vagrant/data/biosample/SAMN02628526/build/SRR1180141.mkb,/vagrant/data/biosample/SAMN02628526/build/SRR1183064.mkb -ad /vagrant/data/biosample/SAMN02628526/align -rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.mkb -t 4

bamtools_sort.pl -bam /vagrant/data/biosample/SAMN02628526/align/SRR1180141.mkb.bam,/vagrant/data/biosample/SAMN02628526/align/SRR1183064.mkb.bam

bamutil_dedup.pl -bam /vagrant/data/biosample/SAMN02628526/align/SRR1180141.mkb.sorted.bam,/vagrant/data/biosample/SAMN02628526/align/SRR1183064.mkb.sorted.bam

freebayes_run.pl -bam /vagrant/data/biosample/SAMN02628526/align/SRR1180141.mkb.sorted.dedup.bam,/vagrant/data/biosample/SAMN02628526/align/SRR1183064.mkb.sorted.dedup.bam -rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.fasta -o /vagrant/data/biosample/SAMN02628526/align/out.vcf


### Step by step discussion ###


### Build the mosaik file for the reference genome ###

# -fr is the fasta reference genome (.fasta or .fa suffix required).
# -o  is the .mkb formatted reference genome used by the Mosaik aligner.
mosaik_build_ref.pl \
        -fr /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.fasta \
        -o /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.mkb



### Build mosaik files from the fastq files ###

# Option 1: provide a directory that contains the fastq files.
# -fd is the fastq_directory where the _1.fastq and _2.fastq files are.
# -bd is build dir. This is where the fastq.mkb files go.
mosaik_build.pl \
        -fd /vagrant/data/biosample/ERS325081 \
	-bd /vagrant/data/biosample/ERS325081/build

# Option 2: provide the fastq files by name.
# -fq1 is a comma separated list of fastq files.
# -fq2 is a comma separated list of the mates, ordered to match -fq1 files.
mosaik_build.pl \
	-fq1 /vagrant/data/biosample/SAMN02628523/SRR1180184_1.fastq.gz,/vagrant/data/biosample/SAMN02628523/SRR1183085_1.fastq.gz \
	-fq2 /vagrant/data/biosample/SAMN02628523/SRR1180184_2.fastq.gz,/vagrant/data/biosample/SAMN02628523/SRR1183085_2.fastq.gz \
	-bd /vagrant/data/biosample/SAMN02628523/build



### Align reads to reference ###

# Option 1: provide a directory that contains the mosaik build files.
# -bd is the build dir, same as above.
# -ad is the align dir where the alignments (bam files) are put.
mosaik_align.pl \
	-bd /vagrant/data/biosample/ERS325081/build \
	-ad /vagrant/data/biosample/ERS325081/align \
	-rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.mkb \
	-annpe /usr/local/bin/2.1.78.pe.ann \
	-annse /usr/local/bin/2.1.78.se.ann \
	-t 1 

# Option 2: provide the mosaik build files by name
# -mkb is a comma separated (no whitespaces) list of mosaik build files
mosaik_align.pl \
	-mkb /vagrant/data/biosample/SAMN02628523/build/SRR1183085.mkb \
	-ad /vagrant/data/biosample/SAMN02628523/align \
	-rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.mkb \
	-t 4



# Sort the resulting bam files

# Option 1: You can sort the bamfiles using the bamttols executable.
bamtools sort \
	-in /vagrant/data/biosample/ERS325081/align/ERR353353.mkb.bam \
	-out /vagrant/data/biosample/ERS325081/align/ERR353353.mkb.sorted.bam


bamtools sort \
	-in /vagrant/data/biosample/ERS325081/align/ERR357439.mkb.bam \
	-out /vagrant/data/biosample/ERS325081/align/ERR357439.mkb.sorted.bam

# Option 2: You can use the bamtools_sort.pl wrapper, which will give you
# the option of providing a directory containing the bam files to sort or
# a comma separated list of bam files to sort.
bamtools_sort.pl \
	-bam /vagrant/data/biosample/SAMN02628522/align/SRR1180179.mkb.bam


# need some work on the sort. Right now, the original bam and the sorted bam
# files will be present in the align_dir, so freebayes_run will pick up both.

freebayes_run.pl \
	-rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.fasta \
	-ad /vagrant/data/biosample/ERS325081/align \
	-o /vagrant/data/biosample/ERS325081/variants/out.vcf 

# Option 2: provide the sorted bam files by name
# -rg is the reference genome in fasta format
# -bam is the comma separated (no whitespaces) list of sorted bam files.
# -o is the full name of the output vcf file.
freebayes_run.pl \
	-rg /vagrant/data/reference/Mycobacterium_tuberculosis_H37Rv.fasta \
	-bam /vagrant/data/biosample/SAMN02628523/align/SRR1180184.mkb.sorted.bam,/vagrant/data/biosample/SAMN02628523/align/SRR1183085.mkb.sorted.bam 
	-o /vagrant/data/biosample/SAMN02628523/align/out.vcf

