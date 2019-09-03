#!/bin/bash

# s03_make_1850_vcf.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 26Apr2019

# Use:
# s03_make_1850_vcf.sh > s03_make_1850_vcf.log

# Stop at runtime errors
set -e

# Start message
echo "Making 1850 sites vcf file"
echo ""

# File names
header="header.txt"
variants="s01_ampliseq_nfe_1850_vars.txt"
output_vcf="s03_1850_sites.vcf"

# Progress report
echo "header: ${header}"
echo "variants: ${variants}"
echo "output_vcf: ${output_vcf}"
echo ""

# Add header to variants
echo "Adding header to variants ..."
cd "/Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s13_eigenvectors_and_outliers"
cat "${header}" "${variants}" > "${output_vcf}"

# Completion message
echo "Done"
date
echo ""
