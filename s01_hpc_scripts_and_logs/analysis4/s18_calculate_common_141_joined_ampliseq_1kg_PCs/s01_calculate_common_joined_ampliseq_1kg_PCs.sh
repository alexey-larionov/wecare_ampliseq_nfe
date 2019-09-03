#!/bin/bash

# s01_calculate_common_joined_ampliseq_1kg_PCs.sh
# Started: Alexey Larionov, 13Jul2019
# Last updated: Alexey Larionov, 14Jul2019

# Use:
# sbatch s01_calculate_common_joined_ampliseq_1kg_PCs.sh

# Calculate PCs for joined ampliseq-1kg dataset (common variants only)

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_calculate_common_joined_ampliseq_1kg_PCs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_calculate_common_joined_ampliseq_1kg_PCs.log
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
echo "Calculate PCs for joined ampliseq-1kg dataset (common variants only)"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

source_vcf_gz="${data_folder}/s17_merge_1kg_and_ampliseq_for_PCA/ampliseq_nfe_1kg_1111_3219.vcf.gz"

data_folder="${data_folder}/s18_calculate_common_141_joined_ampliseq_1kg_PCs"
mkdir -p "${data_folder}"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"
plink="${tools_folder}/plink/plink-1.9/plink"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo "source_vcf_gz: ${source_vcf_gz}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo "plink: ${plink}"
echo ""

# --- Count variants and samples in the sourse VCF --- #

echo "Number of variants in the input VCF:" 
num_variants=$("${bcftools}" view -H "${source_vcf_gz}" | wc -l)
printf "%'d\n" "${num_variants}"
echo ""

echo "Number of samples in the input VCF:" 
num_fields=$("${bcftools}" view -h "${source_vcf_gz}" | tail -n 1 | wc -w)
#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT ...
num_samples=$(( ${num_fields} - 9 ))
printf "%'d\n" "${num_samples}"
echo "" 

# --- Import VCF to PLINK --- #

plink_dataset_folder="${data_folder}/s01_vcf_to_plink"
rm -fr "${plink_dataset_folder}"
mkdir -p "${plink_dataset_folder}"
initial_plink_dataset="${plink_dataset_folder}/ampliseq_1kg_1111_3219"

# --vcf-half-call describes what to do with genotypes like 0/.
# --allow-no-sex suppresses warning about missed sex
# --double-id puts sample name to both Family-ID and Participant-ID
# --silent suppresses very verbous ouput to the "out" file (log file is still avaialble in the data folder)

"${plink}" \
  --vcf "${source_vcf_gz}" \
  --vcf-half-call "missing" \
  --double-id \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${initial_plink_dataset}"

echo "Imported VCF to PLINK (bed-bim-fam file-set)"
echo ""

# --- Exclude low frequency variants --- #
# http://www.cog-genomics.org/plink/1.9/filter#maf
# --maf filters out all variants with minor allele frequency below the provided threshold (default 0.01)
# --max-maf imposes an upper MAF bound. 
# Similarly, --mac and --max-mac impose lower and upper minor allele count bounds, respectively.

output_data_folder="${data_folder}/s02_exclude_low_frequency_variants"
rm -fr "${output_data_folder}"
mkdir -p "${output_data_folder}"
common_variants="${output_data_folder}/ampliseq_1kg_211_3219_common"

"${plink}" \
  --bfile "${initial_plink_dataset}" \
  --maf 0.05 \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${common_variants}"

echo "Excluded low frequency variants"
echo ""

# --- Exclude variants in LD --- #

# Output folder
output_data_folder="${data_folder}/s03_exclude_variants_in_LD"
rm -fr "${output_data_folder}"
mkdir -p "${output_data_folder}"

# Output files
pairphase_LD="${output_data_folder}/pairphase_LD"
LD_pruned_datset="${output_data_folder}/ampliseq_1kg_141_3219_not_in_LD"

# Determine variants in LD
# Command indep-pairphse makes two files:
# - list of variants in LD (file with extension .prune.out)
# - list of cariants not in LD (extension .prune.in)

# --indep-pairphase is just like --indep-pairwise, 
# except that its r2 values are based on maximum likelihood phasing
# http://www.cog-genomics.org/plink/1.9/ld#indep

# The specific parameters 50 5 0.5 are taken from an example 
# discussed in PLINK 1.07 manual for LD prunning
# http://zzz.bwh.harvard.edu/plink/summary.shtml#prune
# It does the following:
# a) considers a window of 50 SNPs
# b) calculates LD between each pair of SNPs in the window 
# c) removes one of a pair of SNPs if the LD is greater than 0.5
# d) shifts the window 5 SNPs forward and repeat the procedure

"${plink}" \
  --bfile "${common_variants}" \
  --indep-pairphase 50 5 0.5 \
  --allow-no-sex \
  --silent \
  --out "${pairphase_LD}"

# Make a new bed-bim-fam file-set w/o the variants in LD
# using the list of variants in LD created in the previous step

"${plink}" \
  --bfile "${common_variants}" \
  --exclude "${pairphase_LD}.prune.out" \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${LD_pruned_datset}"

echo "Excluded variants in LD"
echo ""

# --- Calculate 100 top PCs --- #
# "header" and "tabs" are options to format output

pca_results_folder="${data_folder}/s04_pca"
rm -fr "${pca_results_folder}"
mkdir -p "${pca_results_folder}"
pca_results="${pca_results_folder}/ampliseq_1kg_141_3219_100PCs"

"${plink}" \
  --bfile "${LD_pruned_datset}" \
  --pca 100 header tabs \
  --allow-no-sex \
  --silent \
  --out "${pca_results}"

echo "Calculated 100 top PCs using 141 common variants not in LD"
echo ""

# Progress report
echo "Done all tasks"
date
echo ""
