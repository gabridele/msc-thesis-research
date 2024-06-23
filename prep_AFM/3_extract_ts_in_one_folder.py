from nilearn import image
from nilearn import regions
import numpy as np
import os
import glob
import time
from multiprocessing import Pool
import scipy.io as sio

def extract_ts(subject_name):

   ts,labels=regions.img_to_signals_labels(image.load_img(subject_name,dtype='float64'), image.load_img(path_to_atlas), mask_img=None, background_label=0)

   sub_name_no_ending=('.').join(subject_name.split('/')[-1].split('.')[:-2])
   
   np.save(out_dir+'/'+sub_name_no_ending,ts)


def main():


   global path_to_atlas

   path_to_atlas = os.getcwd()+'derivatives/template'+'/'+'Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_2009c_NLinAsymm.nii.gz'
   
   global out_dir
   out_dir = os.getcwd()

   #path nella cartella coi dati func
   subjects = sorted(glob.glob('/home/ludovicocoletta/Documents/IntraOpMap_2022/04_preprocessed_rsfmri/dataverse_files/GSP1000/sub*/func/*bld001*.nii.gz'))

   pool = Pool(processes=6)

   pool.map(extract_ts, subjects)

# If called from the command line, run main()
if __name__ == '__main__':
   main()

