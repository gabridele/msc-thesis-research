# to get the volume of parcels from an atlas:

#1: get N, number of parcels, by doing this:

fslstats $atlas_name -l 0 -R

#2: run this by modiying N
#N=454
for ii in {1..454}
do
       fslmaths $atlas_name -thr $ii -uthr $ii -bin roi${ii}.nii.gz
       fslstats roi${ii}.nii.gz -V > roi_${ii}.txt
done


#concatenate registered T1s and view them as time series

echo $PWD/derivatives/*/anat/space-MNI152NLin2006Asym/*warped.nii.gz | tr " " "\n" > registered_t1.txt

fslmerge -t reg_t1.nii.gz $(cat registered_t1.txt)

# concatenated ROIs:
output_file="combined.txt"
> $output_file
for i in {1..454}; do     
 input_file="roi_$i.txt"    
 cat $input_file >> $output_file
done

# make ANTS work:
export PATH=/home/gabriele.deleonardis/install/bin:$PATH

# get derivative fmri
1d_tool.py \
         -infile ${sub_folder_epi}/${subject_epi}_eight_regressors.txt \
         -derivative \
         -write ${sub_folder_epi}/${subject_epi}_eight_regressors_derivatives.txt
         
    1dcat \
         ${sub_folder_epi}/${subject_epi}_eight_regressors.txt \
         ${sub_folder_epi}/${subject_epi}_eight_regressors_derivatives.txt \
         &> ${sub_folder_epi}/${subject_epi}_eight_regressors_plus_derivatives.txt

