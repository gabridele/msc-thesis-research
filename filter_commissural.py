#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul  8 16:49:40 2024

@author: ludovicocoletta
"""
import pandas as pd
from dipy.io.streamline import load_tractogram, save_tck
from dipy.io.stateful_tractogram import Space, StatefulTractogram
import numpy as np
import glob
from nibabel.streamlines.array_sequence import ArraySequence
from multiprocessing import Pool

def filter_sub(sub):

    # sub: path to folder derivatives for a given subject
    
    b0=glob.glob(sub + '/dwi/*b0_masked.nii.gz')
    
    files=sorted(glob.glob(sub + '/dwi/*_roi_*.tck'))
    n_streams_per_roi=[]
    
    for file in files:
        print("processing:", file)
        streams=load_tractogram(file,b0[0])
        print('b0:', b0)
        tracto=streams.streamlines
        array_seq=ArraySequence()
               
        for stream in tracto:
                        
            if (stream[0][0] * stream[-1][0]<0) and (stream[0][1] * stream[-1][1]>0) and (stream[0][2] * stream[-1][2]>0):

                array_seq.append(stream,cache_build=True)
                array_seq.finalize_append()
        
        n_streams_per_roi.append(len(array_seq))                      
        out_name=file.replace('.tck','_only_comm.tck')
        print(out_name)
        trac=StatefulTractogram(array_seq,reference=b0[0],space=Space.RASMM)
        save_tck(trac,out_name)
        print('done processing', file)
    return n_streams_per_roi                     

def main():
    
    sub_folders=sorted(glob.glob('derivatives/sub*'))
    sub_folders = [path for path in sub_folders if not path.endswith('.html')]
    print(sub_folders)
    pool = Pool(processes=144)

    n_streams_per_roi_per_subj=pool.map(filter_sub, sub_folders)
    print(n_streams_per_roi_per_subj)
    n_streams_per_roi_per_subj=np.stack(n_streams_per_roi_per_subj)
    np.save('streams_count_per_roi_per_subj.npy',n_streams_per_roi_per_subj)
    n_streams_per_roi_per_subjj= pd.DataFrame(n_streams_per_roi_per_subj)
    n_streams_per_roi_per_subjj.to_csv('streams_count_per_roi_per_subj.csv')
    
if __name__ == "__main__":
        main() 
