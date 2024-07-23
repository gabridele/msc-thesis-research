from nilearn import image, regions # type: ignore
import numpy as np
import os
import glob
from multiprocessing import Pool

def extract_ts(subject_name):

    sub_id = subject_name.split('/')[-3]

    ts, labels = regions.img_to_signals_labels(
        image.load_img(subject_name, dtype='float64'),
        image.load_img(path_to_atlas),
        mask_img=None,
        background_label=0
    )

    ts = ts.T
    ts = ts[:, :1]
    
    sub_name_no_ending = os.path.basename(subject_name).rsplit('.', 2)[0]
    sub_name_no_2vol = sub_name_no_ending.replace('_2vol', '')

    output_path = os.path.join(out_dir, sub_id, 'func', sub_name_no_2vol + '_1vol.npy')
    np.save(output_path, ts)

def main():
    
    global path_to_atlas
    global out_dir

    path_to_atlas = os.path.join(os.getcwd(), 'derivatives', 'templates', 'Schaefer2018_400Parcels_Tian_Subcortex_S4_1mm_2009c_NLinAsymm.nii.gz')

    out_dir = os.path.join(os.getcwd(), 'derivatives')

    single_files = os.path.join(os.getcwd(), 'derivatives', 'sub*', 'func', 'sub-*_scap_decon_outputs', '*_2vol_ts.nii.gz')

    subjects = sorted(glob.glob(single_files))

    with Pool(processes=80) as pool:
        pool.map(extract_ts, subjects)

if __name__ == '__main__':
    main()

