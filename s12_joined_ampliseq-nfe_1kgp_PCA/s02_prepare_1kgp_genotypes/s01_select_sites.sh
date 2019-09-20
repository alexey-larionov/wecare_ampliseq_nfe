#!/bin/bash

# s01_select_sites.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 16Sep2019

# Use:
# ./s01_select_sites.sh > s01_select_sites.log

# Select overlap between 1,838 ampliseq sites and ~84M 1kgp sites for joined PCA

# Stop at runtime errors
set -e

# Start message
echo "Select overlap between 1,838 ampliseq sites and ~84M 1kgp sites for joined PCA"
date
echo ""

# Files and folders 
base_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s12_joined_PCA"

source_1838_vcf="${base_folder}/s01_prepare_data_for_joined_PCA/data/s03_1838_sites.vcf.gz"

kgp_folder="/Users/alexey/Documents/resources/1kgp"
source_1kgp_vcf="${kgp_folder}/ALL.wgs.phase3_shapeit2_mvncall_integrated_v5a.20130502.sites.fixed.filt.biallelic.vcf.gz"

data_folder="${base_folder}/s02_prepare_1kgp_genotypes/data"
mkdir -p "${data_folder}"
target_vcf="${data_folder}/s01_1kgp_1838_intersect_sites.vcf.gz"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "source_1838_vcf: ${source_1838_vcf}"
echo "source_1kgp_vcf: ${source_1kgp_vcf}"
echo "target_vcf: ${target_vcf}"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
echo "--- Progress ---"
echo ""

# Count variants in source files

echo "Number of variants in source_1838_vcf:" 
num_variants=$(bcftools view -H "${source_1838_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

echo "Number of variants in source_1kgp_vcf:" 
num_variants=$(bcftools view -H "${source_1kgp_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

# --- Make intersect --- #
echo "Looking for the intesect ..."

bcftools isec \
  --output "${target_vcf}" \
  --output-type z \
  --nfiles=2 \
  --write 1 \
  "${source_1kgp_vcf}" \
  "${source_1838_vcf}"

bcftools index "${target_vcf}"

echo ""

# --- Count variants --- #
echo "Number of variants in the intesect:" 
num_variants=$(bcftools view -H "${target_vcf}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

# Progress report
echo "Done"
date
echo ""
