#!/bin/bash

path_der="derivatives/"

function get_FD {
    input="$1"
    sub_id=$(basename "$input" | cut -d'_' -f1)
    output="${input%_bold*}_FD.txt"
    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        tail -n +6 "$input" | cut -f 6 > "$output"

    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f get_FD

find "$path_der" -type f -name '*_task-rest_bold_confounds.tsv' > "$path_der/confounds_files.txt"

N=80
(
for ii in $(cat "$path_der/confounds_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   get_FD "$ii" & 
done
)
rm "$path_der/confounds_files.txt"