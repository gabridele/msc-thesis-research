#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"


echo "###################################################################" 
echo ".................Performing fitting..................."

function fitting {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 matrix="${input%_bold*}.xmat.1D"
 mask="${input%_preproc_*}_brainmask_resampled.nii.gz"
 fit_output="${input%_bold*}_fit.nii.gz"
 res_output="${input%_bold*}_REML_whitened_residuals.nii.gz"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

  echo -e "Processing input: $input \n..."
  echo -e "With mask: $mask... \n"
  if [ -f "$output" ]; then
    echo "Output file $output already exists, skipping..."
  else
    3dREMLfit \
    -input "$input" \
    -matrix "$matrix" \
    -mask "$mask" \
    -Rbuck "$fit_output" \
    -fout \
    -tout \
    -Rwherr "$res_output" \
    -verb
  fi
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi

}

export -f fitting
find "$path_der" -type f -name '*_preproc_smoothed_resampled.nii.gz' > "$path_der/input_files.txt"

N=1
current_subject=0
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((current_subject++))
   ((i=i%N)); ((i++==0)) && wait
   fitting "$ii" "$mask" "$matrix" & 
   echo "Processing subject $current_subject of $(wc -l < "$path_der/input_files.txt")"
done
)
rm "$path_der/input_files.txt"