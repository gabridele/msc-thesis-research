#!/bin/bash
# script to create a fake timeseries by concatenating to the single volume a copy of itself

path_der="derivatives"

function fake_ts {
  input="$1"
  sub_id=$(basename "$input" | grep -oP 'sub-\d+')
  output="${input%.nii.gz}_2vol_ts.nii.gz"
  
  fslmerge -t "$output" "$input" "$input"

  echo -e "Done with $output"
}

export -f fake_ts

find "$path_der" -type f -name '*mean_cope_resampled.nii.gz' > "$path_der/fake_ts_files.txt"

N=100
(
for ii in $(cat "$path_der/fake_ts_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   fake_ts "$ii" & 
done
)
rm "$path_der/fake_ts_files.txt"