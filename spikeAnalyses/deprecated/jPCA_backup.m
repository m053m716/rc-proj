%% *jPCA*: _A Guide_
%
% Many of the population-level analyses that are described in assessments of 
% neurophysiological spiking population dynamics seek to interpret not necessarily 
% the mean firing rate, which indeed co-varies most strongly with specific elements 
% of behavior, but rather, the unaccounted variance in underlying processes (sometimes 
% referred to as factors), which might otherwise be better explained when viewed 
% in covariance of overall population "dispersion" under certain task-specific 
% conditions. This script tries to walk through that process in a sensible way.

%% Initialize |*jPCA*| Data
% Click |*Initialize*| to run the current section. Doing so will initialize 
% the main data table, excluding unwanted grouping categories (e.g. trials where 
% no pellet was present).
%
% Clear workspace & load data (if needed)

clearvars -except T G
if exist('T','var')==0
   % note that `'rate_table_default_matfile'` is the smaller table
   % it does not necessarily contain all Alignments etc. (just to save time
   % on loading). It may be necessary to load the other, larger `'T.mat'`
   % file, which doesn't have _default.mat apprended on the end of the
   % filename.
   load(defaults.files('rate_table_default_matfile'),'T');
end

% Reduce table to working subset, |*M*|

M = analyze.marg.get_subset(T);
%% Remove relevant Marginalizations
% Click |*Marginalize*| to run the current section, creating a data table of 
% mean-subtracted trial rates that corresponds to trials with zero cross-trial 
% average according to the groupings in marginalizations.
%
% Subtract group means in a principled way
% We expect there to be large, striking differences in the observed neurophsyiological 
% spiking time-series, with this being unsurprising for the following marginalizations: 
% 
% * |*Group*| (we expect a difference between Ischemic vs. Intact rats)
% * |*Rat*| (we expect a random within-rat difference simply due to different 
% combination of recording channels etc.)
% * |*Area*| (we expect a difference on the basis of Premotor vs. Motor area)
% * |*ICMS*| (motor representation, such as Forelimb vs. Whiskers)
% * |*Channel*| (a huge difference for individual channels)

marginalizations = {'AnimalID','Area','Channel','Alignment','Outcome'};
outcome = 'Successful';
min_n_trials = 5;

%% Create marginalized dataset

S = analyze.marg.subtract_rat_means(M,marginalizations);
S = utils.filterByNTrials(S,min_n_trials,outcome); % Restrict subset to analyze
% View example of mean-subtracted rates
% Click |*Plot| once you have selected the desired Alignment and Outcome parameters.
%
% Set parameters:
%
% * |*animal*| : Exemplar Animal to use in single-recording jPCA analysis/visualization
% * |*align_event*| : Alignment event to use for single-recording jPCA analyses
% * |*save_fig*| : Toggle checkbox on if you wish to automatically save the 
% generated figure
% * |*show_pre_mean_subtraction*| : Toggle checkbox on if you want to check 
% pre-mean-subtraction data

animal = 'RC-05';
align_event = 'Grasp';
save_fig = false; % Auto-saves the figure, if ticked
show_pre_mean_subtraction = false; % Show same data, prior to mean-subtraction

% % Survey of some combinations that I've looked at % %
%   Intact group
% RC-14 - PO-05 - Grasp: same issue as some of Ischemia guys regarding
%       expansions and contractions while still having rotatory structure
% RC-18 - PO-17 - Grasp: looks good in jPCA on Plane-1
% RC-21 - PO-14 - Grasp: looks good in jPCA on Plane-1
% RC-43 - PO-24 - Grasp: looks good in jPCA on Plane-1
%
%   Ischemia group
% RC-02 - PO-17 - Grasp: not as strong jPCA structure on Plane-1
% RC-04 - PO-16 - Grasp: not as strong jPCA structure on Plane-1
% RC-05 - PO-08 - Grasp: not as strong jPCA structure on Plane-1
% RC-08 - PO-16 - Grasp: not as strong jPCA structure on Plane-1
% RC-26 - PO-19 - Grasp: definitely has separation between
%           success/unsuccesful in Plane-1, but has some elements of rotatory
%           structure combined with a lot of expansion/contraction elements.
% RC-30 - PO-16 (& others) - Grasp: has quite good jPCA structure on
%                               Plane-1. Note that on this day, he had many
%                               more successful trials included than
%                               unsuccessful trials, although the variance
%                               captured is lower in general for any of the
%                               visualized planes.
[fig_by_Channel,s] = analyze.rec.plot_rate(...
    utils.filterByNTrials(S,min_n_trials,outcome,'AnimalID',animal),... 
    align_event,outcome,save_fig,1);
%% 
% This figure produces subplots for all trials of a single Block. Each subplot 
% represents a different channel. The top two rows represent normalized spike 
% rates on channels that are in Caudal Forelimb Area (CFA; rat M1 homolog) that 
% is ipsilateral to the forelimb retrieving the pellet. The bottom two rows represent 
% normalized spike rates on channels that are in Rostral Forelimb Area (RFA; rat 
% PM homolog) contralateral to the forelimb retrieving the pellet. Time is represented 
% on the x-axis in milliseconds. The bold text above each subplot indicates the 
% approximate intracortical microstimulation (ICMS) co-registration from a mapping 
% procedure done just prior to the insertion of the microwire arrays. It follows 
% the key: 
%
% * *Distal Forelimb* (DF)
% * *Proximal Forelimb* (PF)
% * *Distal & Proximal Forelimb* (DF-PF)
% * *No Response* (NR; 80 uA maximum current)
% * *Other* (O; e.g. Trunk, Vibrissae, Mouth, etc.)
%
% Verify that the mean-subtracted outcomes make sense; the largest "modulated" 
% component should be the task-aligned one. Since we do not typically see "traditionally" 
% coherent task-related fluctuations, particularly around the 0-ms task alignment, 
% it looks like we correctly subtracted the mean. You can see if there is a difference 
% by toggling the check-box below.

if show_pre_mean_subtraction
    % Note that `M` is the pre-subtraction table
    [fig_by_Channel_orig] = analyze.rec.plot_rate(M(ismember(M.RowID,s.RowID),:),...
        align_event,outcome,save_fig,1); %#ok<UNRCH> 
end
%% Apply Population-Level Analysis
% Click |*Convert*| to create the formatted struct for analyzing the spike rates 
% of trials from a single recording using the (modified) Churchland & Cunningham 
% jPCA scripts.
%  
% Using our marginalized dataset, we can now apply population-level analysis. 
% A principled approach is detailed in (cite), which describes jPCA, a method 
% that attempts to assess the strength of rotatory dynamics present under the 
% assumption that the population dynamics are the result of factors governed in 
% an oscillatory fashion, which is captured by a system of differential equations 
% as:
% 
% Where  is constrained to be skew-symmetric during the optimization procedure 
% (a least-squares minimization). The recovered fit should then be compared to 
% , which is the optimal solution in the least-squares sense. If the fits are 
% comparable (and that part can be nebulous; in general, it would seem that you 
% want the top pairs of eigenvectors to capture 20-40% of the observed data variance 
% as a seeming rule of thumb).
% Organize data for jPCA code
% _Note that all code in |*analyze.jPCA*| is based on code kindly provided by 
% John P. Cunningham & Mark Churchland; it has been changed slightly from the 
% original format to accomodate some optional parameters for visualization purposes, 
% and the documentation is changed to reflect notes as I was learning the material._
% 
% *We will use the (small-m) matrix that we inspected rates for above*

if exist('s','var')==0
    error('Must run previous section prior to this one.')
end
area = "All";
[Data,J,JID] = analyze.jPCA.convert_table(...
    s,align_event,area,...
    'Outcome',outcome);
if isempty(Data)
    error('No trials meet those criteria.');
end
% Verify |*Data*| exported as intended
% Once the Data struct has been exported for jPCA, click Check Data to plot 
% one of the exported trials, verifying that filtering/interpolating didn't do 
% anything "weird." Click |*Run*| to run the current section (_see "*Setting* 
% |*jPCA_params"| below)_.

  % Run current section (requires `Data` (formatted struct array))
if exist('Data','var')==0
    error('Must run previous section to extract `Data` first');
end
% *Setting |jPCA_params*|
% For jPCA, most parameters are set via the defaults and previously-initialized 
% variables. The following parameters can be toggled as desired:
%
% * |*.numPCs*| : Total number of principal components to use for obtaining 
% linearized dynamical system fit.
% * |*.PCStem.PlotMeans*| : Toggle to true in order to plot mean PC values for 
% different conditions (outcomes). Only makes sense if using more than one outcome.

jPCA_params = defaults.jPCA('jpca_params');
jPCA_params.numPCs = 12; % Note: only increments by **even** values
jPCA_params.PCStem.PlotMeans = false; % Plot means if true, otherwise plot individual trials (PCs)

% If you do not wish to see some element of the jPCA output displayed, tick 
% the corresponding checkbox:
%
% * |*.suppressPCstem :*| Stem plot showing % of original data explained by 
% selected |*.numPCs*| parameter.
% * |*.suppressRosettes :*| Arrow "rosette" plots showing individual trial phase 
% trajectories.
% * |*.suppressHistograms :*| Phase-angle histogram displays.
% * |*.suppressText :*| Formatted text reporting eigenvalues and % of data explained 
% and % variance captured.

jPCA_params.suppressPCstem = false; % Set true to suppress PC stem plot
jPCA_params.suppressRosettes = false; % Set true to suppress jPC rosette planar plots
jPCA_params.suppressHistograms = false; % Set true to suppress jPC plane phase angle histograms
jPCA_params.suppressText = false; % Set true to suppress text output

% For plot titles etc. we associate metadata with the parameters struct, but 
% there are no actual parameters to "set" here:

if exist('area','var')~=0
    jPCA_params.Area = area; % Assign `Area` metadata
end
if exist('align_event','var')~=0
    jPCA_params.Alignment = align_event; % Assign `Alignment` metadata
end
if exist('animal','var')~=0
    jPCA_params.Animal = animal; % Assign `Animal` metadata
end
jPCA_params.Day = Data(1).PostOpDay; % Assign `PostOpDay` metadata
 
% With the parameters configured, make a plot to check what the data looks like:

fig = analyze.marg.plot_trial_to_double_check(Data,J);
 
% *Top-left:* the "Original" spike rates (after an initial smoothing step, and 
% whatever other processing has been applied, as shown in |*J.Properties.UserData.Processing*|). 
% 
% *Bottom-left:* Visually inspect that these interpolated and smoothed traces, 
% which are used to give the data to the |*jPCA*| algorithm using a finer time-scale 
% (the derivative is approximated using *differences* between consecutive time-values), 
% have not caused the data to change drastically. 
% 
% *Right:* The distribution of errors shows that, for a minority of the samples, 
% there actually is a substantial change induced by this smoothing and interpolation 
% step; however, the majority of the sample differences are very close to zero. 
% (_Note: some of the error should be accounted for by non-exact matches of interpolated 
% times compared to the "closest" original time, so that differences could be 
% taken to begin with_). 

%% Recover |*jPCA*| projections and summary structure
% With the recording block trial rate data in the appropriate Data array struct, 
% click Run jPCA to recover the single-trial Projections and skew-symmetric projection 
% matrix that best fits the linearized dynamical system.
% 
% This part actually recovers the jPCA projections for a single trial, and depending 
% on the configured |*jPCA_params*| values, displays the rosettes, phase difference 
% histograms, and some printouts such as the eigenvalues and the amount of data 
% explained. 

[Projection,Summary] = analyze.jPCA.jPCA(Data,jPCA_params);
 
% *Top:* The panel shows the selected jPCA plane, which is spanned by a pair 
% of basis vectors in the linear mapping of the data such that it is best fit 
% to its own (time) derivative. The least-squares minimization procedure that 
% recovers this matrix is constrained such that the algorithm must recover a skew-symmetric 
% transformation matrix, which by definition should have pairs of complex-conjugate 
% eigenvectors indicative of a "rotatory subspace" within the neuronal population 
% time-series dynamics. Ideally, each "rosette" arrow (an individual trial)
% 
% *Bottom:* The distribution of phase angle differences between the position 
% in jPCA-plane-space and the corresponding "velocity" of the neural trajectory 
% at that position in jPCA-plane-space. A distribution centered about pi or -pi 
% indicates an offset of 90 degrees between the two phase angles indicates "perfect" 
% rotatory structure (e.g. circles) within the subspace.

%% |*Export*| jPCs in multiple alignments
% To perform a statistical analysis on the strength of rotatory subspaces captured 
% using the jPCA method, so that we can assess trends across days (i.e. during 
% recovery from focal ischemia), we want to export all the data in a batch as 
% a big table, *where each row quantifies the rotatory strength of a particular 
% plane* during a single |*Trial*| or as an aggregate metric from all trials in 
% a recording |*Block*| in some alignment condition. The row should also indicate 
% how much of the data is represented by this plane, and how accurately the projection 
% matrix was able to linearize the dynamical system.
% 
% Click |*Export*| to run the batch export, making sure that the checkbox is 
% clicked (toggling it to false is the default so that clicking Run at the top 
% doesn't accidentally start the batch export, which can take a few minutes depending 
% on settings).
%
% _*Note:* jPC estimation is performed separately for each Alignment; therefore, 
% the jPCs present during Reach may not reflect those present during Grasp. For 
% estimating the number of PCs, in this case we always use the largest even value 
% that is less than the total number of channels present in the data._

D = analyze.jPCA.multi_jPCA(S,jPCA_params);