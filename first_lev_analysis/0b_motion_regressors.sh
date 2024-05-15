#!/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
path_der="derivatives/"

#0.1
echo "###################################################################" 
echo ".....................Processing motion regressors....................."

function process_regr {
 input="$1"
 sub_id=$(basename "$input" | cut -d'_' -f1)
 input=$(basename "$input")
 output="${input%.tsv}_processed.tsv"

 if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
  cd derivatives/$sub_id/func/
  mkdir temp_files
  pwd
  cp "$input" temp_files/
  cd temp_files
  combined_file="combined_columns.tsv"

  # Loop through the specified columns
  for index in {19..24}; do
   echo "Processing column $index of $sub_id"
   
   # Extract the current column to a temporary file
   cut -f "$index" "$input" > "temp_column_${index}.tsv"
   tail -n +2 "temp_column_${index}.tsv" > "tailed_temp_column_${index}.tsv"
   pwd
   # Compute squared numbers using 1deval
   1deval -expr 'a*a' -a "temp_column_${index}.tsv" > "squared_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_2"}')\n$(cat "squared_column_${index}.tsv")" > "squared_column_${index}.tsv"

   # Calculate derivatives using 1d_tool.py
   1d_tool.py -infile "tailed_temp_column_${index}.tsv" -derivative -write "derivative_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der"}')\n$(cat "derivative_column_${index}.tsv")" > "derivative_column_${index}.tsv"

   # Compute squared derivatives using 1deval
   1deval -expr 'a*a' -a "derivative_column_${index}.tsv" > "squared_derivative_column_${index}.tsv"
   echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der2"}')\n$(cat "squared_derivative_column_${index}.tsv")" > "squared_derivative_column_${index}.tsv"

   # Pasting all $index columns together
   paste "temp_column_${index}.tsv" "squared_column_${index}.tsv" "derivative_column_${index}.tsv" "squared_derivative_column_${index}.tsv" >> "temp_combined_columns_${index}.tsv"

  done
 
  # Pasting all combined column files together in single file -> final file of motion regressors
  paste temp_combined_columns_{19..24}.tsv > "$combined_file"
  mv "$combined_file" "../$output"
  cd ..
  rm -r temp_files
  cd ../../..
 else
  echo -e "\n Subject $sub_id is excluded. Skipping..."
 fi
}

export -f process_regr

find "$path_der" -type f -name '*_task-scap_bold_confounds.tsv' > "$path_der/confounds_files.txt"


N=10
(
for ii in $(cat "$path_der/confounds_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   process_regr "$ii" & 
done
)
rm "$path_der/confounds_files.txt"