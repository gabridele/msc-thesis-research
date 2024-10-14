#####
# script to run AFM with AW parallelizing over multiple siubjects
# adjust N to your likings
#####

path_der="derivatives"

function run_AFM_AW {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    arg2="$path_der/${sub_id}/func/processed_${sub_id}_mean_cope_resampled_ts_1vol.npy"
    n_seed=$(basename "$arg1" | awk -F '_' '{print $NF}' | cut -d 's' -f 1)

    # need to have a file with list of subjects that are retained after exclusion process 
    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
    
        echo -e "############# $sub_id, $arg1, $arg2, $n_seed"

        python ../code/AFM/AFM_run_AW.py $arg1 $arg2 $n_seed
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi
}

export -f run_AFM_AW

find "$path_der" -type f -name 'processed_association_matrix_*.csv' > "$path_der/ass_mtrx_files.txt"
sort "$path_der/ass_mtrx_files.txt" -o "$path_der/ass_mtrx_files.txt"

N=144
(
for ii in $(cat "$path_der/ass_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM_AW "$ii" &
done
)
rm "$path_der/ass_mtrx_files.txt"