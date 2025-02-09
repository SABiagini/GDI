#!/bin/bash

cd $SLURM_SUBMIT_DIR
pwd=$PWD
outpath="${pwd}/batches"
mkdir -p $outpath
counter=1
for i in ${pwd}/*.vcf.gz
do
output_file="batch${counter}.vcf.gz"
bcftools norm -d none "$i" --threads 8 -Ou | bcftools annotate --set-id '%CHROM\_%POS\_%REF\_%ALT' --threads 8 -Oz -o ${outpath}/$output_file &&
bcftools index ${outpath}/$output_file &
((counter++))DSGPfilter1.pbs
done
wait
