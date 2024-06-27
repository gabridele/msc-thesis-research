#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep 28 08:53:00 2022

@author: ludovicocoletta
"""

import os 
import numpy as np
import glob

def main():
    
    study_folder='IntraOpMap_RestingState'
    
    fd_files=sorted(glob.glob(os.getcwd()+'/'+study_folder+'/derivatives/CustomPrepro/Pre/sub-*/func/*fd.txt'))
    
    # As per https://www.nature.com/articles/s41467-022-29766-8. The only difference is the FD thr. We set 0.5mm
    
    thr_censoring=0.5
    perc_vol_removed=np.zeros(len(fd_files))
    min_consecutive_n_vol=5
    
    for ii in range(0,len(fd_files)):
        
        fd_sub=np.loadtxt(fd_files[ii])
        censor_list_afni=np.ones(fd_sub.size)
        ind_to_scrub=np.where(fd_sub>thr_censoring)
        
        if ind_to_scrub[0].size==0:
            file_name='/'.join(fd_files[ii].split('/')[:-1]) + '/' + '_'.join(fd_files[ii].split('/')[-1].split('_')[0:-1])+'_censor.txt'
            np.savetxt(file_name, censor_list_afni,fmt='%i')
        
            
        else:
            
            prev_vol=ind_to_scrub[0]-1
            
            succ_one_frame=ind_to_scrub[0] + 1
            succ_two_frames=ind_to_scrub[0] + 2
            
            all_vol_to_scrub=sorted(list(set(np.concatenate((prev_vol,ind_to_scrub[0],succ_one_frame,succ_two_frames),axis=0))))
            all_vol_to_scrub=[ii for ii in all_vol_to_scrub if ((ii>=0) and (ii<=len(fd_sub)-1))]
            
            #new_starting_indices_for_censoring=[[all_vol_to_scrub[ii],all_vol_to_scrub[ii+1]] for ii in range(0,len(all_vol_to_scrub)-1) if all_vol_to_scrub[ii+1]-all_vol_to_scrub[ii]==min_consecutive_n_vol]
            new_starting_indices_for_censoring=[[all_vol_to_scrub[ii],all_vol_to_scrub[ii+1]] for ii in range(0,len(all_vol_to_scrub)-1) if ((all_vol_to_scrub[ii+1]-all_vol_to_scrub[ii]>=2) and (all_vol_to_scrub[ii+1]-all_vol_to_scrub[ii]<=min_consecutive_n_vol))]
            
            new_starting_indices_for_censoring_consecutive=[list(range(new_starting_indices_for_censoring[ii][0],new_starting_indices_for_censoring[ii][1])) for ii in range(0,len(new_starting_indices_for_censoring))]
            
            for iii in range(0,len(new_starting_indices_for_censoring_consecutive)):
                aa=new_starting_indices_for_censoring_consecutive[iii]
                for iiii in range(0,len(aa)):
                    all_vol_to_scrub.insert(0, new_starting_indices_for_censoring_consecutive[iii][iiii])
                    
            all_vol_to_scrub=sorted(all_vol_to_scrub)
            censor_list_afni[all_vol_to_scrub]=0
            file_name='/'.join(fd_files[ii].split('/')[:-1]) + '/' + '_'.join(fd_files[ii].split('/')[-1].split('_')[0:-1])+'_censor.txt'
            np.savetxt(file_name, censor_list_afni,fmt='%i')
            
            perc_vol_removed[ii]=(len(all_vol_to_scrub)/np.size(fd_sub))*100

if __name__ == "__main__":
    main()        
