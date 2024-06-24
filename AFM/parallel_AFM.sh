path_der="derivatives/"

function run_AFM {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    arg2="${arg1%dwi/full_association_mtrix_sub*}func/low_wm_*_${sub_id}_ts_1vol.npy"

    echo -e "############# $sub_id, $arg1, $arg2"

    python ../code/AFM_run.py $arg1 $arg2
}

export -f run_AFM

find "$path_der" -type f -name '*full_association_mtrix_*.csv' > "$path_der/ass_mtrx_files.txt"

N=80
(
for ii in $(cat "$path_der/ass_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM "$ii" &
done
)
rm "$path_der/ass_mtrx_files.txt"
