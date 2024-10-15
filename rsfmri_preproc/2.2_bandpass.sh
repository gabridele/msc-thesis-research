# !/bin/bash
# script to perform bandpass filtering
# edit bandpass filtering range to your likings
path_der="derivatives/"

function bandpass {
    input="$1"
    sub_id=$(basename "$input" | cut -d'_' -f1)
    mask="${input%_regressed*}_task-rest_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz" 
    output="${input%_regressed*}_regressed_bandpass.nii.gz"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

     echo -e "Processing input: $input... \n"
     echo -e "With mask: $mask... \n"
 
     3dBandpass -mask $mask -prefix $output 0.01 0.1 $input
    else
     echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi

}

export -f bandpass

find "$path_der" -type f -name '*regressed.nii.gz' > "$path_der/input_files.txt"

N=2
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   bandpass "$ii" & 
done
)
rm "$path_der/input_files.txt"