#!/bin/bash
path_der="derivatives/"


function remove_TR {
    num_remove="4"
    num_keep="148"
    input="$1"
    sub_id=$(basename "$input" | cut -d'_' -f1)
    censor_input="${input%_preproc*}_censor.txt"
    censor_output="${censor_input%.txt}_${num_remove}RTremoved.txt"
    output_preproc="${input%.nii.gz}_${num_remove}RTremoved.nii.gz"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        echo -e "Processing input: $sub_id \n..."

        fslroi $input $output_preproc $num_remove $num_keep

        echo "Modified nifti file saved as: $output_preproc"

        tail -n +5 $censor_input > $censor_output
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f remove_TR

find "$path_der" -type f -name '*_task-rest_bold_space-MNI*_preproc_resampled.nii.gz' > "$path_der/input_files.txt"

N=80
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   remove_TR "$ii" "$mask" & 
done
)

rm "$path_der/input_files.txt"