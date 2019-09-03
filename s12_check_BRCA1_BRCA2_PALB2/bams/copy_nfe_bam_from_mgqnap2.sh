#!/bin/bash

# copy_from_mgqnap2.sh
# Copy NFE bam from mgqnap2
# Alexey Larionov, 26Apr2019

rsync -avhe "ssh -x" admin@mgqnap2.medschl.cam.ac.uk:/share/1kgenomes/kgenomes/batch1/processed/f01_bams/NA20821_idr_bqr* /Users/alexey/Documents/wecare/ampliseq/v04_ampliseq_nfe/s12_check_BRCA1_BRCA2_PALB2/bam/ 
