#!/bin/bash
path_der="derivatives/"


function remove_TR {

    t_min="4"
    t_size="148"
    input="$1"
    sub_id=$(basename "$input" | cut -d'_' -f1)
    output_preproc="${input%.nii.gz}_${t_min}RTremoved.nii.gz"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        echo -e "Processing input: $sub_id..."

        fslroi $input $output_preproc $t_min $t_size
        
        if [ -f "$output_preproc" ]; then
            echo "Function was successful and file saved as: $(basename "$output_preproc")"
        else
            echo "ERROR: output not issued"
        fi

    else
        echo -e "\nSubject $sub_id is excluded. Skipping..."
    fi
}

export -f remove_TR

find "$path_der" -type f -name '*_task-rest_bold_space-MNI*_preproc_resampled.nii.gz' > "$path_der/input_files.txt"

N=80
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   remove_TR "$ii" & 
done
)

rm "$path_der/input_files.txt"