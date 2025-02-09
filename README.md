# GDI

GDI is a quality filter for post-imputation data across multiple samples. You can work with a single batch containing several imputed samples or multiple batches, each with several samples. The GDI strategy aims to remove low-quality variants based on a combination of Genotype Probability (GP), Dosage Score (DS), and INFO score.

This process is carried out in several steps:

### 1. Prepare the folder with a file for each batch (`PrepareData.sh`). This script assumes all vcf.gz files are present in the folder where the script is run from.
### 2. Prepare a list of common variants (2 columns: CHROM and POS, no header) to work with. (In our case, we created a list of variants from the HRC panel with MAF > 0.05).

```
1_49298_T_C
1_54676_C_T
1_79033_A_G
1_86028_T_C
```
