echo `date`

if [ ! -e test/SAMN01828242/SRR832983.mkb ]
then
  va-awe_mosaik_build -fq1 test/SAMN01828242/SRR832983_1.fastq.gz -fq2 test/SAMN01828242/SRR832983_2.fastq.gz -o test/SAMN01828242/SRR832983.mkb
fi


if [ ! -e test/SAMN01828242/SRR832983.bam ]
then
  va-awe_mosaik_align -mkb test/SAMN01828242/SRR832983.mkb -o test/SAMN01828242/SRR832983 -rg /mnt/reference/mosaik/Mycobacterium_tuberculosis_H37Rv.mkb -t 4 -annpe /kb/runtime/bin/2.1.78.pe.ann -annse /kb/runtime/bin/2.1.78.se.ann
fi


if [ ! -e test/SAMN01828242/SRR832983.sorted.bam ]
then
  va-awe_bamtools_sort -bam test/SAMN01828242/SRR832983.bam -o test/SAMN01828242/SRR832983.sorted.bam
fi


if [ ! -e test/SAMN01828242/SRR832983.sorted.dedup.bam ]
then
  va-awe_bamutil_dedup -bam test/SAMN01828242/SRR832983.sorted.bam -o test/SAMN01828242/SRR832983.sorted.dedup.bam
fi


if [ ! -e test/SAMN01828242/out.vcf ]
then
  va-awe_freebayes_run -bam test/SAMN01828242/SRR832983.sorted.dedup.bam -o test/SAMN01828242/out.vcf -rg /mnt/reference/mosaik/Mycobacterium_tuberculosis_H37Rv.fasta
fi

echo `date`

# mosaik_build.pl -fq1 SRR832983_1.fastq.gz,SRR833041_1.fastq.gz,SRR833180_1.fastq.gz,SRR833012_1.fastq.gz,SRR833088_1.fastq.gz,SRR833182_1.fastq.gz -fq2 SRR832983_2.fastq.gz,SRR833041_2.fastq.gz,SRR833180_2.fastq.gz,SRR833012_2.fastq.gz,SRR833088_2.fastq.gz,SRR833182_2.fastq.gz
