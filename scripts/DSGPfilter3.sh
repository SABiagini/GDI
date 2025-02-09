#!/bin/bash

cd $SLURM_SUBMIT_DIR

#HOW2RUN: sbatch DSGPfilter3.sh FILEbaseNAME IS GP (e.g., bash DSGPfilter3.sh AllSamples.GDI 4 99)

###
# VARIABLES
###

batch=$1 # File name with no extension (e.g., AllSamples.GDI)
IS=$2
GP=$3
path=$PWD
scripts="${path}/scripts"
num_cores=8
metrics=${batch}_metrics.txt
input_file_basename=$(basename "${metrics}" .txt)
metrics_IS="${input_file_basename}.txt" 

awk_script='FNR==NR {a[$1]; next} !($1 in a) {print $0 > FILENAME".out"}'

#1# Keep only specific fields for each sample for downstream analyses
current_batch="${path}/batches/ALL"
mkdir -p $current_batch &&
mv ${path}/batches/${batch}.vcf.gz* $current_batch &&
path2="${current_batch}/metrics" &&
mkdir -p $path2 &&
bcftools query -f '%CHROM\_%POS\_%REF\_%ALT[\t%GT\_%GP\_%DS]\n'
${current_batch}/${batch}.vcf.gz > ${path2}/${metrics} &&

#2# Split by sample (creates a file per sample with variant ID and metrics)
# The file ${batch}_metrics.txt is divided by individual
outpath="${path}/batches/MetricsBySample" &&
folder=${outpath}/${batch}
mkdir -p $folder

# Extract number of samples in current batch
num=$(bcftools query -l ${current_batch}/${batch}.vcf.gz | wc -l)

# Create output files
for ((j=1; j<=$num; j++)); do
filename="${folder}/Sample${j}.${batch}.txt"
if [[ ! -s $filename ]]; then
touch $filename
fi
done

# Check if all files have correct length
# controlla il valore di IS e imposta ref_length (che scelgo io in base ai filtri che già ho impostato in precedenza)
# Catturo la lunghezza di ${path2}/${metrics} perchè è esattamente il numero di varianti con MAF>0.05 che sono ritrovate nei file imputati, che non sono necessariamente tutte le varianti con MAF>0.05 dell'HRC perché magari non tutte le varianti sono state imputate

reflength=$(wc -l < ${path2}/${metrics})
IS_removed=$(wc -l < ${path}/INFOSCOREbyBatch/remove-IS0.${IS}.txt)
expectedSites=$((reflength - IS_removed))
ref_length=$expectedSites

# stampa il valore di $expectedSites
echo "Per INFO SCORE 0.${IS}, the number of expected sites is $expectedSites" >> ${outpath}/${batch}.log &&

# Extract and modify columns for each file# 

for ((col=2; col<=($num+1); col++)); do
outname="${folder}/Sample$((col-1)).${batch}.txt"
if [[ ! -s $outname ]]; then
awk -v OFS="\t" -v col=$col '{{gsub(/[_|,]/,"\t",$col); print $1,$col}}' "${path2}/${metrics_IS}" >> "${outname}" &
else
length=$(wc -l < "$outname")
if [[ $length -eq $expectedSites ]]; then
echo "Sample$((col-1)) is completed" >> ${outpath}/${batch}.log
else
start_line=$(awk 'END{print NR}' "$outname")
echo "Sample$((col-1)) restarts from line $start_line" >> ${outpath}/${batch}.log
sed -i "${start_line}d" "$outname"
awk -v OFS="\t" -v col=$col -v start_line=$start_line '{{gsub(/[_|,]/,"\t",$col); if (NR>=start_line) print $1,$col}}' "${path2}/${metrics_IS}" >> "${outname}" &
fi
fi
done
# wait for the current batch of jobs to finish before starting the next one
wait
# Wait until all files have been written
wait
seq=$(seq 1 $num)
find ${folder} -maxdepth 1 -name "Sample*.${batch}.txt" -print0 | parallel -0 -j 10 "filename=${folder}/Sample{}.${batch}.txt; len=\$(awk 'END{print NR}' \"\${filename}\"); if [[ \$len -ne $expectedSites ]]; then echo 'Error: The file Sample{}.${batch}.txt has a different length than ${path2}/${metrics_IS}.'; fi" ::: $seq &&

#3# Filter variants per sample and creates for each one of them a list of variants to keep and one of variants to remove.

keep_folder=${folder}/keep.GP${GP}
remove_folder=${folder}/remove.GP${GP}
mkdir -p $keep_folder $remove_folder
seq=$(seq 1 $num)
parallel -j $num_cores --delay 2 "f=${folder}/Sample{}.${batch}.txt;keep=${keep_folder}/Sample{}.${batch}.keep; remove=${remove_folder}/Sample{}.${batch}.remove; GP=0.99; perl ${scripts}/DSGPfilter.pl \$f \$keep \$remove \$GP" ::: $seq &&

#4# Create a file with Sample name, count of variants to keep, count of variants to remove, e (ratio variants to remove) / (total variants)

# Find all file with name Sample*.keep in current directory
for keepfile in ${keep_folder}/Sample*.keep; do
# Extract the sample name from the file Sample*.keep.
sample=$(echo "$keepfile" | sed 's/\.keep//')
sample_basename=$(basename $sample)
# Initialize the output variables
keepsize=0
removesize=0
ratio=0
# Calculate the size of the file Sample*.keep
keepsize=$(wc -l < "$keepfile")
# Find the corresponding file Sample*.remove
removefile="${remove_folder}/${sample_basename}.remove"
# Calculate the size of the file Sample*.remove
removesize=$(wc -l < "$removefile")
# Calculate the ratio between the size of the file Sample.remove and the sum of the sizes of Sample.keep and Sample*.remove
total=$(($keepsize + $removesize))
ratio=$(echo "scale=2; $removesize / $total" | bc)
# Print risults
echo "$sample_basename $keepsize $removesize $ratio" >>
${folder}/Sample_badness.${batch}.txt
done
echo "DSGPfilter3.pbs done! Now check the Sample_badness list to observe the new distribution after the GDI filter has been applied." >> ${outpath}/${batch}.log
