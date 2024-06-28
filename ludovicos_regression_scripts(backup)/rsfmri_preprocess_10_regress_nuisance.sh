#!/bin/bash

# This script performs nuisance regression and bandpass filtering as implemented by AFI's 3dTproject (i.e simultaeous regression and bp).
# Volumes flagged for high motion are interpolated before the regression
# time series are normalized to have sum of squares = 1
# -----------------------------------------------------------
# Script written by Ludovico Coletta, NILAB, FBK (2022).
# -----------------------------------------------------------

function regress_nuisance_subject {

    ts="$1"
    sub_id="$(basename "$ts" | grep -oP 'sub-\d+')"
    sub_folder="$(dirname $ts)"
    mask="${ts%reproc_resampled.nii.gz}_brainmask.nii.gz"
    output="${ts%sub-*}${sub_id}__regressed_bp.nii.gz"
    #metric_output="${ts%_preproc.nii.gz}_fd.txt"
    
    subject=$(basename $ts _masked.nii.gz)
    sub_folder=$(dirname $ts)
    
    # EDIT passband (range of frequences to keep) and TR if needed
    3dTproject \
         -input $ts \
         -prefix $output \
         -censor ${sub_folder}/${sub_id}*_censor.txt \
         -cenmode NTRP \
         -ort ${sub_folder}/${sub_id}_eight_regressors_plus_derivatives.txt \
         -polort 2 \
         -passband 0.01 0.1 \
         -TR 2 \
         -mask $mask \
         -norm \
         -verb \
         &> ${sub_folder}/log_${sub_id}_nuisance_regression.txt
                
    }
export -f regress_nuisance_subject
#sub-10171_task-rest_bold_space-MNI152NLin2009cAsym_preproc_resampled.nii.gz
# main code starts here
numjobs=32

echo $PWD/derivatives/sub-*/func/*task-rest_*MNI*preproc_resampled.nii.gz | tr " " "\n" > input_list.txt #EDIT HERE

parallel \
    -j $numjobs \
    regress_nuisance_subject {} \
    < subject_list.txt


