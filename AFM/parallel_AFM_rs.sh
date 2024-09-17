path_der="derivatives"
path_dl="preproc_dl"

function run_AFM_rs {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    arg2="$path_der/${sub_id}/func/processed_${sub_id}_mean_cope_resampled_ts_1vol.npy"

    if grep -q "^$sub_id$" "subject_id_with_exclusions.txt"; then
        echo -e "############# $sub_id, $arg1, $arg2 \n"

        python ../code/AFM/AFM_run_rs.py $arg1 $arg2
    else
        echo -e "\n Subject $sub_id is excluded. Skipping..."
    fi

}
export -f run_AFM_rs

find "$path_der" -type f -name 'processed_functional_connectivity_sub-*.npy' > "$path_der/rs_mtrx_files.txt"

N=140
(
for ii in $(cat "$path_der/rs_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM_rs "$ii" &
done
)
rm "$path_der/rs_mtrx_files.txt"