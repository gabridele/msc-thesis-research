#!/bin/bash

# This script performs nuisance regression and bandpass filtering as implemented by AFI's 3dTproject (i.e simultaeous regression and bp).
# Volumes flagged for high motion are interpolated before the regression
# time series are normalized to have sum of squares = 1
# -----------------------------------------------------------
# Script written by Ludovico Coletta, NILAB, FBK (2022).
# -----------------------------------------------------------

function regress_nuisance_subject {

    ts=$1
    subject=$(basename $ts _masked.nii.gz)
    sub_folder=$(dirname $ts)
    
    # EDIT passband (range of frequences to keep) and TR if needed
    3dTproject \
         -input $ts \
         -prefix ${sub_folder}/${subject}_regressed_bp.nii.gz \
         -censor ${sub_folder}/${subject}_censor.txt \
         -cenmode NTRP \
         -ort ${sub_folder}/${subject}_eight_regressors_plus_derivatives.txt \
         -polort 2 \
         -passband 0.01 0.1 \
         -TR 2.6 \
         -mask ${sub_folder}/${subject}_brain_mask.nii.gz \
         -norm \
         -verb \
         &> ${sub_folder}/log_${subject}_nuisance_regression.txt
                
    }
export -f regress_nuisance_subject

# main code starts here
numjobs=32

study_folder=IntraOpMap_RestingState #EDIT HERE

echo $PWD/${study_folder}/derivatives/CustomPrepro/Pre/sub-*/func/*_masked.nii.gz | tr " " "\n" > subject_list.txt #EDIT HERE

parallel \
    -j $numjobs \
    regress_nuisance_subject {} \
    < subject_list.txt


