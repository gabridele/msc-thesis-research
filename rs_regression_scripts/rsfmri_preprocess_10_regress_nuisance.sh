#!/bin/bash

# This script performs nuisance regression and bandpass filtering as implemented by AFNI's 3dTproject (i.e simultaeous regression and bp).
# Volumes flagged for high motion are interpolated before the regression
# time series are normalized to have sum of squares = 1
# -----------------------------------------------------------
path_der="derivatives/"

function regress_nuisance_subject {

    ts="$1"
    sub_id="$(basename "$ts" | grep -oP 'sub-\d+')"
    sub_folder="$(dirname $ts)"
    regr_file="${ts%_bold*}_bold_confounds_regressors.tsv"
    censor="${ts%_bold*}_censor.txt"
    mask="${ts%_preproc*}_brainmask_resampled.nii.gz"
    output="${ts%sub-*}${sub_id}_regressed_bp.nii.gz"
    

    
    # EDIT passband (range of frequences to keep) and TR if needed
    3dTproject \
         -input $ts \
         -prefix $output \
         -censor $censor \
         -cenmode NTRP \
         -ort $regr_file \
         -polort 2 \
         -passband 0.01 0.1 \
         -TR 2 \
         -mask $mask \
         -norm \
         -verb \
         &> ${sub_folder}/log_${sub_id}_nuisance_regression.txt

}

export -f regress_nuisance_subject


find "$path_der" -type f -name '*_task-rest_bold_space-MNI*_preproc_resampled_4RTremoved.nii.gz' > "$path_der/ts_input.txt"

N=2
(
for ii in $(cat "$path_der/ts_input.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   regress_nuisance_subject "$ii" &
done
)
rm "$path_der/ts_input.txt"
