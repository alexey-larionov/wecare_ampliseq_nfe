#!/bin/bash

# s02_annotate_with_VEP.sh
# Started: Alexey Larionov, 18Mar2019
# Last updated: Alexey Larionov, 18Mar2019

# Use:
# sbatch s02_annotate_with_VEP.sh

# Annotate with VEP

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_annotate_with_VEP
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_annotate_with_VEP.log
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
echo "Annotate VCF with VEP"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

vcf_folder="${data_folder}/s14_annotated_vcf"

source_vcf="${vcf_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_MAsplit_kgen_exac.vcf"
target_vcf="${vcf_folder}/ampliseq_nfe.vcf"
vcf_md5="${vcf_folder}/ampliseq_nfe.md5"
vep_stats="${vcf_folder}/ampliseq_nfe.html"
vep_log="${vcf_folder}/ampliseq_nfe.log"

# VEP
ensembl_api_folder="${base_folder}/tools/ensembl/v87"
vep_script="${ensembl_api_folder}/ensembl-tools/scripts/variant_effect_predictor/variant_effect_predictor.pl"
vep_cache="${ensembl_api_folder}/grch37_vep_cache"
vep_fields="SYMBOL,Allele,Existing_variation,Consequence,IMPACT,CLIN_SIG,SIFT,PolyPhen,cDNA_position,CDS_position,Codons,Protein_position,Amino_acids,DISTANCE,STRAND,SYMBOL_SOURCE"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "source_vcf: ${source_vcf}"
echo "target_vcf: ${target_vcf}"
echo "vcf_md5: ${vcf_md5}"
echo "vep_stats: ${vep_stats}"
echo "vep_log: ${vep_log}"
echo ""
echo "--- VEP ---"
echo ""
echo "ensembl_api_folder: ${ensembl_api_folder}"
echo "vep_script: ${vep_script}"
echo "vep_cache: ${vep_cache}"
echo "vep_fields:"
echo "${vep_fields}"
echo ""

# Progress report
echo "Adding VEP annotations..."

# Configure PERL5LIB for VEP (modules as per ensembl API 87)
PERL5LIB="${ensembl_api_folder}/BioPerl-1.6.1"
PERL5LIB="${PERL5LIB}:${ensembl_api_folder}/ensembl/modules"
PERL5LIB="${PERL5LIB}:${ensembl_api_folder}/ensembl-compara/modules"
PERL5LIB="${PERL5LIB}:${ensembl_api_folder}/ensembl-funcgen/modules"
PERL5LIB="${PERL5LIB}:${ensembl_api_folder}/ensembl-io/modules"
PERL5LIB="${PERL5LIB}:${ensembl_api_folder}/ensembl-variation/modules"
export PERL5LIB

# Run script with vcf output
perl "${vep_script}" \
  -i "${source_vcf}" \
  -o "${target_vcf}" --vcf \
  --stats_file "${vep_stats}" \
  --cache --offline --dir_cache "${vep_cache}" \
  --pick --allele_number --check_existing --check_alleles \
  --symbol --gmaf --sift b --polyphen b \
  --fields "${vep_fields}" --vcf_info_field "ANN" \
  --force_overwrite --fork 4 --no_progress \
  &> "${vep_log}"

# Make md5 file for full vep-annotated vcf (we are in split_annotate_folder)
cd "${vcf_folder}"
md5sum $(basename "${target_vcf}") > "${vcf_md5}"
cd "${scripts_folder}"

# Progress report
echo "Done"
date
echo ""
