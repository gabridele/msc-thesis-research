#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"

#1
echo "###################################################################" 
echo ".....................Smoothing EPI....................."

function smooth {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 mask="${input%_preproc.nii.gz}_brainmask.nii.gz" 
 output="${input%_preproc.nii.gz}_preproc_smoothed.nii.gz"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
        
  echo -e "\n Processing input: $input ..."
  echo -e "\n With mask: $mask..."

  if [ -f "$output" ]; then
    echo -e "\n Output file $output already exists, skipping..."
  else
    3dBlurInMask -input "$input" -mask "$mask" -FWHM 4 -prefix "$output"
    echo -e "\n Smoothed $input and saved as $output"
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f smooth

find "$path_der" -type f -name '*task-scap_bold_space-MNI152NLin2009cAsym_preproc.nii.gz' > "$path_der/input_files.txt"

N=20
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   smooth "$ii" "$mask" & 
done
)
rm "$path_der/input_files.txt"