#!/bin/bash

# s03_merge_genotypes.sh
# Started: Alexey Larionov, 28Apr2019
# Last updated: Alexey Larionov, 16Sep2019

# Use:
# ./s03_merge_genotypes.sh > s03_merge_genotypes.log

# Merge genotypes for 1,130 variants from 1kgp for joined PCA

# Stop at runtime errors
set -e

# Start message
echo "Merge genotypes for 1,130 variants from 1kg for joined PCA"
date
echo ""

# --- Files and folders --- #

start_folder="$(pwd)"

base_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe"
working_folder="${base_folder}/s12_joined_PCA/s02_prepare_1kgp_genotypes"
data_folder="${working_folder}/data"

source_data_folder="${data_folder}/s02_by_chromosome"

tmp_folder="${data_folder}/tmp_sort"
rm -fr "${tmp_folder}"
mkdir "${tmp_folder}"

# The preliminary evaluation showed that the output files should contain 1,130 variants
unsorted_vcf="${data_folder}/unsorted.vcf.gz"
output_vcf="${data_folder}/s03_1kgp_1130_2504.vcf.gz"

# --- Progress report --- #

echo "--- Files and folders ---"
echo ""
echo "start_folder: ${start_folder}"
echo "source_data_folder: ${source_data_folder}"
echo "output_vcf: ${output_vcf}"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
echo "--- Progress ---"
echo ""

# Get list of files to concatenate
cd "${source_data_folder}"
list_of_files=$(ls *.vcf.gz)

# Progress report
num_of_files=$(wc -w <<< ${list_of_files})
echo "Detected ${num_of_files} files to concatenate"
echo ""

# Concatenate
echo "Concatenating ..."
echo ""

bcftools concat \
  ${list_of_files} \
  --allow-overlaps \
  --output "${unsorted_vcf}" \
  --output-type z

# Restore start working folder
cd "${start_folder}"

# Sort
bcftools sort \
  "${unsorted_vcf}" \
  --max-mem 4G \
  --temp-dir "${tmp_folder}" \
  --output-file "${output_vcf}" \
  --output-type z

# Index
bcftools index -f "${output_vcf}"
  
# --- Count variants --- #

echo ""
echo "Number of variants in the output:" 
num_variants=$(bcftools view -H "${output_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"

# --- Count samples --- #
#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT ...

echo ""
echo "Number of samples in the output:" 
num_fields=$(bcftools view -h "${output_vcf}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo ""

# Clean-up
rm "${unsorted_vcf}"

# Progress report
echo "Done"
date
echo ""
