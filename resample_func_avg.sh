#!/bin/bash

path_dl="derivatives/preproc_dl"

function resample_func {
    input="$1"
    template="derivatives/templates/Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz"
    sub_id=$(basename "$input" | cut -d'_' -f1)

    3dresample -master "$template" -prefix "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat_resampled.nii.gz" -input "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat.nii.gz"
}

export -f resample_func

find "$path_dl" -type f -name '*mean_zstat.nii.gz' > "$path_dl/input_files.txt"

N=2
(
for ii in $(cat "$path_dl/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   resample_func "$ii" &
done
)

rm "$path_dl/input_files.txt"