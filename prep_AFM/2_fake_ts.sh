#!/bin/bash

path_der="derivatives/"

function fake_ts {
  input="$1"
  output="${input%.nii.gz}_2vol_ts.nii.gz"

  fslmerge -t "$output" "$input" "$input"

  echo -e "Done with $output"
}

export -f fake_ts

find "$path_der" -type f -name '*_wm_condition*.nii.gz' > "$path_der/fake_ts_files.txt"

N=2
(
for ii in $(cat "$path_der/fake_ts_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   fake_ts "$ii" & 
done
)
rm "$path_der/fake_ts_files.txt"