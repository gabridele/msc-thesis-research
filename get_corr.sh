# new day, new shell script <3
function sing_wm {
  input="$1"
  sub_id="$2"
  sub_path="$3"

  # Temporary directory
  tmp_dir=$(mktemp -d -p ".")

  # Low wm
  3dbucket -prefix "${tmp_dir}/dec_low_wm_1500_${sub_id}.nii.gz" -fbuc "${input}[1]"
  3dbucket -prefix "${tmp_dir}/dec_low_wm_3000_${sub_id}.nii.gz" -fbuc "${input}[4]"
  3dbucket -prefix "${tmp_dir}/dec_low_wm_4500_${sub_id}.nii.gz" -fbuc "${input}[7]"

  # High wm
  3dbucket -prefix "${tmp_dir}/dec_high_wm_1500_${sub_id}.nii.gz" -fbuc "${input}[10]"
  3dbucket -prefix "${tmp_dir}/dec_high_wm_3000_${sub_id}.nii.gz" -fbuc "${input}[13]"
  3dbucket -prefix "${tmp_dir}/dec_high_wm_4500_${sub_id}.nii.gz" -fbuc "${input}[16]"

  # Move files to sub_path
  mv "${tmp_dir}/dec_low_wm_1500_${sub_id}.nii.gz" "./dec_low_wm_1500_${sub_id}.nii.gz"
  mv "${tmp_dir}/dec_low_wm_3000_${sub_id}.nii.gz" "./dec_low_wm_3000_${sub_id}.nii.gz"
  mv "${tmp_dir}/dec_low_wm_4500_${sub_id}.nii.gz" "./dec_low_wm_4500_${sub_id}.nii.gz"

  mv "${tmp_dir}/dec_high_wm_1500_${sub_id}.nii.gz" "./dec_high_wm_1500_${sub_id}.nii.gz"
  mv "${tmp_dir}/dec_high_wm_3000_${sub_id}.nii.gz" "./dec_high_wm_3000_${sub_id}.nii.gz"
  mv "${tmp_dir}/dec_high_wm_4500_${sub_id}.nii.gz" "./dec_high_wm_4500_${sub_id}.nii.gz"

  # Clean up temporary directory
  rm -rf "$tmp_dir"
}

# Function to correlate beta weights of 3ddeconvolve output and 3dremlfit
function corr_vols {
    input="$1"
    sub_id=$(basename "$input" | grep -oP 'sub-\d+')
    sub_path=$(dirname "$input")

    cd "${sub_path}/${sub_id}_scap_decon_outputs"
    pwd
    decon_file="Decon+orig.HEAD"
    decon=$(basename "$decon_file" | cut -d'.' -f1)
    output="${Decon%+*}Decon_${sub_id}.nii.gz"

    3dAFNItoNIFTI -prefix "$output" "$decon_file"
    pwd
    sing_wm "$output" "$sub_id" "$sub_path"
    merge_low="$(find "." -type f -name "dec_low*")"
    fslmerge -t "$output_merge" "$merge_low" "$merge_low"
    merge_high="$(find "." -type f -name "dec_high*")"
    fslmerge -t "$output_merge" "$merge_high" "$merge_high"

    cd ../../..
    pwd
}

export -f sing_wm
export -f corr_vols


path_der="derivatives"

# Find and process files
find "$path_der" -type f -name 'low_wm_1500_sub-*.nii.gz' > "$path_der/input_files.txt"

N=1
(
for ii in $(cat "$path_der/input_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   corr_vols "$ii" & 
done
)
rm "$path_der/input_files.txt"