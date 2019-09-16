#!/bin/bash

# s02_select_genotypes.sh
# Started: Alexey Larionov, 27Apr2019
# Last updated: Alexey Larionov, 16Sep2019

# Use:
# ./s02_select_genotypes.sh > s02_select_genotypes.sh  

# Select 1kgp genotypes for 1,147 sites for joined PCA plot

# Stop at runtime errors
set -e

# Start message
echo "Select 1kgp genotypes for 1,135 sites for joined PCA plot"
date
echo ""

# Files and folders 
base_folder="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe"
working_folder="${base_folder}/s12_joined_PCA/s02_prepare_1kgp_genotypes"
data_folder="${working_folder}/data"

source_1135_vcf="${data_folder}/s01_1kgp_1838_intersect_sites.vcf.gz"
source_1kgp_folder="/Users/alexey/Documents/resources/1kgp"

target_folder="${data_folder}/s02_by_chromosome"
mkdir -p "${target_folder}"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "source_1135_vcf: ${source_1135_vcf}"
echo "source_1kgp_folder: ${source_1kgp_folder}"
echo "target_folder: ${target_folder}"
echo ""
echo "--- Tools ---"
echo ""
bcftools --version
echo ""
echo "--- Progress ---"
echo ""

# Prepare list of chromosomes
chromosomes="chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22"

echo "List of chromosomes:"
echo "${chromosomes}"
echo ""

# Make intersect files
echo "Looking for the genotypes ..."

# For each chromosome
for chromosome in ${chromosomes}
do

  # Make file names
  source_1kgp_vcf="${source_1kgp_folder}/${chromosome}_fixed.vcf.gz"
  output_vcf="${target_folder}/${chromosome}.vcf.gz"
  
  # Look for the intersect (in parallel)
  bcftools isec \
    --output "${output_vcf}" \
    --output-type z \
    --nfiles=2 \
    --write 1 \
    "${source_1kgp_vcf}" \
    "${source_1135_vcf}" &
  
done # Next chromosome

wait

# Index and count
echo "Index and count ..."
total_count=0

for chromosome in ${chromosomes}
do

  # Get file name
  vcf="${target_folder}/${chromosome}.vcf.gz"

  # Index
  bcftools index -f "${vcf}"
  
  # Count
  num_var=$(bcftools view -H "${vcf}" | wc -l)
  echo -e "${chromosome}\t${num_var}" 
  total_count=$(( ${total_count} + ${num_var} ))

done # Next chromosome

# Progress report
echo ""
echo "Done all autosomes"
echo ""
echo "The total count of selected variants:"
printf "%'d\n" "${total_count}"
echo ""
date
echo ""
