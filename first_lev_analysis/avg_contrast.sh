#!/bin/bash

path_dl="derivatives/preproc_dl"

function avg_contrast {
    cope5_1="$1"
    cope7_1="${cope5_1%25*}27.nii.gz"
    cope5_3="${cope5_1%25*}29.nii.gz"
    cope7_3="${cope5_1%25*}31.nii.gz"
    #template="derivatives/templates/Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz"
    
    sub_id=$(basename "$(dirname "$(dirname "$(dirname "$cope5_1")")")")

    fslmaths "$cope5_1" -add "$cope7_1" -add "$cope5_3" -add "$cope7_3" -div 4 "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_cope.nii.gz"
    #3dresample -master "$template" -prefix "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat_resampled.nii.gz" -input "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat.nii.gz"
}

export -f avg_contrast

find "$path_dl" -type f -name 'sub-*cope25.nii.gz' > "$path_dl/input_files.txt"

N=120
(
for ii in $(cat "$path_dl/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   avg_contrast "$ii" &
done
)

rm "$path_dl/input_files.txt"