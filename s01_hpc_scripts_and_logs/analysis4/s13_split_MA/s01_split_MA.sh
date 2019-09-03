#!/bin/bash

# s01_split_MA.sh
# Started: Alexey Larionov, 18Mar2019
# Last updated: Alexey Larionov, 18Mar2019

# Use:
# sbatch s01_split_MA.sh

# Split MA, clean split VCF add Var IDs

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_split_MA
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_split_MA.log
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
echo "Split MA, clean split VCF add VarIDs"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

source_folder="${data_folder}/s12_hard_filters"
target_folder="${data_folder}/s13_split_MA"
tmp_folder="${target_folder}/tmp"

rm -fr "${target_folder}" # remove target folder, if existed
mkdir -p "${tmp_folder}"

source_vcf="${source_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf.vcf"
target_vcf="${target_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_MAsplit.vcf"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.7-0/GenomeAnalysisTK.jar"

# Resources 
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "source_vcf: ${vqsr_vcf}"
echo "target_vcf: ${target_vcf}"
echo ""
echo "--- Tools ---"
echo ""
echo "gatk: ${gatk}"
echo "java: ${java}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "targets_interval_list: ${targets_interval_list}"
echo ""
echo "--- Settings ---"
echo ""
echo "MIN_DP: ${MIN_DP}"
echo ""

# --- Split multiallelic variants --- #
# Splits multiallelic variants to separate lanes, left-align and trim indels

# File names
split_vcf="${tmp_folder}/split.vcf"
split_log="${tmp_folder}/split.log"

# Progress report
echo "Splitting multiallelic variants"
echo "Num of variants before splitting:"
grep -v "^#" "${source_vcf}" | wc -l
echo ""

# Split ma sites
"${java}" -Xmx24g -jar "${gatk}" \
  -T LeftAlignAndTrimVariants \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${source_vcf}" \
  -o "${split_vcf}" \
  --downsampling_type NONE \
  --splitMultiallelics &> "${split_log}"

# Progress report
echo "Num of variants after splitting: "
grep -v "^#" "${split_vcf}" | wc -l
echo ""

# --- Clean vcf after splitting multiallelic variants --- #

# Progress report
echo "Cleaning vcf after splitting multiallelic variants"
echo ""

# Set file names
split_cln_vcf="${tmp_folder}/split_cln.vcf"
sma_head="${tmp_folder}/sma_vcf_header.txt"
sma_tab="${tmp_folder}/sma_vcf_tab.txt"
sma_tab_cln1="${tmp_folder}/sma_vcf_tab_cln1.txt"
sma_tab_cln2="${tmp_folder}/sma_vcf_tab_cln2.txt"

# Get vcf header and table
grep "^#" "${split_vcf}" > "${sma_head}"
grep -v "^#" "${split_vcf}" > "${sma_tab}"

# Remove variants with * in ALT 
# * in ALT refers to an upstream INDEL overlapping with current variant
# It should already be annotated upstream, and it is not suitable for VEP
awk '$5 != "*"' "${sma_tab}" > "${sma_tab_cln1}"
echo "Num of variants after removing * in ALT: "
cat "${sma_tab_cln1}" | wc -l
echo ""

# Keep only variants with known AN and AC 
# (unknown AC/AN are not suitable for downstream analyses)
awk '($8 ~ "AN=") && ($8 ~ "AC=")' "${sma_tab_cln1}" > "${sma_tab_cln2}"
echo "Num of variants after removing ones w/o AN/AC in INFO: "
cat "${sma_tab_cln2}" | wc -l 
echo ""

# Merge header and filtered body of the vcf file
cat "${sma_head}" "${sma_tab_cln2}" > "${split_cln_vcf}"

# --- Add variants IDs to INFO field --- #
# To make easier tracing split variants during the later steps

# Progress report
echo "Adding split variants IDs to INFO field ..."

# Compile names for temporary files
vid_tmp1=$(mktemp --tmpdir="${tmp_folder}" "vid_tmp1".XXXXXX)
vid_tmp2=$(mktemp --tmpdir="${tmp_folder}" "vid_tmp2".XXXXXX)
vid_tmp3=$(mktemp --tmpdir="${tmp_folder}" "vid_tmp3".XXXXXX)
vid_tmp4=$(mktemp --tmpdir="${tmp_folder}" "vid_tmp4".XXXXXX)

# Prepare data witout header
grep -v "^#" "${split_cln_vcf}" > "${vid_tmp1}"
awk '{printf("SplitVarID=Var%09d\t%s\n", NR, $0)}' "${vid_tmp1}" > "${vid_tmp2}"
awk 'BEGIN {OFS="\t"} ; { $9 = $9";"$1 ; print}' "${vid_tmp2}" > "${vid_tmp3}"
cut -f2- "${vid_tmp3}" > "${vid_tmp4}"

# Prepare header
grep "^##" "${split_cln_vcf}" > "${target_vcf}"
echo '##INFO=<ID=SplitVarID,Number=1,Type=String,Description="Split Variant ID">' >> "${target_vcf}"
grep "^#CHROM" "${split_cln_vcf}" >> "${target_vcf}"

# Append data to header in the output file
cat "${vid_tmp4}" >> "${target_vcf}"

# --- Add alt allele data from 1k ph3 (b37) --- #

# Progress report
echo "Done"
date
echo ""
