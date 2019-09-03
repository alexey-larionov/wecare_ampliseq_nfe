#!/bin/bash

# s03_merge_genotypes.sh
# Started: Alexey Larionov, 28Apr2019
# Last updated: Alexey Larionov, 10Jul2019

# Use:
# sbatch s03_merge_genotypes.sh

# Select 1,140 genotypes from 1kg for joined PCA plot

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s03_merge_genotypes
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s03_merge_genotypes.log
#SBATCH --ntasks=4
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4 

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Allocated node: $(hostname)"
echo "Time: $(date)"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo "------------------ Output ------------------"
echo ""

# ---------------------------------------- #
#                    job                   #
# ---------------------------------------- #

# Stop at runtime errors
set -e

# Start message
echo "Select 1,140 genotypes from 1kg for joined PCA plot"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"

output_data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results/s15_prepare_1kg_genotypes_for_PCA"
source_data_folder="${output_data_folder}/by_chromosome"

# The preliminary evaluation showed that the output files should contain 1,140 variants
unsorted_vcf="${output_data_folder}/selected_1140_1kg_genotypes_unsorted.vcf.gz"
output_vcf="${output_data_folder}/selected_1140_1kg_genotypes.vcf.gz"

tmp_folder="${output_data_folder}/tmp_sort"
rm -fr "${tmp_folder}"
mkdir "${tmp_folder}"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "source_data_folder: ${source_data_folder}"
echo "output_vcf: ${output_vcf}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo ""

# Get list of files to concatenate
cd "${source_data_folder}"
list_of_files=$(ls *.vcf.gz)

# Progress report
num_of_files=$(wc -w <<< ${list_of_files})
echo "Detected ${num_of_files} files to concatenate"
echo ""

# Index source files
echo "Indexing ..."
echo ""

for file in ${list_of_files}
do
  "${bcftools}" index -f "${file}"
done

# Concatenate
echo "Concatenating ..."
echo ""

"${bcftools}" concat \
  ${list_of_files} \
  --allow-overlaps \
  --output "${unsorted_vcf}" \
  --output-type z

# Restore working folder
cd "${scripts_folder}"

# Sort
"${bcftools}" sort \
  "${unsorted_vcf}" \
  --max-mem 24G \
  --temp-dir "${tmp_folder}" \
  --output-file "${output_vcf}" \
  --output-type z

# Index
"${bcftools}" index -f "${output_vcf}"
  
# Explore result
num_var=$("${bcftools}" view -H "${output_vcf}" | wc -l)
echo "Number of variants in concatenated vcf: ${num_var}"
echo ""

# Clean-up
rm "${unsorted_vcf}"

# Progress report
echo "Done"
date
echo ""
