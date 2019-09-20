#!/bin/bash

# s01_calculate_PCs.sh
# Started: Alexey Larionov, 13Jul2019
# Last updated: Alexey Larionov, 17Sep2019

# Use:
# ./s01_calculate_PCs.sh > s01_calculate_PCs.log

# Calculate PCs for joined 1kgp-ampliseq-nfe dataset (excluding rare variants and variants in LD)

# Stop at runtime errors
set -e

# Start message
echo "Calculate PCs for ampliseq-nfe only dataset (excluding rare variants and variants in LD)"
date
echo ""

# Files and folders 
base_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s13_ampliseq-nfe_only_PCA"

data_folder="${base_folder}/s02_calculate_ampliseq_nfe_only_PCs/data"
rm -fr "${data_folder}"
mkdir -p "${data_folder}"

source_vcf="${base_folder}/s01_prepare_wecare_nfe_genotypes/data/s02_ampliseq_nfe_1838_712.vcf.gz"

# Tools
plink="/Users/alexey/Documents/tools/plink_19/plink_1.9-b6.10/plink"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo "source_vcf: ${source_vcf}"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
"${plink}" --version
echo ""
echo "--- Progress ---"
echo ""

# --- Count variants and samples in the sourse VCF --- #

echo "Number of variants in the input VCF:" 
num_variants=$(bcftools view -H "${source_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

echo "Number of samples in the input VCF:" 
num_fields=$(bcftools view -h "${source_vcf}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo "" 

# --- Import VCF to PLINK --- #

plink_dataset_folder="${data_folder}/s01_vcf_to_plink"
rm -fr "${plink_dataset_folder}"
mkdir -p "${plink_dataset_folder}"
initial_plink_dataset="${plink_dataset_folder}/ampliseq_nfe_1838_712"

# --vcf-half-call describes what to do with genotypes like 0/.
# --allow-no-sex suppresses warning about missed sex
# --double-id puts sample name to both Family-ID and Participant-ID
# --silent suppresses very verbous ouput to the "out" file (log file is still avaialble in the data folder)

"${plink}" \
  --vcf "${source_vcf}" \
  --vcf-half-call "missing" \
  --double-id \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${initial_plink_dataset}"

echo "Imported VCF to PLINK (bed-bim-fam file-set)"
echo ""

# --- Exclude low frequency variants --- #
# http://www.cog-genomics.org/plink/1.9/filter#maf
# --maf filters out all variants with minor allele frequency below the provided threshold (default 0.01)
# --max-maf imposes an upper MAF bound. 
# Similarly, --mac and --max-mac impose lower and upper minor allele count bounds, respectively.

output_data_folder="${data_folder}/s02_exclude_rare_variants"
rm -fr "${output_data_folder}"
mkdir -p "${output_data_folder}"
common_variants="${output_data_folder}/ampliseq_nfe_1kgp_non_rare_308_712"

"${plink}" \
  --bfile "${initial_plink_dataset}" \
  --maf 0.01 \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${common_variants}"

echo "Excluded rare variants"
echo ""

# --- Exclude variants in LD --- #

# Output folder
output_data_folder="${data_folder}/s03_exclude_variants_in_LD"
rm -fr "${output_data_folder}"
mkdir -p "${output_data_folder}"

# Output files
pairphase_LD="${output_data_folder}/pairphase_LD"
LD_pruned_datset="${output_data_folder}/ampliseq_nfe_1kgp_non_rare_not_in_LD_215_712"

# Determine variants in LD
# Command indep-pairphse makes two files:
# - list of variants in LD (file with extension .prune.out)
# - list of cariants not in LD (extension .prune.in)

# --indep-pairphase is just like --indep-pairwise, 
# except that its r2 values are based on maximum likelihood phasing
# http://www.cog-genomics.org/plink/1.9/ld#indep

# The specific parameters 50 5 0.5 are taken from an example 
# discussed in PLINK 1.07 manual for LD prunning
# http://zzz.bwh.harvard.edu/plink/summary.shtml#prune
# It does the following:
# a) considers a window of 50 SNPs
# b) calculates LD between each pair of SNPs in the window 
# c) removes one of a pair of SNPs if the LD is greater than 0.5
# d) shifts the window 5 SNPs forward and repeat the procedure

"${plink}" \
  --bfile "${common_variants}" \
  --indep-pairphase 50 5 0.5 \
  --allow-no-sex \
  --silent \
  --out "${pairphase_LD}"

# Make a new bed-bim-fam file-set w/o the variants in LD
# using the list of variants in LD created in the previous step

"${plink}" \
  --bfile "${common_variants}" \
  --exclude "${pairphase_LD}.prune.out" \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${LD_pruned_datset}"

echo "Excluded variants in LD"
echo ""

# --- Calculate 100 top PCs --- #
# "header" and "tabs" are options to format output

pca_results_folder="${data_folder}/s04_pca"
rm -fr "${pca_results_folder}"
mkdir -p "${pca_results_folder}"
pca_results="${pca_results_folder}/ampliseq_nfe_215_712_100PCs"

"${plink}" \
  --bfile "${LD_pruned_datset}" \
  --pca 100 header tabs \
  --allow-no-sex \
  --silent \
  --out "${pca_results}"

echo "Calculated 100 top PCs for ampliseq-nfe dataset using 215 non-rare variants not in LD"
echo ""

# Progress report
echo "Done all tasks"
date
echo ""
