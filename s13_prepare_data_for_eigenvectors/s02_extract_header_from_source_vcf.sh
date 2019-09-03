#!/bin/bash

# s02_extract_header_from_source_vcf.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 26Apr2019

# Use:
# s02_extract_header_from_source_vcf.sh > s02_extract_header_from_source_vcf.log

# Stop at runtime errors
set -e

# Start message
echo "Extracting header from source vcf"
echo ""

# VCF file
vcf_file="/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s04_annotated_vcf/ampliseq_nfe.vcf"

# Progress report
echo "Source vcf:"
echo "${vcf_file}"
echo ""

# Extract header
cd "/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s13_eigenvectors_and_outliers"
grep ^# "${vcf_file}" > header.txt

# Completion message
echo "Done"
date
echo ""
