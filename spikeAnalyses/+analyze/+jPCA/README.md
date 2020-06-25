# Single-recording jPCA State Plane Fits #

This package contains `MATLAB` functions adapted from their **[original version](https://www.dropbox.com/sh/2q3m5fqfscwf95j/AAC3WV90hHdBgz0Np4RAKJpYa?dl=0)** for two purposes:

1. Performing **`jPCA`** using all or a subset of channels in alignment to some condition. 
2. Exporting summary statistics of the recovered state-space trajectories in a principled way that allows the construction of a statistical model, which then assesses changes in spiking dynamics at the **multi-unit population scale**.  

## Overview ##

This section indicates the fit parameters and generic database structure.

### Motivation ###

The main **fixed effect** of interest is the interaction of *Group, Electrode Location, and Post-Operative Day* in predicting changes in the following response parameter:

* **Average absolute dot-product of absolute phase difference in state plane with 90 degrees** ("strength of rotations" - A value of zero indicates a purely circular subspace)
  * **Null hypothesis H0:** No effect of post-operative day on timing parameter for either area.
  * **Alternative hypothesis H1:** Timing parameter in premotor homolog has significant positive coefficient for interaction effect, corresponding to a "shift" in distribution of observed activation tunings as existing corticospinal projections become more active in direct-alignment to behavior as opposed to predominantly during behavior preparation. No effect on timing parameter in motor cortex homolog in uninjured hemisphere.
* **Variance captured by rotatory plane model** ("presence of rotational dimensions" - The least-squares regression will **always** recover pairs of eigenvectors corresponding to "rotatory" subspace bases)

We know that **Duration** is a covariate that strongly affects pre-motor neural variability, and so it should accordingly be accounted for in the statistical model since there appears to be a trend for the **Ischemia** group wherein trial duration decreases as a function of post-operative day (presumably, as the recovering rats become more proficient).


### Database Structure ###

These data are structured as summarized in the **Data** tab as described in Figures 1-3 **[here](https://m053m716.github.io/RC-Data/)**. Specifically, data in **Figure 3** represent filtered views of rows from the **main database table**, `T`, wherein each row corresponds to the spike rate time-series estimate for a single recording channel, in alignment to a single behavioral event, from a single animal during one recording. In `MATLAB`, `T` contains the following variables (columns, listing most-relevant):

*  **`RowID`** : A unique alphanumeric identifier for each row, used in table filtering operations to ensure that the correct metadata is retained with each row.
*  **`Group`** : A categorical variable with 2 levels: {"Ischemia" or "Intact"}. This is one of the main effects we are interested in.
*  **`AnimalID`** : Categorical variable that is nested within **`Group`**. By group, there are 4 rats in "Intact" and 6 rats in "Ischemia".
*  **`BlockID`** : Categorical variable that is nested within **`AnimalID`**. Each element denotes an individual recording session; each session was performed on a unique **`PostOpDay`**, which takes a value on the range [3,30]. **`BlockID`** is unique to each rat, but **`PostOpDay`** is not.
*  **`Outcome`** : Categorical variable with 2 levels: {"Successful" or "Unsuccessful"}. We are restricting analyses to only "Successful" outcomes, since those present the most stereotyped behavior and we wish to compare changes in neurophysiology that facilitate a conserved behavior as recovery progresses.
*  **`Trial_ID`** : Categorical variable indicating unique trials (from all recordings/animals). 
   * *Note:* The following variables are "blocked" or nested within **Trial_ID**:
     * **`Alignment`** : Categorical event variable {"Reach","Grasp","Support","Complete"}, although we are mainly restricting the dataset to look at "Reach" and "Grasp" alignments.
     * **`ChannelID`** : Categorical variable indicating unique identifier for a particular spatial sensor position within a single rat. Each rat contains 32 channels divided equally between hemispheres, although this number is reduced in order to only retain channels with neurophysiological activity observed during each recording session.
*  **`ML`** : Categorical variable indicating whether shank was on "Medial" or "Lateral" row of probe array. Each member of **`ProbeID`** contains a unique subset of up to 16 elements of **`ChannelID`**. They are spatially configured in two rows, such that 8 of those elements are situated more medially relative to bregma (skull landmark used for stereotaxic positions), while 8 are more lateral. Note that **`ML`** should be the same for each instance of **`ChannelID`** (the same is true for any other "channel-related" metadata). The more-specific (continuous) location data for each **`ChannelID`** is shown in the variables **`X`** (anteroposterior stereotaxic distance from bregma, mm), and **`Y`** (mediolateral stereotaxic distance from bregma, mm).
*  **`ICMS`** : The evoked movement response obtained by using an intracortical microstimulation test pulse prior to insertion of the electrode array, nearest to the co-registered insertion sites (Categorical: {"DF", "DF-PF", "PF", "O", "NR"} which correspond to {"Distal Forelimb", "Distal or Proximal Forelimb", "Proximal Forelimb", "Other", "Non-responsive"}).
*  **`Area`** : The main effect of interest in combination with **`PostOpDay`** and **`Group`**; this has two levels {"RFA" (rostral forelimb area; PM homolog) or "CFA" (caudal forelimb area; M1 homolog)}. 

## Parameter Fitting Procedure ##

### Syntax ###

After recovering the master database, `T`, we recover the parameter fits using:

```(matlab)
G = analyze.stat.get_fitted_table(T,min_n_trials);
```

Where `min_n_trials` is an adjustable parameter that has been set to **5** for the exported table, meaning that there must be at least 5 (successful) trials from a given element of **`BlockID`** in order for that recording to be considered for further analysis. This is to avoid cases where we have a single trial for a given channel on some post-operative day, which could really bias the data if we have spurious fluctuation or a noisy channel for whatever reason on that particular instance. Ideally the restriction number could be higher, but given the nature of these data (the rehabilitation testing is restricted to a limited number of attempts to begin with),  it's a compromise between causing spurious model associations and throwing away too much of the experiment.

### Description ###

The bulk of the `get_fitted_table` function is in the parameterized built-in `fmincon` function provided by the `Statistics and Machine Learning` toolkit. The algorithm is as follows:

1. Set a "hyperparameter" grid, sweeping a combination of relevant parameters.
2. Evaluate at each point on the grid.
3. Initialize the constrained optimizer with the "best" combination (in this case, determined by the minimum residual sum of squares). 

The parameters are used by the `gauspuls` function (`Signal Processing Toolbox`) to fit a Gaussian-modulated cosine to the observed (smoothed) spike rate of each individual trial (data table row). Prior to the `fmincon` procedure, the individual trial spike rate is detrended using the following algorithm:

1. Compute the trial median spike rate (`b`)

2. Recover the least-squares optimal coefficient (`a`) of time (`t`) as a linear predictor of spike rate (`Rate`) as 

   ```(matlab)
   a = (Rate - b)/t; % matlab performs least-squares regression
   ```

3. The de-trended rates are therefore the residual rate not explained by the model

   ```(matlab)
   rate = a*t + b;
   ```

Often, spike rate histograms in alignment to a motor event look like a series of peaks and valleys, indicating alternating periods where a spike is more likely (due to excitation related somehow to the behavior) or less likely (due to inhibition related to the behavior, or refractory period of having been recently likely to depolarize). This "shape" is captured well by `gauspuls`, which allows us to recover the following parameters: 

#### **tau** ####

An offset parameter, which describes the time-shift of a zero-centered Gaussian-modulated cosine estimated at the relative times for which the spike rate was obtained.

#### **omega** ####

Frequency of the cosine component, which ranges on the order of a physiologically plausible behavior.

* For example, it's only reasonable that a rat might be expected to complete a reaching behavior at a maximum of 2 attempts per second. Therefore most values here are in the range of 0.25 - 1.5 Hz.

#### **sigma** ####

Fractional bandwidth of **[omega](#omega)** for the Gaussian pulse, which describes the bandwidth at half-maximum amplitude of the Gaussian "envelope."

### Exported Table (statistics) ###

The table used to fit a **Generalized Linear Mixed Effects model** (Matlab function `fitglme`) is recovered from the table of estimated parameters using

```(matlab)
Gr = analyze.stat.remove_excluded(G);
```

This step initially performed a **PCA** to obtain components that qualitatively were orthogonal elements that when plotted using the built-in `biplot` function to view the PC coefficients turned out to correspond to parameters that related to the timing and frequency parameters independently. Instead of fitting the principal component scores, since the timing and frequency parameter estimates do not demonstrate much covariance I decided to fit the recovered parameters directly.

The `remove_excluded` function also performs a series of filters that were included to reject poorly fit trajectories. Specifically, any time the product of **sigma** and **omega** is > 10 Hz (which is above the Nyquist frequency given the spike rate bin size), the data is excluded. `Gr` only contains rows in alignment to **Grasp** events, where the pellet was **Successfully** retrieved. Visual inspection of fitted data indicates that the `gauspuls` fits are robust across the majority of the sum-of-square error range; however, there was an outlier cluster that had very bad fits and so any rows for which the error exceeded **50** (a.u.) the trials were excluded. Finally, any time that the peak offset parameter **tau** exceeded 750-ms or was lower than -1000-ms relative to the alignment event, the trial was excluded, as values outside that range become exceedingly likely to be associated with some other behavior that is not under consideration in this experiment. After all exclusions, the number of observations was reduced from 211,424 rows to 20,220 rows. Categorical exclusions (total: **168,051**) were performed first and breakdown (independently) as follows:

* *By Outcome:* 117,611 exclusions
* *By Alignment:* 113,290 exclusions
* *By Day:* 0

After categorical exclusions, removals from the remaining **43,373** observations due to parameter-fit rules (total: **23,152**) breakdown (independently) as follows:

* *tau:* 21,396 exclusions
  * *tau < 1 second:* 8,674 exclusions
  * *tau > 0.75 seconds:* 12,722 exclusions
* *(sigma* * *omega) > 10 Hz:*  2,617 exclusions
* *sum of square errors > 50:* 0 exclusions

The remaining **20,221** rows were included in the following table (`Gr` from the code above) for statistical analysis contains metadata described in `T` as well as the following **endpoint (response)** variables:

* **`EnvelopeBW`** : Envelope bandwidth (Hz) - the product of **sigma** and **omega** parameters from model fit, which describes the bandwidth of overall modulation we see related to the behavior of interest.
* **`PeakOffset`** : Temporal offset (seconds) - The time of the fitted center of Gaussian pulse described by **`EnvelopeBW`**, relative to the behavioral alignment. Note that the cosine always has zero-phase angle at `t = PeakOffset` seconds relative to the event.

In addition, the following covariates are included:

* **Error_SS** : For each fit `rate` time-series, this is the sum of squares of errors at each time sample between the observed (smoothed) rate series and the fitted Gaussian-modulated cosine pulse. A higher value indicates a worse fit.
* **Duration** : Total duration of the behavior (time from **Reach** to **Complete** for a single trial; seconds). It has been well-described in the literature that there is a direct relationship between movement velocity and the population-level activity observed within the areas we are recording from. We expect this to be a strong covariate of the observed fit parameters, but we want to include it in the model to ensure that changes we are seeing are not simply due to the rat reaches becoming faster over time.
  * *Note: it is pretty clear that for the Ischemia group, the reaches **do** become faster over the time-course of the 3 weeks we do these recordings. So we definitely **must** account for this term.*

