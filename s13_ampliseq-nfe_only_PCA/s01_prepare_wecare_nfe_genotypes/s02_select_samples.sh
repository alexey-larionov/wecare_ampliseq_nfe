#!/bin/bash

# s02_select_samples.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 17Sep2019

# Use:
# ./s02_select_samples.sh > s02_select_samples.log

# Select 712 ampliseq-nfe samples for joined PCA

# Stop at runtime errors
set -e

# Start message
echo "Select 712 ampliseq-nfe samples for joined PCA"
date
echo ""

# --- Files and folders --- #

base_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/"

data_folder="${base_folder}/s13_ampliseq-nfe_only_PCA/s01_prepare_wecare_nfe_genotypes/data"

source_samples_file="${base_folder}/s12_joined_ampliseq-nfe_1kgp_PCA/s01_prepare_data_for_joined_PCA/data/s01_ampliseq_nfe_712_samples.txt"
source_ampliseq_nfe_1838_739_vcf="${data_folder}/s01_ampliseq_nfe_1838_739.vcf.gz"
target_ampliseq_nfe_1838_712_vcf="${data_folder}/s02_ampliseq_nfe_1838_712.vcf.gz"

# --- Progress report --- #

echo "--- Files and folders ---"
echo ""
echo "source_samples_file: ${source_samples_file}"
echo "source_ampliseq_nfe_1838_739_vcf: ${source_ampliseq_nfe_1838_739_vcf}"
echo "target_ampliseq_nfe_1838_712_vcf: ${target_ampliseq_nfe_1838_712_vcf}"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
echo "--- Progress ---"
echo ""

# --- Select samples --- #

echo "Number of samples in the source samples file:"
cat "${source_samples_file}" | wc -l
echo ""

echo "Selecting samples ..."

bcftools view \
  --samples-file "${source_samples_file}" \
  --output-type z \
  --output-file "${target_ampliseq_nfe_1838_712_vcf}" \
  "${source_ampliseq_nfe_1838_739_vcf}"

bcftools index -f "${target_ampliseq_nfe_1838_712_vcf}"

echo ""

# --- Count variants --- #
echo "Number of variants in the output:" 
num_variants=$(bcftools view -H "${target_ampliseq_nfe_1838_712_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

# --- Count samples --- #
echo "Number of samples in the output:" 
num_fields=$(bcftools view -h "${target_ampliseq_nfe_1838_712_vcf}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo ""

# Progress report
echo "Done"
date
echo ""
