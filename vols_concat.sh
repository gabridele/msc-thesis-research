cd derivatives/

function vols_concat {
 input="$1"
 sub_id=$(echo "$input" | sed 's/^.*\/sub/sub/')
 sub_id="${sub_id%%/dwi*}"
 output="./concat_vols.tsv"

 echo -e "$sub_id\n$(cat "$input")" > "${input}.with_header"
 # If output file doesn't exist, create it with the header and content
 if [ ! -f "$output" ]; then
   mv "${input}.with_header" "$output"
 else
   # Otherwise, append content of input file as new column
   paste "$output" "${input}.with_header" > "${output}.tmp" && mv "${output}.tmp" "$output"
 fi
 rm "${input}.with_header"

}

export -f vols_concat
find "." -type f -name 'AllVols.txt' > "./input_files.txt"
cat "./input_files.txt" | parallel -j 1 vols_concat {}
rm "./input_files.txt"
cd ..


















export -f vols_concat

find "." -type f -name 'AllVols.txt' > "./input_files.txt"
cat "./input_files.txt" | parallel -j 1 vols_concat {}
rm "./input_files.txt"