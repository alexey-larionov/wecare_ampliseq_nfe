#!/bin/bash

# s01_annotate_with_KGEN_and_EXAC.sh
# Started: Alexey Larionov, 18Mar2019
# Last updated: Alexey Larionov, 18Mar2019

# Use:
# sbatch s01_annotate_with_KGEN_and_EXAC.sh

# Annotate with KGEN and EXAC

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_annotate_with_KGEN_and_EXAC
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_annotate_with_KGEN_and_EXAC.log
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
echo "Annotate with KGEN and EXAC"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

source_folder="${data_folder}/s13_split_MA"
target_folder="${data_folder}/s14_annotated_vcf"
tmp_folder="${target_folder}/tmp"

rm -fr "${target_folder}" # remove target folder, if existed
#rm -fr "${tmp_folder}" # remove tmp folder, if existed
mkdir -p "${tmp_folder}"

source_vcf="${source_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_MAsplit.vcf"
target_vcf="${target_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_MAsplit_kgen_exac.vcf"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.7-0/GenomeAnalysisTK.jar"

# Resources 
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
dbsnp_138="${resources_folder}/gatk_bundle/b37/decompressed/dbsnp_138.b37.vcf"

kgen_folder="${resources_folder}/phase3_1k_release20130502/wes_pipeline_v01.17"
kgen_sites_vcf="ALL.wgs.phase3_shapeit2_mvncall_integrated_v5a.20130502.sites.fixed.filt.biallelic.leftaligned.vcf"
kgen_sites_vcf="${kgen_folder}/${kgen_sites_vcf}"

exac_folder="${resources_folder}/exac/wes_pipeline_v01.17"
exac_sites_vcf="ExAC_nonTCGA.r0.3.1.sites.vep.filt.biallelic.leftaligned.vcf.gz"
exac_sites_vcf="${exac_folder}/${exac_sites_vcf}"

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
echo "dbsnp_138: ${dbsnp_138}"
echo "kgen_sites_vcf: ${kgen_sites_vcf}"
echo "exac_sites_vcf: ${exac_sites_vcf}"
echo ""

# --- Add alt allele data from 1k ph3 (b37) --- #

# Notes: 
# --resourceAlleleConcordance may not be supported by gatk below v 3.6
# 1k phase 3 vcf includes left-aligned biallelic variants passed filters

# Progress report
echo "Adding data from kgen (ph3, b37)..."

# File names
kgen_vcf="${tmp_folder}/kgen.vcf"
kgen_log="${tmp_folder}/kgen.log"

# Add annotations
"${java}" -Xmx24g -jar "${gatk}" \
  -T VariantAnnotator \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${source_vcf}" \
  -o "${kgen_vcf}" \
  --resource:kgen "${kgen_sites_vcf}" \
  --expression kgen.AC \
  --expression kgen.AN \
  --expression kgen.AF \
  --expression kgen.AFR_AF \
  --expression kgen.AMR_AF \
  --expression kgen.EAS_AF \
  --expression kgen.EUR_AF \
  --expression kgen.SAS_AF \
  --resourceAlleleConcordance \
  --downsampling_type NONE \
  -nt 4 &>  "${kgen_log}"

# --- Add alt allele data from exac (non-tcga, b37) and IDs from dbSNP_138 --- #

# Notes: 
# --resourceAlleleConcordance may not be supported by gatk below v 3.6
# exac non-tcga vcf includes left-aligned biallelic variants passed filters

# Progress report
echo "Adding data from exac (non-tcga, b37) and IDs from dbSNP_138..."

# File names
exac_log="${tmp_folder}/exac.log"

# Add annotations
"${java}" -Xmx24g -jar "${gatk}" \
  -T VariantAnnotator \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${kgen_vcf}" \
  -o "${target_vcf}" \
  --resource:exac_non_TCGA "${exac_sites_vcf}" \
  --expression exac_non_TCGA.AF \
  --expression exac_non_TCGA.AC \
  --expression exac_non_TCGA.AN \
  --expression exac_non_TCGA.AC_FEMALE \
  --expression exac_non_TCGA.AN_FEMALE \
  --expression exac_non_TCGA.AC_MALE \
  --expression exac_non_TCGA.AN_MALE \
  --expression exac_non_TCGA.AC_Adj \
  --expression exac_non_TCGA.AN_Adj \
  --expression exac_non_TCGA.AC_Hom \
  --expression exac_non_TCGA.AC_Het \
  --expression exac_non_TCGA.AC_Hemi \
  --expression exac_non_TCGA.AC_AFR \
  --expression exac_non_TCGA.AN_AFR \
  --expression exac_non_TCGA.Hom_AFR \
  --expression exac_non_TCGA.Het_AFR \
  --expression exac_non_TCGA.Hemi_AFR \
  --expression exac_non_TCGA.AC_AMR \
  --expression exac_non_TCGA.AN_AMR \
  --expression exac_non_TCGA.Hom_AMR \
  --expression exac_non_TCGA.Het_AMR \
  --expression exac_non_TCGA.Hemi_AMR \
  --expression exac_non_TCGA.AC_EAS \
  --expression exac_non_TCGA.AN_EAS \
  --expression exac_non_TCGA.Hom_EAS \
  --expression exac_non_TCGA.Het_EAS \
  --expression exac_non_TCGA.Hemi_EAS \
  --expression exac_non_TCGA.AC_FIN \
  --expression exac_non_TCGA.AN_FIN \
  --expression exac_non_TCGA.Hom_FIN \
  --expression exac_non_TCGA.Het_FIN \
  --expression exac_non_TCGA.Hemi_FIN \
  --expression exac_non_TCGA.AC_NFE \
  --expression exac_non_TCGA.AN_NFE \
  --expression exac_non_TCGA.Hom_NFE \
  --expression exac_non_TCGA.Het_NFE \
  --expression exac_non_TCGA.Hemi_NFE \
  --expression exac_non_TCGA.AC_SAS \
  --expression exac_non_TCGA.AN_SAS \
  --expression exac_non_TCGA.Hom_SAS \
  --expression exac_non_TCGA.Het_SAS \
  --expression exac_non_TCGA.Hemi_SAS \
  --expression exac_non_TCGA.AC_OTH \
  --expression exac_non_TCGA.AN_OTH \
  --expression exac_non_TCGA.Hom_OTH \
  --expression exac_non_TCGA.Het_OTH \
  --expression exac_non_TCGA.Hemi_OTH \
  --dbsnp "${dbsnp_138}" \
  --resourceAlleleConcordance \
  --downsampling_type NONE \
  -nt 4 &>  "${exac_log}"

# Progress report
echo "Done"
date
echo ""
