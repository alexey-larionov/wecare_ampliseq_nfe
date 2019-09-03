#!/bin/bash

# s02_select_genotypes.sh
# Started: Alexey Larionov, 27Apr2019
# Last updated: Alexey Larionov, 27Apr2019

# Use:
# sbatch s02_select_genotypes.sh

# Select 1,145 genotypes from 1kg for joined PCA plot

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_select_genotypes
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=09:00:00
#SBATCH --output=s02_select_genotypes.log
#SBATCH --ntasks=4
##SBATCH --qos=INTR

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
echo "Select 1,145 genotypes from 1kg for joined PCA plot"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"

data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results/s15_prepare_1kg_genotypes_for_PCA"

source_1145_vcf="${data_folder}/sites_1kg_1850_intersect.vcf.gz"

target_folder="${data_folder}/by_chromosome"

rm -fr "${target_folder}"
mkdir "${target_folder}"

# Resources
resources_folder="${base_folder}/resources"
source_1kg_folder="${resources_folder}/phase3_1k_release20130502/vcfs_fixed"
compressed_1kg_folder="${resources_folder}/phase3_1k_release20130502/vcfs_fixed_compressed"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "source_1145_vcf: ${source_1145_vcf}"
echo "compressed_1kg_folder: ${compressed_1kg_folder}"
echo "target_folder: ${target_folder}"
echo ""
echo "--- Resources ---"
echo ""
echo "source_1kg_folder: ${source_1kg_folder}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo ""

# Prepare accessory data
chromosomes="chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22"
prefix="${source_1kg_folder}/"

# --- Compress and index source files --- #

#"${bcftools}" index "${source_1145_vcf}" # Should be done once

echo "Compressing and indexing source files ..."

for chromosome in ${chromosomes}
do

  "${bcftools}" view \
    --output-file "${compressed_1kg_folder}/${chromosome}_fixed.vcf.gz" \
    --output-type z \
    "${source_1kg_folder}/${chromosome}_fixed.vcf"

  "${bcftools}" index "${compressed_1kg_folder}/${chromosome}_fixed.vcf.gz"
  
  echo "${chromosome}"
  
done

date
echo ""

# --- Make intersects --- #
echo "Looking for the intesects ..."

for chromosome in ${chromosomes}
do

  # Intersect
  "${bcftools}" isec \
    --output "${target_folder}/${chromosome}.vcf.gz" \
    --output-type z \
    --nfiles=2 \
    --write 1 \
    "${compressed_1kg_folder}/${chromosome}_fixed.vcf.gz" \
    "${source_1145_vcf}"
  
  # Progress report
  num_var=$("${bcftools}" view -H "${target_folder}/${chromosome}.vcf.gz" | wc -l)
  echo -e "${chromosome}\t${num_var}" 

done

# Progress report
echo ""
echo "Done"
date
echo ""
