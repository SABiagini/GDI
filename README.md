# GDI

GDI is a quality filter for post-imputation data across multiple samples. You can work with a single batch containing several imputed samples or multiple batches, each with several samples. The GDI strategy aims to remove low-quality variants based on a combination of Genotype Probability (GP), Dosage Score (DS), and INFO score.

This process is carried out in several steps:

### 1. Prepare the folder with a file for each batch (`PrepareData.sh`). 
This script assumes all vcf.gz files are present in the folder where the script is run from.
### 2. Prepare a list of common variants (2 columns: CHROM and POS, no header) to work with.
In our case, we created a list of variants from the HRC panel with MAF > 0.05:

```
1_49298_T_C
1_54676_C_T
1_79033_A_G
1_86028_T_C
...
...
```
### 3. For each batch, create a list of variants with their INFO score (`extract.infoscore.sh`)
This script will provide for each batch a file listing all the positions with MAF > 0.05 and for each position the corresponding INFO score. For example:

```
1 49298 1_49298_T_C 0.15884
1 54353 1_54353_C_A 1
1 54564 1_54564_G_T 1
1 54591 1_54591_A_G 1
1 54676 1_54676_C_T 0.18757
1 54712 1_54712_T_C 1
...
...
```
### 4. Prepare a list of variants to remove based on the selected INFO score filter (`remove.variants.R`)
The input for this script is the file IDs.InfoScores generated in the previous step. The script groups variants with the same ID from all batches and includes their corresponding INFO scores. If any batch has an INFO score less than or equal to the defined threshold (e.g., 0.4), the variant is flagged as an outlier. This means the variant will be marked for removal, as it does not meet the INFO score requirement across all batches. The script will generate a 2-column file, with the first column showing the variant ID and the second column indicating how many batches the variant failed to pass the INFO score filter:

```
identifiers	NumBelowThreshold
1_49298_T_C	11
1_79033_A_G	4
1_86028_T_C	9
1_234313_C_T	10
...
...
```

### 5. Calculate samples' low quality based on GP, DS, and INFO score.

This step **must be executed separately for each batch** and will consist of one main script (`DSGPfilter1.sbatch`) and an auxiliary one (`DSGPfilter.pl`), which is internally called by the main script.

**Briefly, what `DSGPfilter1.sbatch` does is:**

- Extract variants with MAF > 0.05 (you need the file created in step 2 with two columns: CHROM and POS, no header)
- Apply a GT to GP filter (this step fixes possible post-imputation GP/GT discrepancies)
- Extract only fields of interest for each variant (GT, GP, and DS) for each individual in the file
- Remove variants marked for removal due to the INFO score filter (you'll need the file created in step 4 with the `remove.variants.R` script)
- Split the file by sample
- Apply filters on GP and DS for each sample. This will give a list of variants to remove (as well as a list of variants to keep) for each sample.
- It generates a `Sample_LQV` file for each batch, listing the proportion of LQV variants for each sample prior to filtering variants based on GP and DS.

A Sample_LQV file contains 4 columns:

Sample_ID
Total number of sites
Number of low-quality sites
LQV score (the proportion of low-quality sites)

The **LQV score** is calculated as the ratio of low-quality sites to the total number of sites:

$$
LQV\ score = \frac{\text{Number of low-quality sites}}{\text{Total number of sites}}
$$

```
Sample10.10.4.0.99 5337523 121691 .02
Sample1.10.4.0.99 5168470 290744 .05
Sample12.10.4.0.99 4362019 1097195 .20
Sample13.10.4.0.99 5295058 164156 .03
Sample15.10.4.0.99 5372628 86586 .01
...
...
```
### 6. Observe the sample distribution based on LQV scores before removing low-quality sites (`LQV.outliers.R`).

This step generates a boxplot illustrating the sample distribution and creates a `remove_batch` file containing a list of samples to be removed. If you merge all LQV files into one and run the `LQV.outliers.R` script, you will have a plot like this:



### 7. Run this step after all batches have been processed. 
In this step (`DSGPfilter2.pbs`), you will first remove all the `*.keep` and `*.remove` files from the outlier samples identified in the previous step. Then, it runs the `count.pl` script to count how many sites fail the quality threshold in a specific number of samples (e.g., site `chr10_1234_A_C` fails in 35 samples). It then groups the sites based on how frequently each number of failures occurs and generates a new file with the frequency of these failure counts. The resulting file shows how many sites failed in exactly "x" number of samples and how often that number of failures appears in the dataset. For this script, you will need the `remove_batch` file, which contains the list of detected outliers.

### 8. Generate a list of variants to remove based on quality threshold failures across samples.

The file `count.remove.group` contains the distribution of how many samples each variant failed the quality thresholds. The script `plot_variants_to_remove.R` generates a scatter plot visualizing how many variants failed in each sample count category. The plot helps to determine an appropriate cutoff for removing variants by allowing the user to visually inspect the distribution of failures. Based on this, the user can choose a threshold that filters variants exceeding a certain number of sample failures, marked by a vertical line on the plot. The number of variants exceeding this threshold is calculated and displayed.

The purpose of this process is to strike a balance between being too conservative and too aggressive in variant removal. While this may seem arbitrary, it is essential to consider that each dataset is unique, so this step should be approached in a customized way.

After determining the cutoff value, which is stored in the `cutoff` variable from the R script, the list of sites to remove is prepared. This involves filtering the variants that exceed the specified threshold. These variants are extracted, sorted, and processed into the final list for removal:

```bash
awk '$2>60.6' count.remove.group | awk '{print $2}' | sort -n | uniq > 20perc
fgrep -wf 20perc count.remove | awk '{print $2}' > remove20perc
sed 's/\_/\t/g' remove20perc | cut -f1,2 | sort -n -k1 > rem20perc
```

Next, the dataset is merged, retaining only the relevant samples and removing the variants stored in the dedicated file created. Variants previously removed due to failing the INFO score filter are also excluded, and only those variants with a Minor Allele Frequency (MAF) greater than 0.05 are kept. This results in a final list of sites that need to be retained, which is generated and stored in the `FinalSites2Keep.txt` file:

```bash
IS="/path/to/INFOSCOREbyBatch"
remove="/path/to/batches/MetricsBySample/REMOVE"
maf="/path/to/maf"
out="/path/to/scripts"

sed 's/\_/\t/g' ${IS}/remove-IS0.4.txt | cut -f1,2 > ${IS}/remove-IS0.4_4bcftools.txt &&
cat ${remove}/rem20perc ${IS}/remove-IS0.4_4bcftools.txt > ${out}/remove4bcftools
# Use file generated in step 2
fgrep -wvf ${out}/remove4bcftools ${maf}/maf0.05sites.txt | sort | uniq > ${out}/FinalSites2Keep.txt
```

### 9. Merge results
At this point, you can merge all the batches, filtering them to keep only the sites you selected (`FinalSites2Keep.txt`) and the non-outlier samples. You can use, for example, `bcftools merge` and obtain a final file named `AllSamples.GDI.vcf.gz`.

### 10. Calculate LQV scores post-GDI application
You can then run `DSGPfilter3.sh`, a revised version of `DSGPfilter1.sh`, and obtain new LQV scores for the newly filtered samples, as well as plot a new boxplot to compare the sample distribution after applying the GDI filtering strategy.

### 11. Plot comparison pre- and post-GDI application
Run `PrePostGDI.R` to plot a boxplot comparison between the pre-GDI application and post-GDI application.

The input file for this script will be a 3-column file with `SampleID`, `LQV_preGDI`, and `LQV_postGDI`. The header should be:
`ID LQV_preGDI LQV_postGDI`.

### Final Goal

The final goal is to obtain a high-quality dataset, where the retained variants have a high probability of being accurate and useful for subsequent analyses across the entire set of samples.
