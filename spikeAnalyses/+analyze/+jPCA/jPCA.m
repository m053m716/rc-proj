function [Projection,Summary,PhaseData,fig] = jPCA(Data,varargin)
%JPCA Recover rotatory subspace projections from spike rate time-series
%
% [Projection,Summary] = analyze.jPCA.jPCA(Data);
% [Projection,Summary,PhaseData,fig] = analyze.jPCA.jPCA(Data,params);
% [__] = analyze.jPCA.jPCA(Data,'param1Name',param1Val,...)
%
% Inputs
%  Data   - A struct array with one entry per condition.
%            For a given condition (c), the following fields are needed:
%              -> Data(c).A should hold the data (e.g. firing rates)
%                 * Rows of A are time samples
%                 * Columns of A are channels or other variables measured
%                    in parallel during the recording
%              -> Data(c).times corresponds to relative times of rows of A
%
%   In addition, this modified code contains the following fields for Data:
%
%        .AnimalID
%           -> Name of Animal performing each trial
%        .Trial_ID
%           -> Identifier specific to an individual trial
%        .Alignment
%           -> Event used for aligning data in input `Rates`
%        .Group
%           -> Experimental group of a given animal.
%                 * ('Ischemia' or 'Intact')
%        .Outcome
%           -> 1 for unsuccessful, 2 for successful
%        .PostOpDay
%           -> Day, relative to implant, that data was collected
%        .Duration
%           -> Duration (ms) of reach-to-complete for this trial
%        .tReach
%           -> Relative time of "Reach" with respect to Alignment event
%        .tGrasp
%           -> Relative time of "Grasp" with respect to Alignment event
%        .tSupport
%           -> Relative time of "Support" with respect to Alignment event
%        .tComplete
%           -> Relative time of "Complete" with respect to Alignment event
%
%  params - An optional struct containing the following fields:
%   .analyzeTimes
%     -> Default is empty; if it's empty all times are used.
%   .numPCs
%     -> Default is 6. The number of PCs to use during pre-processing
%   .normalize
%     -> Default is 'true'.  Normalize each neuron (column) by FR range?
%   .softenNorm
%     -> Default is 10. How much do we "under-normalize" for low FR neurons
%        -> 0 means standard normalization
%        -> 10 maps an FR range of 10 spikes/sec -> 0.5
%   .suppressRosettes
%        -> Set true to prevent rosette plots
%   .suppressHistograms
%        -> Set true to prevent phase histogram plots
%   .suppressText
%        -> Set true to suppress command window output text
%
%  varargin - Alternatively, can use `<'Name',value> input argument pair
%              syntax to parameters without introducing the entire
%              parameter struct, using default values for the rest (or if
%              `params` is provided as first "varargin" argument, it will
%              still be parsed correctly).
%
% Output
%   Projection - A struct array with same dimension as `Data` with fields:
%       Main output field:
%       .proj
%        -> The projection into the 6D jPCA space.
%
%     In addition, Projection contains all fields of `Data` except for `A`
%     and the Duration/event time fields:
%
%        .Condition
%           -> Index that is odd for unsuccessful and even for successful
%              pellet retrieval trials, and scales with PostOpDay
%        .reachIndex
%           -> Index into `.times` for when Reach occurred this trial
%        .graspIndex
%           -> Index into `.times` for when Grasp occurred this trial
%        .supportIndex
%           -> Index into `.times` for when Support occurred this trial
%        .completeIndex
%           -> Index into `.times` for when Complete occurred this trial
%
%   Summary - Struct containing parameter and matrix mapping info:
%       .jPCs
%        -> The jPCs in terms of the PCs (not the full-D space)
%       .PCs
%        -> The PCs (each column is a PC, each row a neuron)
%       .jPCs_highD
%        -> The jPCs, but in the original high-D space.
%           * This is just PCs * jPCs, and is thus of size neurons x numPCs
%       .varCaptEachJPC
%        -> The data variance captured by each jPC
%       .varCaptEachPC
%        -> The data variance captured by each PC
%       .R2_Mskew_2D
%        -> Fit quality (fitting dx with x) provided by Mskew in top-2 jPCs
%       .R2_Mbest_2D
%        -> Fit quality for least-squares top-2 dimensions
%       .R2_Mskew_kD
%        -> Quality of map from x to dx provided by Mskew using all jPCs
%           * (the number of which is determined by 'numPCs')
%       .R2_Mbest_kD
%        -> Quality of map from x to dx provided by Mbest using all dims
%
%    PhaseData - Cell array where each cell element contains struct
%                 referring to phase information regarding angle between
%                 the rate of change (for trajectory in that plane) and the
%                 actual position of the trajectory itself in the jPCA
%                 plane (see analyze.jPCA.getPhase)
%
%    fig - (Optional) Figure handle to output figure or array of output
%                       figure handles (depends on settings in `params`)
%                       -> If no figures generated, returns as []
%
%  -- Other Notes --
%
%  1) During preprocessing we FIRST normalize, and then (when doing PCA)
%     subtract the overall mean firing rate (no relationship to the
%     cross-condition mean subtraction).  For new data you must do this
%     in the same order (using ORIGINAL normFactors and mean firing rats)
%
%  2) To get from low-D to high D you must do just the reverse: add back
%     the mean FRs and the multiply by the normFactors:
%
%       Summary.preprocessing.normFactors = normFactors;
%       Summary.preprocessing.meanFReachNeuron = meanFReachNeuron;
%
% See Also: analyze.jPCA.plotRosette, analyze.jPCA.plotPhaseDiff,
%           analyze.jPCA.getPhase, analyze.jPCA.skewSymRegress,
%           analyze.jPCA.skewSymLSEval, analyze.jPCA.getPhase

% % % Parse Input arguments % % % % % %
if nargin < 2
   params = defaults.jPCA('jpca_params');
else
   if isstruct(varargin{1})
      params = varargin{1};
      varargin(1) = [];
   else
      params = defaults.jPCA('jpca_params');
   end
   fn = fieldnames(params);
   for iV = 1:2:numel(varargin)
      iField = ismember(lower(fn),lower(varargin{iV}));
      if sum(iField)==1
         params.(fn{iField}) = varargin{iV+1};
      else
         warning(['JPCA:' mfilename ':BadParameter'],...
            ['\n\t->\t<strong>[JPCA]:</strong> ' ...
            'Unrecognized parameter name: "<strong>%s</strong>"\n'],...
            varargin{iV});
      end
   end
end
% % % % % % % End Input Parsing % % % %


% % Mild Error-Checking % % % % % % % % % % % % % % % % % % % % % % % % % %
% Ensure that the number of PCs is an even value %
if rem(params.numPCs,2)>0
   error(['jPCA:' mfilename ':InvalidParameter'],...
      ['\n\t->\t<strong>[JPCA]:</strong> ' ...
      'Motivation for jPCA is to find <strong>pairs</strong> ' ...
      'of complex-conjugate eigenvectors; therefore, number of '...
      'PCs <strong>must</strong> be even.']);
end

% Ensure that plane2plot is sorted in descending order so that
% highest-variance plot is on top (for convenience) if multiple are
% returned.
params.plane2plot = sort(params.plane2plot,'descend');
% % % % % % % % % % % % % % % % % % % % % % End Error-Checking% % % % % % %

% % Figure out which times to analyze and make masks % %
if isempty(params.analyzeTimes)
   analyzeIndices = true(numel(Data(1).times),1);
else
   analyzeIndices = ismember(round(Data(1).times), round(params.analyzeTimes));
   if size(analyzeIndices,1) == 1
      analyzeIndices = analyzeIndices';  % orientation matters for the repmat below
   end
end

% % Get these variables for convenience % %
numTrials = length(Data); % total number of trials (conditions)
analyzeMask = repmat(analyzeIndices,numTrials,1);  % used to mask bigA
tt = Data(1).times(analyzeIndices); % relative sample times in all trials

% % (m053m716 June-2020): Added "State" indexing fields.               % %
% % -> Main use is for bookkeeping, for example useful to superimpose  % %
% %      behaviorally-related events on trajectories at heterogeneous  % %
% %      indices relative to event onset                               % %
% Check that input Data even contains `tReach` or other metadata %
params = parseMetaTimes(params,Data,tt);

% these are used to take the derivative
bunchOtruth = true(sum(analyzeIndices)-1,1);
maskT1 = repmat( [bunchOtruth;false],numTrials,1);  % skip the last time for each condition
maskT2 = repmat( [false;bunchOtruth],numTrials,1);  % skip the first time for each condition
if sum(analyzeIndices) < params.minTimeSamplesToWarn
   warning(['JPCA:' mfilename ':TooFewSamples'],...
      ['\n\t->\t<strong>[JPCA]:</strong> ' ...
      'Data contains only (%g) sample times!\n' ...
      '\t\t\t(This is unlikely to work very well)\n'],sum(analyzeIndices));
end

% % Make a version of A that has all the data from all the conditions % %
% in doing so, mean subtract and normalize
bigA = vertcat(Data.A);  % append conditions vertically

% note that normalization is done based on ALL the supplied data, not just what will be analyzed
if params.normalize  % normalize (incompletely unless asked otherwise)
   ranges = range(bigA);  % For each neuron, the firing rate range across all conditions and times.
   normFactors = (ranges+params.softenNorm);
   bigA = bsxfun(@times, bigA, 1./normFactors);  % normalize
else
   normFactors = ones(1,size(bigA,2));
end

sumA = 0;
for c = 1:numTrials
   % Get the per-sample, per-channel total rate at each time-sample,
   % applying the normalization or weighting scheme defined above:
   sumA = sumA + bsxfun(@times, Data(c).A, 1./normFactors);
end
% Note this is the same as "cross-trial mean" (by sample) if
% normFactors are ones:
meanA = sumA/numTrials;
bigA = bigA-repmat(meanA,numTrials,1);

% % % Apply traditional PCA % % %
smallA = bigA(analyzeMask,:);
% (m053m716 June-2020: update from `princomp` to `pca`):
[PCvectors,rawScores,~,~,explained,mu] = pca(smallA,'Economy',true);
meanFReachNeuron = mean(smallA,1);
explained_total = cumsum(explained); % For plot purposes and/or estimation

% these are the directions in the high-D space (the PCs themselves)
if isnan(params.threshPC)
   if params.numPCs > size(PCvectors,2)
      error(['JPCA:' mfilename ':InvalidParameter'],...
         ['\n\t->\t<strong>[JPCA]:</strong> More principal components '...
         'were requested than there are dimensions of data\n']);
   end
else % Otherwise, derive # PCs from % explained data
   nPC = find(explained_total > params.threshPC,1,'first');
   if rem(nPC,2) > 0
      if nPC < numel(explained_total)
         nPC = nPC + 1;
      else
         nPC = nPC - 1;
         warning(['JPCA:' mfilename ':SpecificationMismatch'],...
            ['\n\t->\t<strong>[NUMBER OF PCS]:</strong> ' ...
            'Could not retrieve an even number of PCs meeting specified ' ...
            'threshold for reconstructing original data (%g%%)\n'],...
            params.threshPC);
      end
   end
   params.numPCs = nPC;
   params.plane2plot(params.plane2plot > (nPC/2)) = [];
end
% Reduce the total number of PCvectors based on fixed number or threshold
% number of EVEN number of PCs based on % explained threshold:
PCvectors = PCvectors(:,1:params.numPCs);

% % % % Optional: plot stem of PCs % % % %
if ~params.suppressPCstem
   fig = analyze.jPCA.stemPCvariance(explained_total,params);
else
   fig = [];
end

% % % % % % % % % % % % % % % % %
% % % CRITICAL STEP UP NEXT % % %
% % % % % % % % % % % % % % % % %

% This is what we are really after: the projection of the data onto the PCs
scores = rawScores(:,1:params.numPCs);  % cut down to the right number of PCs

% % Some extra steps
% %
% % projection of all the data
% % princomp subtracts off means automatically so we need to do that too when projecting all the data
% % bigAred = bsxfun(@minus, bigA, mean(smallA)) * PCvectors(:,1:params.numPCs); % projection of all the data (not just teh analyzed chunk) into the low-D space.
% % need to subtract off the mean for smallA, as this was done automatically when computing the PC
% % scores from smallA, and we want that projection to match this one.

% projection of the mean
meanAred = bsxfun(@minus, meanA, mean(smallA)) * PCvectors(:,1:params.numPCs);  % projection of the across-cond mean (which we subtracted out) into the low-D space.

% will need this later for some indexing
nSamples = size(scores,1)/numTrials;

% % Get M & Mskew % %
% Compute dState, and use that to find the best M and Mskew that predict
% dState (using "preState", which is simply the "minuend").

% We are interested in the eqn that explains the derivative as a function
% of the state: dState = M*preState

% Apply masks to get and later times within each condition
dState = scores(maskT2,:) - scores(maskT1,:);
% For convenience, keep the "state" in its own variable (we will use the
% average of the two masks, since each difference estimate is most accurate
% for the point halfway between the two sets of samples)
State = (scores(maskT1,:) + scores(maskT2,:)) ./ 2;

% First compute M_best. Note that we mean "best" in the least-squares
% sense; therefore we can solve this using standard least-squares
% regression, which we can implement in MATLAB via `mldivide`, which is
% numerically stable due to use of QR decomposition

M = (State \ dState)';  % M takes the state and provides a fit to dState
% Note on sizes of matrices:
% dState' and preState' have time running horizontally and state dimension running vertically
% We are thus solving for dx = Mx.
% M is a matrix that takes a column state vector and gives the derivative

% now compute Mskew using John's method
% Mskew expects time to run vertically, transpose result so Mskew in the same format as M
% (that is, Mskew will transform a column state vector into dx)
Mskew = analyze.jPCA.skewSymRegress(dState,State)';  % this is the best Mskew for the same equation

% % Decompose Mskew to get the jPCs % %

% get the eigenvalues and eigenvectors
[V,D] = eig(Mskew); % V are the eigenvectors, D contains the eigenvalues
lambda = diag(D); % eigenvalues

% Eigenvalues are usually in order, but not always.
% We want the ones with the largest imaginary component!
[~,sortIndices] = sort(abs(lambda),1,'descend');
lambda = lambda(sortIndices);  % reorder the eigenvalues
explained_skew = 100 * (abs(lambda) / sum(abs(lambda)));
lambda = imag(lambda);  % get rid of any tiny real part

V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)

% Eigenvalues will be displayed to confirm that everything is working
% unless we are asked not to output text
if ~params.suppressText
   fprintf(1,'<strong>[%s::%s::Day-%02d]</strong>  ',...
      Data(1).AnimalID,Data(1).Alignment,Data(1).PostOpDay);
   fprintf(1,'Eigenvalues of M (<strong>skew</strong>): \n');
   for i = 1:length(lambda)
      if (lambda(i) > 0)
         fprintf('                  %1.3fi', lambda(i)*100);
      else
         fprintf('     %1.3fi (%3.2f%%)\n', lambda(i)*100, ...
            sum(explained_skew([i,i-1])));
      end
   end
end

% % Recover pairs of complex conjugate eigenvectors (jPC planes) % %
jPCs = zeros(size(V));
tPlan = params.(params.planStateEvent).';
fcn = @(D,tKeep)analyze.jPCA.recover_align_index(D,tKeep);
planSamples = arrayfun(fcn,Data,tPlan) + 0:nSamples:(numTrials-1)*nSamples;
planSamples = planSamples(~isnan(planSamples));
for pair = 1:params.numPCs/2
   vi1 = 1+2*(pair-1);
   vi2 = 2*pair;
   
   VconjPair = V(:,[vi1,vi2]);  % a conjugate pair of eigenvectors
   evConjPair = lambda([vi1,vi2]); % and their eigenvalues
   VconjPair = analyze.jPCA.getRealVs(VconjPair,evConjPair,scores,planSamples);
   
   jPCs(:,[vi1,vi2]) = VconjPair;
end



% % Reproject data using recovered jPCs % %
proj = scores * jPCs; %
crossCondMeanAllTimes = meanAred * jPCs; % Offsets to recover original using jPCs

% Do some annoying output formatting.
% Put things back so we have one entry per condition
index1 = 1;
Projection = initProjStruct(Data);

for c = 1:numTrials
   index1b = index1 + nSamples -1;  % we will go from index1 to this point
   Projection(c).proj = proj(index1:index1b,:); %#ok<*AGROW>
   Projection(c).state = scores(index1:index1b,:);
   Projection(c).times = Data(1).times(analyzeIndices);
   index1 = index1+nSamples;
end

% Do indexing on individual array elements (trials) %
keepFcn = @(structArray,keepTime)recover_state_index(structArray,keepTime,tt);
[reachState,reachIndex] = arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tReach);
reachState = cell2mat(reachState.');
[graspState,graspIndex] = arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tGrasp);
graspState = cell2mat(graspState.');
[completeState,completeIndex] = arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tComplete);
completeState = cell2mat(completeState.');
[supportState,supportIndex] = arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tSupport);
supportState = cell2mat(supportState.');
[Projection.reachIndex] = deal(reachIndex{:});
[Projection.graspIndex] = deal(graspIndex{:});
[Projection.completeIndex] = deal(completeIndex{:});
[Projection.supportIndex] = deal(supportIndex{:});

% % % SUMMARY STATS % % %
% % Compute R^2 for the fit provided by M (Mbest) and Mskew % %
% Notes:
%  -> This step obtains the `fit error` (distribution of residuals from
%        reprojecting using Mbest and Mskew)
%  -> Once the residual fits are estimated R^2 is computed by taking the
%        difference between the variance
e = reshape(explained./100,1,numel(explained));
pc_vec = 1:params.numPCs;
SS_all = recover_explained_variance(State,dState,M,Mskew,e,pc_vec);
SS_all.explained = SS_all.RSS.Mskew .* e(pc_vec);

% % (Optional): Report "High Dims" % reconstruction % %
if ~params.suppressText
   fprintf(1,'\t--------- | --------------- | ----------------------\n');
   fprintf(1,'\t(Mapping) |');
   fprintf(1,'      <strong>Dims</strong>       |');
   fprintf(1,' [%% Variance Explained]\n');
   fprintf(1,'\t--------- | --------------- | ----------------------\n');
   fprintf(1,'\t (<strong>Best</strong> M) | ');
   fprintf(1,'   <strong>All (%2d)</strong>     |  ',params.numPCs);
   fprintf(1,'[%1.2f]\n', sum(SS_all.RSS.Mbest .* e(pc_vec)));
   fprintf(1,'\t (<strong>Skew</strong> M) | ');
   fprintf(1,'   <strong>All (%2d)</strong>     |  ',params.numPCs);
   fprintf(1,'[%1.2f] <<------\n', sum(SS_all.explained(pc_vec)));
end

% % Compute variance captured by the jPCs % %
origVar = sum(sum( bsxfun(@minus, smallA, mean(smallA)).^2));
varCaptEachJPC = sum((scores*jPCs).^2) / origVar;
varCaptEachPlane = reshape(varCaptEachJPC, 2, params.numPCs/2);
varCaptEachPlane = sum(varCaptEachPlane,1);
if strcmp(params.rankType, 'varCapt')
   [~,sortIndices] = sort(varCaptEachPlane,'descend');
   sortIndices_jPCs = [(sortIndices-1).*2+1;sortIndices.*2];
   sortIndices_jPCs = (sortIndices_jPCs(:)).';
else
   sortIndices = 1:numel(varCaptEachPlane/2);
   sortIndices_jPCs = 1:params.numPCs;
end

iTop = find(ismember(sortIndices_jPCs,[1,2]));
SS_2D = recover_explained_variance(State,dState,M,Mskew,e,iTop);
SS_2D.explained = SS_2D.RSS.Mskew .* e(pc_vec(iTop));

% % (Optional): Report "High Dims" % reconstruction % %
if ~params.suppressText
   fprintf(1,'\t (<strong>Best</strong> M) | ');
   fprintf(1,'<strong>Top-2 (%7s)</strong> |  ',params.rankType);
   fprintf(1,'[%1.2f]\n', sum(SS_2D.RSS.Mbest .* e(pc_vec(iTop))));
   fprintf(1,'\t (<strong>Skew</strong> M) | ');
   fprintf(1,'<strong>Top-2 (%7s)</strong> |  ',params.rankType);
   fprintf(1,'[%1.2f] <<------\n', sum(SS_2D.RSS.Mskew .* SS_2D.explained));
end

% % (Optional): plot the rosette(s) to visualize trajectories % %
vc = varCaptEachPlane;
% If figures are to be exported, get those parameters now %
if params.batchExportFigs
   [figDir,rosetteDir,rosetteExpr,phaseDir,phaseExpr] = defaults.files(...
      'jpca_fig_folder','jpca_rosettes_folder','jpca_rosettes_fname_expr',...
      'jpca_phase_folder','jpca_phase_fname_expr' ...
      );
   rosetteDir = fullfile(figDir,rosetteDir);
   phaseDir = fullfile(figDir,phaseDir);
   if exist(rosetteDir,'dir')==0
      mkdir(rosetteDir);
   end
   if exist(phaseDir,'dir')==0
      mkdir(phaseDir);
   end
end
RosetteProj = cell(1,max(params.plane2plot));
if (~params.suppressRosettes) || (params.batchExportFigs)
   for jPCplane = params.plane2plot
      iSort = sortIndices(jPCplane);
      if ~isnan(varCaptEachPlane(iSort)) && (vc(iSort) > 1e-9)
         p = analyze.jPCA.setRosetteParams(...
            'WhichPair',jPCplane,'VarCapt',vc(iSort),...
            'batchExportFigs',params.batchExportFigs,...
            'Alignment',params.Alignment,...
            'Animal',params.Animal,...
            'Day',params.Day,...
            'markEachMetaEvent',params.markEachMetaEvent);
         [thisFig,RosetteProj{jPCplane}] = ...
            analyze.jPCA.plotRosette(Projection,p);
         if params.batchExportFigs
            f = sprintf(rosetteExpr,...
               params.Animal,params.Alignment,params.Day,jPCplane);
            analyze.jPCA.printFigs(thisFig,rosetteDir,f);
         else
            fig = [fig; thisFig];
         end
      end
   end
end

% % Analysis of whether things really look like rotations (makes plots) % %
circStats = cell(size(params.plane2plot));
PhaseData = cell(1,max(params.plane2plot));
for jPCplane = params.plane2plot
   % % Compute phaseData to be plotted % %
   % Notes:
   % -> Kept as a separate function from `plotPhaseDiff` so that it can be
   %     referenced using the `Projection` output later (if needed)
   PhaseData{jPCplane} = analyze.jPCA.getPhase(...
      Projection,jPCplane,params.wlen,params.S);
   
   % % Optional: plot the histogram of phase angle differences % %
   % Notes:
   %  -> 'params' is just what the user passed
   %  -> if suppressHistograms == false, plots are suppressed
   [circStats{jPCplane},thisFig] = analyze.jPCA.plotPhaseDiff(...
      PhaseData{jPCplane},jPCplane,params);
   if params.batchExportFigs
      f = sprintf(phaseExpr,...
         params.Animal,params.Alignment,params.Day,jPCplane);
      analyze.jPCA.printFigs(thisFig,phaseDir,f);
   else
      fig = [fig; thisFig];
   end
end

% % Make the summary output structure % %
Summary.numTrials = numTrials;
Summary.times = Projection(1).times;
Summary.jPCs = jPCs;
Summary.PCA.vectors = PCvectors;
Summary.PCA.mu = mu;
Summary.PCA.explained = explained;
Summary.PCA.scores = rawScores;
Summary.jPCs_highD = PCvectors * jPCs;
Summary.varCaptEachJPC = varCaptEachJPC;
Summary.varCaptEachPlane = varCaptEachPlane;
Summary.sortIndices = sortIndices;
Summary.sortIndices_jPCs = sortIndices_jPCs;
Summary.reachState = reachState;
Summary.graspState = graspState;
Summary.completeState = completeState;
Summary.supportState = supportState;
% (m053m716, CPL-specific) "Success" or "Failure" among condition labels
Summary.Mbest = M;
Summary.Mskew = Mskew;
Summary.SS.all = SS_all;
Summary.SS.top = SS_2D;
% Summary.fitErrorM = SE_Mbest;
% Summary.fitErrorMskew = SE_Mskew;
% Summary.R2_Mskew = RSS_Mskew;
% Summary.R2_Mbest = RSS_Mbest;
% Summary.R2_Mskew_err = R2_Mskew_err;
% Summary.R2_Mbest_err = R2_Mbest_err;
Summary.circStats = circStats;
Summary.RosetteProj = RosetteProj;
Summary.crossCondMean = crossCondMeanAllTimes(analyzeIndices,:);
Summary.crossCondMeanAllTimes = crossCondMeanAllTimes;
% You should first normalize and then mean subtract using this
% (the original) mean. Conversely, to come back out, you must add the mean
% back on and then MULTIPLY by the normFactors to undo the normalization:
Summary.preprocessing.meanFReachNeuron = meanFReachNeuron;
% Used for projecting new data from the same neurons into the jPC space (in
% case that `normFactors` are non-ones):
Summary.preprocessing.normFactors = normFactors;
Summary.params = params;

utils.addHelperRepos();
sounds__.play('pop',1.2,-10);
fprintf(1,'\n\t->\t<strong>jPCA</strong> projections recovered\n');

   function Projection = initProjStruct(Data)
      %INITPROJSTRUCT Initialize `Projection` (output) array struct
      %
      % Projection = initProjStruct(numTrials);
      %
      % Inputs
      %  Data       - Input data array struct where trials (conditions)
      %                 correspond to each array element
      %
      % Output
      %  Projection - Output array struct where each array element
      %                 corresponds to data and metadata from a single
      %                 trial/condition.
      
      iVal = cell(1,numel(Data));
      Projection = struct(...
         'AnimalID',iVal,...
         'Trial_ID',iVal,...
         'Alignment',iVal,...
         'PostOpDay',iVal,...
         'Group',iVal,...
         'Outcome',iVal,...
         'Condition',iVal,...
         'Duration',iVal,...
         'reachIndex',iVal,...
         'graspIndex',iVal,...
         'completeIndex',iVal,...
         'supportIndex',iVal,...
         'times',iVal,...
         'proj',iVal,...
         'state',iVal,...
         'proj_rot',iVal ...
         );
      [Projection.Trial_ID] = deal(Data.Trial_ID);
      [Projection.AnimalID] = deal(Data.AnimalID);
      [Projection.Alignment] = deal(Data.Alignment);
      [Projection.Outcome] = deal(Data.Outcome);
      [Projection.PostOpDay] = deal(Data.PostOpDay);
      [Projection.Group] = deal(Data.Group);
      [Projection.Duration] = deal(Data.Duration);
      outcome = [Projection.Outcome] - 1; % 0: Unsuccessful; 1: Successful
      condition = num2cell([Projection.PostOpDay] * 2 + outcome);
      [Projection.Condition] = deal(condition{:});
   end

   function params = parseMetaTimes(params,Data,trialTimes)
      %PARSEMETATIMES  Parse timestamp metadata within-trials
      %
      % params = parseMetaTimes(params,Data);
      %
      % Inputs
      %  params     - `defaults.jPCA('jpca_params');` parameters structure
      %  Data       - Main data input struct array where each array element
      %                 corresponds to a single trial (condition)
      %  trialTimes - The corresponding "label" of each timestep in Data
      %
      % Output
      %  params     - Updated parameters struct, with new fields
      %                 corresponding to the times of specifically tagged
      %                 metadata behavioral events to be added to the final
      %                 `Projection` output
      
      if nargin < 3
         trialTimes = Data(1).times;
      end
      Data = Data.'; % This is a fix from old code
      if isnan(params.tReach(1))
         if isfield(Data,'tReach')
            params.tReach = [Data.tReach];
         else
            params.tReach = ones(size(Data)).*trialTimes(1);
         end
      elseif numel(params.tComplete)~=numel(Data)
         params.tComplete = ones(size(Data)).*params.tComplete;
      end
      
      if isnan(params.tGrasp(1))
         if isfield(Data,'tGrasp')
            params.tGrasp = [Data.tGrasp];
         else
            params.tGrasp = ones(size(Data)).*trialTimes(1);
         end
      elseif numel(params.tComplete)~=numel(Data)
         params.tComplete = ones(size(Data)).*params.tComplete;
      end
      
      if isnan(params.tSupport(1))
         if isfield(Data,'tSupport')
            params.tSupport = [Data.tSupport];
         else
            params.tSupport = ones(size(Data)).*trialTimes(1);
         end
      elseif numel(params.tComplete)~=numel(Data)
         params.tComplete = ones(size(Data)).*params.tComplete;
      end
      
      if isnan(params.tComplete(1))
         if isfield(Data,'tComplete')
            params.tComplete = [Data.tComplete];
         else
            params.tComplete = ones(size(Data)).*trialTimes(end);
         end
      elseif numel(params.tComplete)~=numel(Data)
         params.tComplete = ones(size(Data)).*params.tComplete;
      end
      
      % % Get labeling metadata from data input % %
      if isempty(params.Animal)
         params.Animal = Data(1).AnimalID;
      end
      if isempty(params.Alignment)
         params.Alignment = Data(1).Alignment;
      end
      if isempty(params.Day)
         params.Day = Data(1).PostOpDay;
      end
   end

   function [c,keepIndex] = recover_state_index(projArray,keepTime,t)
      %RECOVER_STATE_INDEX  Recovers "state" index of certain time
      %
      %  c = recover_state_index(projArray,keepTime,t);
      %
      %  Inputs
      %     projArray - Array of projection data (`Projection` struct)
      %     keepTime  - Time (ms) to keep
      %     t         - Vector of comparison trials (sample times; rows)
      %
      %  Output
      %     c         - Cell array that is the "State" at that trial
      %                    instant corresponding to `keepTime`
      %
      %     keepIndex - Index corresponding to timepoint of `c`
      
      if isnan(keepTime) || isinf(keepTime)
         keepIndex = nan;
         c = {nan(1,size(projArray.proj,2))};
      else
         [~,keepIndex] = min(abs(t-keepTime));
         c = {projArray.proj(keepIndex,:)};
      end
      keepIndex = {keepIndex};
   end

   function SS = recover_explained_variance(State,dState,M,Mskew,e,dims)
      %RECOVER_EXPLAINED_VARIANCE Return struct with % explained var, etc.
      %
      %  SS = recover_explained_variance(State,dState,M,Mskew,e,dims);
      %
      %  Inputs
      %     State    - Matrix of "X" data (the independent variables)
      %     dState   - Matrix of "Y" data (dependent variables; derivative)
      %     M        - Matrix recovered by LS optimal regression
      %     Mskew    - Matrix recovered by LS optimal regression under
      %                 constraint that transformation matrix is
      %                 skew-symmetric (and therefore has pairs of
      %                 complex-conjugate eigenvalues, corresponding to
      %                 "rotatory" subspace projections).
      %     e        - Proportion (0 - 1) of original data explained by
      %                    each column of `State`
      %     dims     - Indices of dimensions (M) to use
      %
      %  Output
      %     SS       - Struct with fields corresponding to sums of squares
      %                 and square error etc.
      
      
      
      if nargin < 6
         dims = 1:size(State,2);
      end
      
      % Get the dimensions to estimate this on
      rState = State(:,dims);
      rdState = dState(:,dims);
      
      % Get the percent explained based on eigenvalues of transform
      % matrices:
      [~,D_m] = eig(M);
      M_explained = cumsum(diag(abs(D_m)) ./ sum(diag(abs(D_m))));
      [~,D_mskew] = eig(Mskew);
      Mskew_explained = cumsum(diag(abs(D_mskew)) ./ sum(diag(abs(D_mskew))));
      
      % Initialize output data struct
      SS = struct(...
         'info',struct(...
            'dims',dims,...
            'M',M,...
            'M_explained',M_explained,...
            'Mskew',Mskew, ... % Return full transforms, `dims` indicates index
            'Mskew_explained',Mskew_explained) ...
         );
      
      % Make M and Mskew in lower dims (less indexing notation):
      M = M(:,dims);
      Mskew = M(:,dims);
      
      % Mean-Square terms
      SS.MS.State  = (mean(rState,2)  - rState).^2;
      SS.MS.dState = (mean(rdState,2) - rdState).^2;
      SS.MS.orig   = (mean(rdState,2) - rdState) .* ...
                     (mean(rState,2) - rState);
      SS.MS.Mbest  = (mean(rdState,2) - rdState) .* ...
                     (mean(State * M,2) - State*M);
      SS.MS.Mskew  = (mean(rdState,2) - rdState) .* ...
                     (mean(State * Mskew,2) - State*Mskew);
      
      % Compute square-error terms
      SS.ESS.Mbest  = (mean(rdState,2) - State * M).^2;
      SS.ESS.Mskew  = (mean(rdState,2) - State * Mskew).^2;
      
      % Compute total sum-of-squares
      SS.TSS.State  = sum(SS.MS.State, 1);
      SS.TSS.dState = sum(SS.MS.dState,1);
      SS.TSS.orig   = sum(SS.MS.orig  ,1);
%       SS.TSS.Mbest  = sum(SS.MS.Mbest,1);
%       SS.TSS.Mskew  = sum(SS.MS.Mskew,1);
      
      % SSE_Mbest_kd = sum(ESS_Mbest_kd,1);
      % SSE_Mskew_kd = sum(ESS_Mskew_kd,1);
      SS.RSS.Mbest = mean(SS.TSS.dState - SS.ESS.Mbest,1);
      SS.RSS.Mskew = mean(SS.TSS.dState - SS.ESS.Mskew,1);

      % Total sum-of-squares of dependent variable scales this.
      % If the original covariance is equal to the new, 
      %  then we've explained nothing!
      % -> Normalize each estimate so that the cumulative sum becomes 1
      SS.RSS.orig  = SS.TSS.dState .* ...
         (1 - (SS.TSS.orig ./ (SS.TSS.dState .* SS.TSS.State))); 
%       SS.RSS.Mbest = ...
%          (1 - (SS.TSS.orig ./  (SS.TSS.Mbest .* SS.TSS.State))) .* ...
%          M_explained;
%       SS.RSS.Mskew = 1 - (SS.TSS.orig ./  (SS.TSS.Mskew .* SS.TSS.State)) ...
%          .* Mskew_explained; 
   end

end





