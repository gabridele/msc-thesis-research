#!/bin/bash

# This script computes the framewise displacement (FD) that will be used for censoring. 
# -----------------------------------------------------------
# Script written by Ludovico Coletta
# Nilab, FBK (2022)
# -----------------------------------------------------------

function compute_fd {

    ts=$1
    subject=$(basename $ts _slt.nii.gz)
    sub_folder=$(dirname $ts)
    
    fsl_motion_outliers \
      -i $ts \
      --fd \
      -s ${sub_folder}/${subject}_fd.txt \
      -o ${sub_folder}/${subject}_confound \
      -v \
      &> ${sub_folder}/log_${subject}_fd_computation.txt

}
export -f compute_fd

# main code starts here

study_folder=IntraOpMap_RestingState #EDIT HERE
numjobs=16 #EDIT HERE

echo $PWD/${study_folder}/derivatives/CustomPrepro/Pre/sub-*/func/*_slt.nii.gz | tr " " "\n" > subject_list.txt #EDIT HERE

parallel \
    -j $numjobs \
    compute_fd {} \
    < subject_list.txt


