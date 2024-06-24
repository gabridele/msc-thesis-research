path_der="derivatives/"

function run_AFM_sing {
    arg1="$1"
    sub_id=$(basename "$arg1" | grep -oP 'sub-\d+')
    n_seed=$(basename "$arg1" | awk -F '_' '{print $NF}' | cut -d 's' -f 1)

    for wm_condition in 1500 3000 4500; do
        # Generate arg2 paths for both low_wm and high_wm conditions
        arg2_low="${arg1%dwi/full_association_mtrix_sub*}func/low_wm_${wm_condition}_${sub_id}_ts_1vol.npy"
        arg2_high="${arg1%dwi/full_association_mtrix_sub*}func/high_wm_${wm_condition}_${sub_id}_ts_1vol.npy"

        # Run your Python script with each combination of arg1 and arg2
        echo -e "############# $sub_id, $arg1, $arg2_low" 
        python ../code/AFM_run.py "$arg1" "$arg2_low" "$n_seed"

        echo -e "############# $sub_id, $arg1, $arg2_high"
        python ../code/AFM_run.py "$arg1" "$arg2_high" "$n_seed"
    done
}

export -f run_AFM_sing

find "$path_der" -type f -name '*full_association_mtrix_*_2seeds.csv' > "$path_der/ass_mtrx_files.txt"

N=100
(
for ii in $(cat "$path_der/ass_mtrx_files.txt"); do 
   ((i=i%N)); ((i++==0)) && wait
   run_AFM_sing "$ii" &
done
)
rm "$path_der/ass_mtrx_files.txt"