path_der="derivatives/"
path_dl="derivatives/preproc_dl"

function run_AFM {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    arg2="$path_dl/${sub_id}/scap.feat/${sub_id}_mean_cope_resampled_ts_1vol.npy"
    n_seed=$(basename "$arg1" | awk -F '_' '{print $NF}' | cut -d 's' -f 1)

    echo -e "############# $sub_id, $arg1, $arg2"

    python ../code/AFM/AFM_run.py $arg1 $arg2 $n_seed
}

export -f run_AFM

find "$path_der" -type f -name '*_rs_correlation_matrix.npy' > "$path_der/rs_mtrx_files.txt"

N=140
(
for ii in $(cat "$path_der/rs_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM "$ii" &
done
)
rm "$path_der/rs_mtrx_files.txt"