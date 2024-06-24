#!/bin/bash

path_der="derivatives/"

function fake_ts {
  input="$1"
  sub_id=$(basename "$input" | grep -oP 'sub-\d+')
  condition=$(echo "$input" | grep -oP '(?<=_wm_)\d+(?=_sub)')
  output="${input%_wm*}_wm_${condition}_${sub_id}_2vol_ts.nii.gz"
  
  fslmerge -t "$output" "$input" "$input"

  echo -e "Done with $output"
}

export -f fake_ts

find "$path_der" -type f -name '*_wm_*.nii.gz' > "$path_der/fake_ts_files.txt"

N=2
(
for ii in $(cat "$path_der/fake_ts_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   fake_ts "$ii" & 
done
)
rm "$path_der/fake_ts_files.txt"