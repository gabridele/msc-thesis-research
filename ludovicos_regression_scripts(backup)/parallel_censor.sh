#!/bin/bash

path_der="derivatives/"

function parallel_censor {
    sub="$1"
    echo -e "############# Processing $sub ######### \n"
    python ../code/rsfmri/rsfmri_preprocess_08_create_afni_censor_file.py
}

export -f parallel_censor

N=20
(
for sub in $(cat "subject_id_with_exclusions.txt"); do 
    ((i=i%N)); ((i++==0)) && wait
    parallel_censor "$sub" &
done
wait
)