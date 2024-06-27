#!/bin/bash


path_der="derivatives/"

function compute_fd {

    ts=$1
    sub_id=$(basename "$ts" | grep -oP 'sub-\d+')
    sub_folder=$(dirname $ts)
    metric_output="${ts%_preproc.nii.gz}_fd.txt"
    output="${ts%_preproc.nii.gz}_confound"
    
    fsl_motion_outliers \
      -i $ts \
      --fd \
      -s $metric_output \
      -o $output \
      -v \
      &> ${sub_folder}/log_${sub_id}_fd_computation.txt

}

export -f compute_fd

find "$path_der" -type f -name '*_task-rest_bold_space-MNI*_preproc.nii.gz' > "$path_der/rsfmri_files.txt"

N=40
(
for ii in $(cat "$path_der/rsfmri_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   compute_fd "$ii" &
done
)
rm "$path_der/rsfmri_files.txt"

