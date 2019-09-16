#!/bin/bash

# s02_extract_header_from_source_vcf.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 16Sep2019

# Note
# The Info/Format fields in the header should be checked and manually updated:  
# keeping only canonical contigs and SplitVarID info field

# Use:
# s02_extract_header_from_source_vcf.sh > s02_extract_header_from_source_vcf.log

# Stop at runtime errors
set -e

# Start message
echo "Extracting header from source vcf"
echo ""

# VCF file
source_vcf="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s04_annotated_vcf/ampliseq_nfe.vcf"
header_file="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s12_joined_PCA/s01_prepare_data_for_joined_PCA/data/s02_header.txt"

# Progress report
echo "source_vcf:"
echo "${source_vcf}"
echo ""
echo "header_file:"
echo "${header_file}"
echo ""

# Extract header
grep ^# "${source_vcf}" > "${header_file}"

# Completion message
echo "Done"
date
echo ""
