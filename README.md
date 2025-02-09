# GDI

GDI is a quality filter for post-imputation data across multiple samples. You can work with a single batch containing several imputed samples or multiple batches, each with several samples. The GDI strategy aims to remove low-quality variants based on a combination of Genotype Probability (GP), Dosage Score (DS), and INFO score.

This process is carried out in several steps:

### 1. Prepare the folder with a file for each batch (`1_PrepareData.sbatch`)
