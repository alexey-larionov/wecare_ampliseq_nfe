#!/bin/bash

# s03_make_1838_sites_vcf.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 16Sep2019

# Use:
# s03_make_1838_sites_vcf.sh > s03_make_1838_sites_vcf.log

# Stop at runtime errors
set -e

# Start message
echo "Making 1838 sites vcf file"
date
echo ""

# Files and folders
data_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s12_joined_PCA/s01_prepare_data_for_joined_PCA/data"

variants_file="${data_folder}/s01_ampliseq_nfe_1838_vars.txt"
header_file="${data_folder}/s02_header.txt"
output_vcf="${data_folder}/s03_1838_sites.vcf"

# Progress report
echo "--- Files ---"
echo ""
echo "header_file: ${header_file}"
echo "variants_file: ${variants_file}"
echo "output_vcf: ${output_vcf}.gz"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
echo "--- Progress ---"
echo ""

# Check number of variants in the input file
echo "Number of lines in the input variants file (excluding the line for header)"
echo $(( $(cat ${variants_file} | wc -l) - 1 ))
echo ""

# Add header to variants
echo "Adding VCF header to variants ..."
cat "${header_file}" "${variants_file}" > "${output_vcf}"

# Compress and index
echo "Compressing and indexing ..."
bcftools view \
  --output-file "${output_vcf}.gz" \
  --output-type z \
  "${output_vcf}"

bcftools index "${output_vcf}.gz"

# Count variants
echo ""
echo "Number of variants in the output VCF:" 
bcftools view -H "${output_vcf}.gz" | wc -l

# Clean-up
rm "${output_vcf}"

# Completion message
echo ""
echo "Done"
date
echo ""
