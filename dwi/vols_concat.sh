# add header to single parcel file
# run locally because used parallel library
function header {
 input="$1"
 file_name=$(basename "$input")
 #sub_id=$(echo "$input" | sed 's/^.*\/sub/sub/')
 #sub_id="${sub_id%%/dwi*}"
 output="./concat_vols.tsv"
 
 for subj in $(cat "subject_id_with_exclusions.txt"); do
  echo "Processing subject: $subj"
  echo "File name: $file_name"

  cd derivatives/$subj/dwi/Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_by_parcel/

  echo -e "$subj\n$(cat "$file_name")" > "${file_name%.txt}_"$subj"_with_header.txt"
  cd ../../../..
 done

}

export -f header
find "." -type f -name 'AllVols.txt' > "./input_files.txt"
cat "./input_files.txt" | parallel -j 1 header {}
rm "./input_files.txt"
cd ..


# create a tsv storing all the volumes of the parcels of all subjects
function vols_concat {
  output_file="./concat_vols.tsv"
  temp_dir=$(mktemp -d)

  for subj in $(cat "subject_id_with_exclusions.txt"); do
    echo "Processing subject: $subj"
    input_file="derivatives/$subj/dwi/Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_by_parcel/AllVols_${subj}_with_header.txt"
    if [[ -f "$input_file" ]]; then
      cp "$input_file" "$temp_dir/${subj}_vols.txt"
    else
      echo "File not found: $input_file"
    fi
  done

  # Use paste to concatenate all files column-wise
  paste "$temp_dir"/* > "$output_file"

  # Clean up temporary directory
  rm -r "$temp_dir"
}

export -f vols_concat

vols_concat