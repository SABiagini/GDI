#!/bin/bash

cd $SLURM_SUBMIT_DIR
pwd=$PWD
outpath="${pwd}/INFOSCOREbyBatch"
mkdir -p $outpath

for batch in ${pwd}/batches/batch*.vcf.gz
do
name=$(basename $batch .vcf.gz)
bcftools query -f '%CHROM\t%POS\t%CHROM\_%POS\_%REF\_%ALT\t%INFO_SCORE\n' ${batch} | fgrep -wf ${pwd}/maf/HRCmaf0.05sites.txt - > ${outpath}/infoscore_${name} &
done &&
wait

cat ${outpath}/infoscore_batch* | cut -f 3,4 > ${outpath}/IDs.InfoScores
