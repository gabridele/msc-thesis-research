#!/bin/bash

path_dl="derivatives/preproc_dl"

function avg_contrast {
    zstat5_1="$1"
    zstat7_1="${zstat5_1%25*}27.nii.gz"
    zstat5_3="${zstat5_1%25*}29.nii.gz"
    zstat7_3="${zstat5_1%25*}31.nii.gz"
    zstat7_5="${zstat5_1%25*}33.nii.gz"
    #template="derivatives/templates/Schaefer2018_400Parcels_Tian_Subcortex_S4_2mm_2009c_NLinAsymm.nii.gz"
    
    sub_id=$(basename "$(dirname "$(dirname "$(dirname "$zstat5_1")")")")

    fslmaths "$zstat5_1" -add "$zstat7_1" -add "$zstat5-3" -add "$zstat7_3" -add "$zstat7_5" -div 5 "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat.nii.gz"
    #3dresample -master "$template" -prefix "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat_resampled.nii.gz" -input "$path_dl/${sub_id}/scap.feat/${sub_id}_mean_zstat.nii.gz"
}

export -f avg_contrast

find "$path_dl" -type f -name '*zstat25.nii.gz' > "$path_dl/input_files.txt"

N=100
(
for ii in $(cat "$path_dl/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   avg_contrast "$ii" &
done
)

rm "$path_dl/input_files.txt"