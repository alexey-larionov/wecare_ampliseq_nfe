#!/bin/bash

# s01_select_variants.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 10Jul2019

# Use:
# sbatch s01_select_variants.sh

# Select 1,140 variants from ampliseq-nfe VCF for PCA plots

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_select_variants
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_select_variants.log
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
echo "Select 1,140 variants for PCA plots"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

selected_1140_sites_vcf_gz="${data_folder}/s15_prepare_1kg_genotypes_for_PCA/selected_1140_1kg_genotypes.vcf.gz"

source_ampliseq_nfe_vcf="${data_folder}/s14_annotated_vcf/ampliseq_nfe.vcf"
ampliseq_nfe_vcf_gz="${data_folder}/s16_prepare_wecare_genotypes_for_PCA/ampliseq_nfe.vcf.gz"

ampliseq_nfe_1140_vcf_gz="${data_folder}/s16_prepare_wecare_genotypes_for_PCA/ampliseq_nfe_1140.vcf.gz"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "selected_1140_sites_vcf_gz: ${selected_1140_sites_vcf_gz}"
echo "source_ampliseq_nfe_vcf: ${source_ampliseq_nfe_vcf}"
echo "ampliseq_nfe_1140_vcf_gz: ${ampliseq_nfe_1140_vcf_gz}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo ""

# --- Compress and index source file --- #

"${bcftools}" view \
  --output-file "${ampliseq_nfe_vcf_gz}" \
  --output-type z \
  "${source_ampliseq_nfe_vcf}"

"${bcftools}" index -f "${ampliseq_nfe_vcf_gz}"

# --- Select variants --- #
echo "Selecting variants ..."

"${bcftools}" isec \
  --output "${ampliseq_nfe_1140_vcf_gz}" \
  --output-type z \
  --nfiles=2 \
  --write 1 \
  "${ampliseq_nfe_vcf_gz}" \
  "${selected_1140_sites_vcf_gz}"

"${bcftools}" index -f "${ampliseq_nfe_1140_vcf_gz}"

# --- Count variants --- #
echo ""
echo "Number of variants in the output:" 
num_variants=$("${bcftools}" view -H "${ampliseq_nfe_1140_vcf_gz}" | wc -l)
printf "%'d\n" "${num_variants}"

# --- Count samples --- #
#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT 100_S8_L007 101_S528_L008 ...
echo ""
echo "Number of samples in the output:" 
num_fields=$("${bcftools}" view -h "${ampliseq_nfe_1140_vcf_gz}" | tail -n 1 | wc -w)
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"

# Progress report
echo ""
echo "Done"
date
echo ""
