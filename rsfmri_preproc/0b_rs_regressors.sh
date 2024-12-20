# !/bin/bash
##!!! working directory must be that of dataset ~/spreading_dynamics_clinical
## path to extract physiological noise (first 5 acompcor) and compute the motion regressors: extract the 6 basic ones, their square, their derivative, their squared derivative (tot. 24) from *confounds.tsv file

path_der="derivatives/"

#0.1
echo "###################################################################" 
echo ".....................Processing motion regressors....................."

function regr_file {
    input="$1"
    #csf_file="${input%_bold*}_meants_CSF.tsv"
    sub_id=$(basename "$input" | cut -d'_' -f1)
    input=$(basename "$input")
    output="${input%.tsv}_regressors.tsv"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then

        cd derivatives/$sub_id/func/
        mkdir temp_files

        cp $(basename "$input") temp_files/
        #cp $(basename "$csf_file") temp_files/
        cd temp_files

        combined_file="combined_columns.tsv"

        # Extract wm column from the input file
        #cut -f 1 $(basename "$input") > "wm_column.tsv"

        # Extract column from meanTS csf file
        #cut -f 1 $(basename "$csf_file") > "csf_column.tsv"

        # Loop thru column index of physiological noise (first 5 of acompcor)

        for index in {13..17}; do
            echo "Processing column $index of $sub_id"

            # Extract the current column to a temporary file
            cut -f "$index" "$input" > "temp_column_${index}.tsv"
            #tail -n +2 "temp_column_${index}.tsv" > "tailed_temp_column_${index}.tsv"

            # Compute squared numbers using 1deval
            #1deval -expr 'a*a' -a "temp_column_${index}.tsv" > "squared_column_${index}.tsv"
            #echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_2"}')\n$(cat "squared_column_${index}.tsv")" > "squared_column_${index}.tsv"

            # Calculate derivatives using 1d_tool.py
            #1d_tool.py -overwrite -infile "tailed_temp_column_${index}.tsv" -derivative -write "derivative_column_${index}.tsv"
            #echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der"}')\n$(cat "derivative_column_${index}.tsv")" > "derivative_column_${index}.tsv"

            # Compute squared derivatives using 1deval
            # 1deval -expr 'a*a' -a "derivative_column_${index}.tsv" > "squared_derivative_column_${index}.tsv"
            #echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der2"}')\n$(cat "squared_derivative_column_${index}.tsv")" > "squared_derivative_column_${index}.tsv"

            # Pasting all $index columns together 
            paste "temp_column_${index}.tsv" >> "temp_combined_columns_${index}.tsv"
        done

        # Loop thru column index of motion noise
        for index in {19..24}; do
            echo "Processing column $index of $sub_id"

            # Extract the current column to a temporary file
            cut -f "$index" "$input" > "temp_column_${index}.tsv"
            tail -n +2 "temp_column_${index}.tsv" > "tailed_temp_column_${index}.tsv"

            # Compute squared numbers using 1deval
            1deval -expr 'a*a' -a "temp_column_${index}.tsv" > "squared_column_${index}.tsv"
            echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_2"}')\n$(cat "squared_column_${index}.tsv")" > "squared_column_${index}.tsv"

            # Calculate derivatives using 1d_tool.py
            1d_tool.py -overwrite -infile "tailed_temp_column_${index}.tsv" -derivative -write "derivative_column_${index}.tsv"
            echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der"}')\n$(cat "derivative_column_${index}.tsv")" > "derivative_column_${index}.tsv"

            # Compute squared derivatives using 1deval
            1deval -expr 'a*a' -a "derivative_column_${index}.tsv" > "squared_derivative_column_${index}.tsv"
            echo -e "$(head -n 1 "$input" | awk -v col="$index" -F'\t' '{print $col "_der2"}')\n$(cat "squared_derivative_column_${index}.tsv")" > "squared_derivative_column_${index}.tsv"

            # Pasting all $index columns together 
            paste "temp_column_${index}.tsv" "squared_column_${index}.tsv" "derivative_column_${index}.tsv" "squared_derivative_column_${index}.tsv" >> "temp_combined_columns_${index}.tsv"
        done

        # Pasting the wm column, csf column, and all combined column files together into a single file
        paste temp_combined_columns_{13..17}.tsv temp_combined_columns_{19..24}.tsv > "$combined_file"

        # remove first 4 values and header, as I removed first 4 TRs from nifti files 
        { head -n 1 "$combined_file"; tail -n +6 "$combined_file"; } > temp && mv temp "$combined_file"
        
        mv "$combined_file" "../$output"
        cd ..
        rm -r temp_files
        cd ../../..

    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f regr_file

find "$path_der" -type f -name '*_task-rest_bold_confounds.tsv' > "$path_der/confounds_files.txt"

N=1
(
for ii in $(cat "$path_der/confounds_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   regr_file "$ii" & 
done
)
rm "$path_der/confounds_files.txt"