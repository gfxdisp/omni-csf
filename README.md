# Spatio-chromatic contrast sensitivity function for any colour direction.

This repository contains Matlab code for the spatio-chromatic contrast sensitivity function (SC-CSF), which predicts the smallest contrast that is visible to an average human observer. 

The SC-CSF is modeled as a function of:
* spatial frequency;
* colour and luminance of the background, specified as the LMS cone responses (using CIE LMS 2006 cone fundamentals);
* colour direction, in the LMS space;
* and stimulus size. 

Refer to the script `plot_sccsf.m` for an example on how to use the model.

The details of the model can be found in the paper:

Rafał K. Mantiuk, Minjung Kim, Maliha Ashraf, Qiang Xu, M. Ronnier Luo, Jasna Martinovic and Sophie Wuerger. _Practical color contrast sensitivity functions for luminance levels up to 10000 cd/m^2_. In: Color Imaging Conference (CIC28), 2020 [PDF](https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2020practical_csf.pdf)

Other papers and more details on the modeling of the spatio-chromatic CSF can be found at the [project web page](https://www.cl.cam.ac.uk/research/rainbow/projects/hdr-csf/).

This is an "early-access" version of the model, which is taken directly from our development branch. It is not optimized for speed and contains extra code that may not be relevant for the core functionality of the model. 
