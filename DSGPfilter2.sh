#!/bin/bash

#HOW2RUN: qsub DSGPfilter2.sh -F "Y Z A"
# Where Y is the first decimal value of the INFO_SCORE filter (e.g., 4, 6), Z is the GP filter value (e.g., 0.99 or 0.9), and A il file remove_batch)

cd $SLURM_SUBMIT_DIR

###
# VARIABLES
###

IS=$1
GP=$2
list=$3

path=$PWD
scripts="${path}/scripts"
outpath="${path}/batches/MetricsBySample"
keep_folder=${outpath}/KEEP
remove_folder=${outpath}/REMOVE
exclude=${outpath}/EXCLUDE
mkdir -p $keep_folder $remove_folder $exclude

while IFS= read -r sample; do
batch=$(echo "$sample" | cut -d '.' -f 2)
var="$batch"
echo "${outpath}/batch$var.IS0.4/keep.GP0.99/${sample}.keep" >> "${outpath}/move_remove_keep_file"
echo "${outpath}/batch$var.IS0.4/remove.GP0.99/${sample}.remove" >>"${outpath}/move_remove_keep_file"
done < "$list"

# Move outliers' keep and remove files
while read filename; do
mv "$filename" $exclude
done < ${outpath}/move_remove_keep_file ## List of keep and remove files for outliers of each batch with full path.

# Prepare following files using only the remaining samples
cat ${outpath}/batch*.IS0.${IS}/keep.GP${GP}/Sample*.*.${IS}.${GP}.keep > ${keep_folder}/KEEP &
cat ${outpath}/batch*.IS0.${IS}/remove.GP${GP}/Sample*.*.${IS}.${GP}.remove > ${remove_folder}/REMOVE &
wait
perl ${scripts}/count.pl ${keep_folder}/KEEP ${keep_folder}/count.keep &
perl ${scripts}/count.pl ${remove_folder}/REMOVE ${remove_folder}/count.remove &
wait
cut -f1 ${keep_folder}/count_keep | sort | uniq -d -c | sort -k2 -n > ${keep_folder}/count.keep.group &
cut -f1 ${remove_folder}/count.remove | sort | uniq -d -c | sort -k2 -n > ${remove_folder}/count.remove.group &
wait
echo "DSGPfilter2.pbs ended! Now use the output files to decide what variants to remove!"
