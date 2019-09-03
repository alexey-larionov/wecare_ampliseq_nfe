#!/bin/bash

# s02_select_samples.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 29Aug2019

# Use:
# sbatch s02_select_samples.sh

# Select 715 ampliseq-nfe samples for ampliseq-NFE PCA plots

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_select_samples
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_select_samples.log
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
echo "Select 715 ampliseq-nfe samples for ampliseq-NFE PCA plots"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

ampliseq_nfe_1850_vcf_gz="${data_folder}/s21_calculate_ampliseq_NFE_PCs/s01_ampliseq_nfe_1850.vcf.gz"
samples_file="${data_folder}/s16_prepare_wecare_genotypes_for_PCA/s01_ampliseq_nfe_715_samples.txt"
ampliseq_nfe_1850_715_vcf_gz="${data_folder}/s21_calculate_ampliseq_NFE_PCs/s02_ampliseq_nfe_1850_715.vcf.gz"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "ampliseq_nfe_1850_vcf_gz: ${ampliseq_nfe_1850_vcf_gz}"
echo "samples_file: ${samples_file}"
echo "ampliseq_nfe_1850_715_vcf_gz: ${ampliseq_nfe_1850_715_vcf_gz}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo ""

echo "--- Progress ---"
echo ""

# --- Count variants in input vcf --- #
echo "Number of variants in the input vcf:" 
num_variants=$("${bcftools}" view -H "${ampliseq_nfe_1850_vcf_gz}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

# --- Count samples --- #
echo "Number of samples in the input vcf:" 
num_fields=$("${bcftools}" view -h "${ampliseq_nfe_1850_vcf_gz}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo ""

# --- Select samples --- #
echo "Selecting samples ..."

"${bcftools}" view \
  --samples-file "${samples_file}" \
  --output-type z \
  --output-file "${ampliseq_nfe_1850_715_vcf_gz}" \
  "${ampliseq_nfe_1850_vcf_gz}"

"${bcftools}" index -f "${ampliseq_nfe_1850_715_vcf_gz}"
echo ""

# --- Count variants --- #
echo "Number of variants in the output vcf:" 
num_variants=$("${bcftools}" view -H "${ampliseq_nfe_1850_715_vcf_gz}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

# --- Count samples --- #
echo "Number of samples in the output vcf:" 
num_fields=$("${bcftools}" view -h "${ampliseq_nfe_1850_715_vcf_gz}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo ""

# Progress report
echo "Done"
date
echo ""
