#!/bin/bash

# This script prepares the confounds used for performing nuisance regression. It currently uses 6 motion traces, WM , and CSF + their temporal derivatives (16 regressors in total). We assume that
#       a) you have a T1 image of each subject that was segmented using the neural nets provided by Freesurfer. Labels: https://surfer.nmr.mgh.harvard.edu/fswiki/SynthSeg
#       b) For each subj, you already registered the epi image to the T1 image. 

# -----------------------------------------------------------
# Script written by Ludovico Coletta
# NILAB, FBK (2022)
# -----------------------------------------------------------


function prepare_confounds {

    mean_image=$1
    subject_epi=$(basename $mean_image _mcf_mean_reg.nii.gz)
    sub_folder_epi=$(dirname $mean_image)
    
    # Inverting the epi_to_t1 matrix. We need it to obtain the CSF ad WM masks in the EPI space
    
    convert_xfm -omat ${sub_folder_epi}/${subject_epi}_t1_to_epi.mat -inverse ${sub_folder_epi}/${subject_epi}_epi_to_t1.mat
    
    # In the anat folder of the subj, prepare the WM and CSF masks, erode them by one voxel, and project everything into the subj epi space.
    
    seg_t1_image=$(echo ${sub_folder_epi}/../anat/*seg_res.nii.gz)
    subject_t1=$(basename $seg_t1_image _seg_res.nii.gz)
    sub_folder_t1=$(dirname $seg_t1_image)
    
    # Cortical WM
    fslmaths $seg_t1_image -thr 2 -uthr 2 -bin ${sub_folder_t1}/${subject_t1}_left_ctx_wm.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_left_ctx_wm.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_left_ctx_wm_ero.nii.gz -dilate_input -1
    
    fslmaths $seg_t1_image -thr 41 -uthr 41 -bin ${sub_folder_t1}/${subject_t1}_right_ctx_wm.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_right_ctx_wm.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_right_ctx_wm_ero.nii.gz -dilate_input -1

    # Cerebellar WM
    fslmaths $seg_t1_image -thr 7 -uthr 7 -bin ${sub_folder_t1}/${subject_t1}_left_cerebellar_wm.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_left_cerebellar_wm.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_left_cerebellar_wm_ero.nii.gz -dilate_input -1
    
    fslmaths $seg_t1_image -thr 46 -uthr 46 -bin ${sub_folder_t1}/${subject_t1}_right_cerebellar_wm.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_right_cerebellar_wm.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_right_cerebellar_wm_ero.nii.gz -dilate_input -1
    
    # Add everything together
    fslmaths \
         ${sub_folder_t1}/${subject_t1}_left_ctx_wm_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_right_ctx_wm_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_left_cerebellar_wm_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_right_cerebellar_wm_ero.nii.gz \
         -bin ${sub_folder_t1}/${subject_t1}_wm_ero.nii.gz

    # Project into EPI SPACE    
    flirt \
         -in ${sub_folder_t1}/${subject_t1}_wm_ero.nii.gz \
         -ref $mean_image \
         -out ${sub_folder_t1}/${subject_t1}_wm_ero_epi.nii.gz \
         -interp nearestneighbour \
         -init ${sub_folder_epi}/${subject_epi}_t1_to_epi.mat \
         -applyxfm
             
    # CSF
    fslmaths $seg_t1_image -thr 4 -uthr 4 -bin ${sub_folder_t1}/${subject_t1}_left_lateral_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_left_lateral_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_left_lateral_ventr_ero.nii.gz -dilate_input -1
    
    fslmaths $seg_t1_image -thr 5 -uthr 5 -bin ${sub_folder_t1}/${subject_t1}_left_inf_lateral_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_left_inf_lateral_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_left_inf_lateral_ventr_ero.nii.gz -dilate_input -1
        
    fslmaths $seg_t1_image -thr 43 -uthr 43 -bin ${sub_folder_t1}/${subject_t1}_right_lateral_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_right_lateral_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_right_lateral_ventr_ero.nii.gz -dilate_input -1    
    
    fslmaths $seg_t1_image -thr 44 -uthr 44 -bin ${sub_folder_t1}/${subject_t1}_right_inf_lateral_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_right_inf_lateral_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_right_inf_lateral_ventr_ero.nii.gz -dilate_input -1    

    fslmaths $seg_t1_image -thr 14 -uthr 14 -bin ${sub_folder_t1}/${subject_t1}_third_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_third_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_third_ventr_ero.nii.gz -dilate_input -1

    fslmaths $seg_t1_image -thr 15 -uthr 15 -bin ${sub_folder_t1}/${subject_t1}_fourth_ventr.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_fourth_ventr.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_fourth_ventr_ero.nii.gz -dilate_input -1

    fslmaths $seg_t1_image -thr 24 -uthr 24 -bin ${sub_folder_t1}/${subject_t1}_csf_sys.nii.gz
    3dmask_tool -input ${sub_folder_t1}/${subject_t1}_csf_sys.nii.gz -prefix ${sub_folder_t1}/${subject_t1}_csf_sys_ero.nii.gz -dilate_input -1
      
    # Add everything together
    fslmaths ${sub_folder_t1}/${subject_t1}_left_lateral_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_left_inf_lateral_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_right_lateral_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_right_inf_lateral_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_third_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_fourth_ventr_ero.nii.gz \
         -add ${sub_folder_t1}/${subject_t1}_csf_sys_ero.nii.gz \
         -bin ${sub_folder_t1}/${subject_t1}_csf_ero.nii.gz

    # Project into EPI SPACE    
    flirt \
         -in ${sub_folder_t1}/${subject_t1}_csf_ero.nii.gz \
         -ref $mean_image \
         -out ${sub_folder_t1}/${subject_t1}_csf_ero_epi.nii.gz \
         -interp nearestneighbour \
         -init ${sub_folder_epi}/${subject_epi}_t1_to_epi.mat \
         -applyxfm
         
    # Clean up some intermediate files
    rm ${sub_folder_t1}/${subject_t1}_left*gz ${sub_folder_t1}/${subject_t1}_right*.gz ${sub_folder_t1}/${subject_t1}_third_ventr.nii.gz 
    rm ${sub_folder_t1}/${subject_t1}_fourth_ventr.nii.gz ${sub_folder_t1}/${subject_t1}_csf_sys.nii.gz


    # extract WM signal
    fslmeants \
        -i ${sub_folder_epi}/${subject_epi}_mcf.nii.gz \
        -m ${sub_folder_t1}/${subject_t1}_wm_ero_epi.nii.gz \
        -o ${sub_folder_epi}/${subject_epi}_wm.txt
        
    # extract CSF signal
    fslmeants \
        -i ${sub_folder_epi}/${subject_epi}_mcf.nii.gz \
        -m ${sub_folder_t1}/${subject_t1}_csf_ero_epi.nii.gz \
        -o ${sub_folder_epi}/${subject_epi}_csf.txt
        
    # create regressor files via AFNI   
    1dcat \
         ${sub_folder_epi}/${subject_epi}_mcf.par \
         ${sub_folder_epi}/${subject_epi}_csf.txt \
         ${sub_folder_epi}/${subject_epi}_wm.txt \
         &> ${sub_folder_epi}/${subject_epi}_eight_regressors.txt
    
    
    1d_tool.py \
         -infile ${sub_folder_epi}/${subject_epi}_eight_regressors.txt \
         -derivative \
         -write ${sub_folder_epi}/${subject_epi}_eight_regressors_derivatives.txt
         
    1dcat \
         ${sub_folder_epi}/${subject_epi}_eight_regressors.txt \
         ${sub_folder_epi}/${subject_epi}_eight_regressors_derivatives.txt \
         &> ${sub_folder_epi}/${subject_epi}_eight_regressors_plus_derivatives.txt
                             
    }
export -f prepare_confounds

# main code starts here

numjobs=16

study_folder=IntraOpMap_RestingState #EDIT HERE

echo $PWD/${study_folder}/derivatives/CustomPrepro/Pre/sub-*/func/*_mcf_mean_reg.nii.gz | tr " " "\n" > subject_list.txt #EDIT HERE

parallel \
    -j $numjobs \
    prepare_confounds {} \
    < subject_list.txt

