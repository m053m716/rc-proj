# Spike Analyses

Analyses of neurophysiological data for `RC` project. This sub-folder has a 3-pronged approach:

1. Object-oriented structure for in-house pre-processing and workflow, designed to ultimately output a table with smoothed single-trial spike rates and associated metadata. From there, data is analyzed using sub-packages in `+analyze` to export endpoint statistic tables. 
2. [`+analyze/+stat`](https://github.com/m053m716/rc-proj/tree/master/spikeAnalyses/%2Banalyze/%2Bstat) contains code to fit Gaussian-modulated cosine pulses onto observed single-trial data at the single-channel level, recovering parameters that inform us about the **timing** and **overall modulation frequency** of multi-unit activity relative to behavioral recovery, post-operative day, and metadata such as where the recording channel is located. This gives us an idea of any **multi-unit scale** plasticity that occurs as recovery progresses and neurophysiology changes relative to a conserved behavior.
3. [`+analyze/+jPCA`](https://github.com/m053m716/rc-proj/tree/master/spikeAnalyses/%2Banalyze/%2BjPCA) contains code to perform the **jPCA** *population-scale* analyses, which recover the projection matrix for a linearized dynamical system regressing principal components of all recorded channels onto the derivative of said principal components, under the constraint that eigenvalues are pairs of imaginary complex conjugates. Ultimately, the average **phase angle** is recovered from these projections; in an ideal state plane with high rotatory strength (which is thought to be an important component in neurophysiology relating to motor behavior), this angle would be exactly 90 degrees; therefore, statistics aim to quantify **population-scale** plasticity using this value as a marker for the presence or absence of correct population dynamics during behavior.

## Overview

This folder contains (primarily) Matlab functions and classes used to curate and analyze neurophysiological multi-unit spike rate time-series that were acquired from rats in the `RC` project.

### Objectives

* Curate data and select non-noise channels for days with robust recordings.
* Incorporate tagged metadata so that it can be included for multivariate statistical regression.
* Generate a null hypothesis model using popular **`Population Dynamics`** theories regarding simultaneous activity of spiking units in motor areas of cortex.
  * Fit this model to different groupings of the data to see where the error is and use standard statistical testing (e.g. **`SSE`**) to realize how and why heterogeneous neural time-series differentiate between **ischemic** and **intact** rats.

## Use

#### Where to Start?

There are pretty much just two steps to follow:

1. If not already cloned to the same folder containing this repository, clone the following repository to the local folder that contains your `rc-proj` repository folder: 
   https://github.com/m053m716/Matlab_Utilities

   - This should be the only major **dependency** the repository has, and it's not actually the most important, but probably most of the functions will fail without it present so you have to make sure this part is set up correctly.

   - Once cloned, you may need to change a few configuration variables:

     - In `+local\defaults.m`, make sure that the following match your local installation-
       - `pars.LocalMatlabUtilitiesRepo` : Name of your cloned folder of `Matlab_Utilities`
       - `pars.LocalMatlabReposFolder` : Location containing the cloned `Matlab_Utilities` 
     - While here, if you have access to the data servers (or local copies of the data) you should check that the following data path variables match your local mappings:
       - `pars.CommunalDataTank` -- This pretty much just should point to your mapping of the KUMC Isilon `P:\Processed_Data` drive holding the original data.
       - `pars.LocalDataTank` -- This is where any "locally downloaded" data files should go, such as large tables used as loose databases for some of the processed data.

   - To check that all dependencies are installed successfully, from the `spikeAnalyses` folder you can run the following line in the **Command Window:**

     ```(matlab)
     utils.checkInstalledRepos();
     ```

     It will print a success message to the Command Window if it finds the Utilities repo and play a sound; otherwise, it will throw an error message.

     

2. You can see an overview of pre-processing and curation steps as well as aggregate Table generation in `main.m`, however this is probably uninteresting and can take a while depending on what stage you have saved versions of the data for. Most likely, skip this step.

3. To look at the main analyses of interest that were applied to these data, click through `marg.mlx` in a Matlab release that supports the Matlab `Live Editor` (likely, `Matlab R2016a` and beyond).

   * *Note:* prior to running `marg.mlx`, make sure that you have a local version of the data table `*.mat` file. This should be saved somewhere locally as the file `T_default.mat`. 
   * If you did not save `T_default.mat` to the folder specified by `pars.LocalDataTank` in `+local\defaults.m`, then either change the name to match the actual location in `pars.LocalDataTank` or move the variable to the specified location on your machine.