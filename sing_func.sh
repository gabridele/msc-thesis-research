#!/bin/bash
path_der="derivatives/"

function sing_wm {
  input="$1"
  sub_id=$(basename "$input" | cut -d'_' -f1)
  low_15="${input%_task-scap_fit.nii.gz}low_wm15.nii.gz"
  low_30="${input%_task-scap_fit.nii.gz}low_wm30.nii.gz"
  low_45="${input%_task-scap_fit.nii.gz}low_wm45.nii.gz"

  high_15="${input%_task-scap_fit.nii.gz}high_wm15.nii.gz"
  high_30="${input%_task-scap_fit.nii.gz}high_wm30.nii.gz"
  high_45="${input%_task-scap_fit.nii.gz}high_wm45.nii.gz"

  sub_path=$(dirname "$input")
  
  # temporary directory
  tmp_dir=$(mktemp -d -p "$sub_path")

  # low wm
  3dbucket -prefix "${tmp_dir}/low_wm_condition1500_${sub_id}.nii.gz" -fbuc "$input[1]"
  3dbucket -prefix "${tmp_dir}/low_wm_condition3000_${sub_id}.nii.gz" -fbuc "$input[4]"
  3dbucket -prefix "${tmp_dir}/low_wm_condition4500_${sub_id}.nii.gz" -fbuc "$input[7]"

  #3dMean -prefix "${tmp_dir}/avg_low_wm_${sub_id}.nii.gz" ${tmp_dir}/low_wm_condition*.nii.gz

  # high mw
  3dbucket -prefix "${tmp_dir}/high_wm_condition1500_${sub_id}.nii.gz" -fbuc "$input[10]"
  3dbucket -prefix "${tmp_dir}/high_wm_condition3000_${sub_id}.nii.gz" -fbuc "$input[13]"
  3dbucket -prefix "${tmp_dir}/high_wm_condition4500_${sub_id}.nii.gz" -fbuc "$input[16]"

  #3dMean -prefix "${tmp_dir}/avg_high_wm_${sub_id}.nii.gz" ${tmp_dir}/high_wm_condition*.nii.gz
  
  # low-high
  #3dcalc -a "${tmp_dir}/avg_low_wm_${sub_id}.nii.gz" -b "${tmp_dir}/avg_high_wm_${sub_id}.nii.gz" -expr 'a - b' -prefix "$output"
 
  mv "${tmp_dir}/low_wm_condition1500_${sub_id}.nii.gz" "${sub_path}/low_wm_condition1500_${sub_id}.nii.gz"
  mv "${tmp_dir}/low_wm_condition3000_${sub_id}.nii.gz" "${sub_path}/low_wm_condition3000_${sub_id}.nii.gz"
  mv "${tmp_dir}/low_wm_condition4500_${sub_id}.nii.gz" "${sub_path}/low_wm_condition4500_${sub_id}.nii.gz"

  mv "${tmp_dir}/high_wm_condition1500_${sub_id}.nii.gz" "${sub_path}/high_wm_condition1500_${sub_id}.nii.gz"
  mv "${tmp_dir}/high_wm_condition3000_${sub_id}.nii.gz" "${sub_path}/high_wm_condition3000_${sub_id}.nii.gz"
  mv "${tmp_dir}/high_wm_condition4500_${sub_id}.nii.gz" "${sub_path}/high_wm_condition4500_${sub_id}.nii.gz"

  rm -rf "$tmp_dir"
}
  
export -f sing_wm

#find "$path_der" -type f -name '*_task-scap_fit.nii.gz' > "$path_der/fit_files.txt"

N=2
(
for ii in $(cat "$path_der/10_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   sing_wm "$ii" & 
done
)
#rm "$path_der/fit_files.txt"