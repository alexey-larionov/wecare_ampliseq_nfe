#!/bin/bash

# s01_select_sites.sh
# Started: Alexey Larionov, 26Apr2019
# Last updated: Alexey Larionov, 26Apr2019

# Use:
# sbatch s01_select_sites.sh

# Select overlap between 1,850 sites and 1kg sites for joined PCA plot

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_select_sites
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_select_sites.log
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
echo "Select overlap between 1,850 sites and 1kg sites for joined PCA plot"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"

data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results/s15_prepare_1kg_genotypes_for_PCA"

source_1850_vcf="${data_folder}/s03_1850_sites.vcf"
source_1850_vcf_gz="${data_folder}/s03_1850_sites.vcf.gz"

source_1kg_vcf_gz="${data_folder}/ALL.wgs.phase3_shapeit2_mvncall_integrated_v5a.20130502.sites.fixed.filt.biallelic.vcf.gz"

target_vcf_gz="${data_folder}/sites_1kg_1850_intersect.vcf.gz"

# Resources
resources_folder="${base_folder}/resources"
source_1kg_vcf="${resources_folder}/phase3_1k_release20130502/wes_pipeline_v01.17/ALL.wgs.phase3_shapeit2_mvncall_integrated_v5a.20130502.sites.fixed.filt.biallelic.vcf"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "source_1850_vcf: ${source_1850_vcf}"
echo "source_1kg_vcf_gz: ${source_1kg_vcf_gz}"
echo "target_vcf_gz: ${target_vcf_gz}"
echo ""
echo "--- Resources ---"
echo ""
echo "source_1kg_vcf: ${source_1kg_vcf}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo ""

# --- Compress and index source files --- #

"${bcftools}" view \
  --output-file "${source_1850_vcf_gz}" \
  --output-type z \
  "${source_1850_vcf}"

"${bcftools}" index "${source_1850_vcf_gz}"

"${bcftools}" view \
  --output-file "${source_1kg_vcf_gz}" \
  --output-type z \
  "${source_1kg_vcf}"

"${bcftools}" index "${source_1kg_vcf_gz}"

# --- Make intersect --- #
echo "Looking for the intesect ..."

"${bcftools}" isec \
  --output "${target_vcf_gz}" \
  --output-type z \
  --nfiles=2 \
  --write 1 \
  "${source_1kg_vcf_gz}" \
  "${source_1850_vcf_gz}"

# --- Count variants --- #
echo ""
echo "Number of variants in the intesect:" 

"${bcftools}" view -H "${target_vcf_gz}" | wc -l

# Progress report
echo ""
echo "Done"
date
echo ""
