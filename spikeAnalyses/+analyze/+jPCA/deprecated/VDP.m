function [Projection,Summary,PhaseData,fig] = VDP(Data,varargin)
%VDP Recover Van der Pol's subspace projections from spike rate time-series
%
% [Projection,Summary] = analyze.jPCA.VDP(Data);
% [Projection,Summary,PhaseData,fig] = analyze.jPCA.VDP(Data,params);
% [__] = analyze.jPCA.VDP(Data,'param1Name',param1Val,...)
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
%       .PCA -> Struct with original PCA info
%       .SS  -> Struct with projection matrix and associated statistics
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
            ['\n\t->\t<strong>[VDP]:</strong> ' ...
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
nAnalyze = sum(analyzeIndices);
mask1T1 = repmat( [true(nAnalyze-1,1);false],numTrials,1);  % skip the last time for each condition
mask1T2 = repmat( [false;true(nAnalyze-1,1)],numTrials,1);  % skip the first time for each condition
mask2T1 = repmat( [true(nAnalyze-2,1);false],numTrials,1);
mask2T2 = repmat( [false;true(nAnalyze-2,1)],numTrials,1);
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
   else
      params.plane2plot(params.plane2plot > (params.numPCs/2)) = [];
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

% % % % % % % % % % % % % % % % %
% % % CRITICAL STEP UP NEXT % % %
% % % % % % % % % % % % % % % % %

% This is what we are really after: the projection of the data onto the PCs
scores = rawScores(:,1:params.numPCs);  % cut down to the right number of PCs
et = explained_total(params.numPCs);    % For reference later (% original data explained by PCs selected)
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

% % Recover mu % %
% We need to bound the input so our expression is numerically stable. If we
% divide by the maximum value of scores, plus some error factor epsilon to
% prevent the denominator going to zero when x == 1.
% scores = scores ./ max(abs(scores),[],1);

% Get approximation for dt
dt = mode(diff(tt)) * 1e-3; % Convert to seconds
% Apply masks to get and later times within each condition
dX = (scores(mask1T2,:) - scores(mask1T1,:)) ./ dt;
d2X = (dX(mask2T2,:) - dX(mask2T1,:)) ./ dt;
dX = (dX(mask2T2,:) + dX(mask2T1,:)) ./ 2;
X = scores(mask1T2 & mask1T1,:);
State = (d2X + X)./(1 - X.^2);

iStable = 1-abs(X) > params.epsilon; % Remove these values from regression

% First compute M_best. Note that we mean "best" in the least-squares
% sense; therefore we can solve this using standard least-squares
% regression, which we can implement in MATLAB via `mldivide`, which is
% numerically stable due to use of QR decomposition

M = (State(all(iStable,2),:) \ dX(all(iStable,2),:))';  % M takes the state and provides a fit to dState
% Note on sizes of matrices:
% dState' and preState' have time running horizontally and state dimension running vertically
% We are thus solving for dx = Mx.
% M is a matrix that takes a column state vector and gives the derivative

% % % Get eigenvalues of both projection matrices % % %
% % Decompose Mbest to get "best" system characterization % %
% get the eigenvalues and eigenvectors
[V,D] = eig(M); % V are the eigenvectors, D contains the eigenvalues
lambda_best = diag(D); % eigenvalues

% Eigenvalues are usually in order, but not always.
% We want the ones with the largest imaginary component!
[~,sortIndices] = sort(abs(lambda_best),1,'descend');
lambda_best = lambda_best(sortIndices);  % reorder the eigenvalues
explained_best = (abs(lambda_best) / sum(abs(lambda_best))) .* et;
lambda_i = imag(lambda_best);  % get rid of any tiny real part
lambda_r = real(lambda_best);

V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)

% Eigenvalues will be displayed to confirm that everything is working
% unless we are asked not to output text
if ~params.suppressText
   fprintf(1,'\n\t<strong>BEGIN</strong> -> [%s::%s::Day-%02d (%s)]\n',...
      Data(1).AnimalID,Data(1).Alignment,Data(1).PostOpDay,Data(1).Area);
   fprintf(1,'\t\t\t----------------------------------\n');
   fprintf(1,'\t\t\tEigenvalues of <strong>best</strong> transformation\n');
   fprintf(1,'\t\t\t----------------------------------\n');
   for ii = 1:length(lambda_i)
      if rem(ii,2) > 0
         fprintf('\t\t->\t%7.4f%+7.4fi',lambda_r(ii),lambda_i(ii));
      else
         fprintf('\t%7.4f%+7.4fi (%4.2f%%)\n',lambda_r(ii),lambda_i(ii), ...
            sum(explained_best([ii,ii-1])));
      end
   end
end

% % Recover pairs of complex conjugate eigenvectors (jPC planes) % %
vdpPCs = zeros(size(V));
tPlan = params.(params.planStateEvent).';
fcn = @(D,tKeep)analyze.jPCA.recover_align_index(D,tKeep);
planSamples = arrayfun(fcn,Data,tPlan) + 0:nSamples:(numTrials-1)*nSamples;
planSamples = planSamples(~isnan(planSamples));
for pair = 1:params.numPCs/2
   vi1 = 1+2*(pair-1);
   vi2 = 2*pair;
   
   VconjPair = V(:,[vi1,vi2]);  % a conjugate pair of eigenvectors
   evConjPair = lambda_i([vi1,vi2]); % and their eigenvalues
   VconjPair = analyze.jPCA.getRealVs(VconjPair,evConjPair,scores,planSamples);
   
   vdpPCs(:,[vi1,vi2]) = VconjPair;
end

% % Reproject data using recovered jPCs % %
% proj = normScores * vdpPCs; %
% crossCondMeanAllTimes = meanAred * vdpPCs; % Offsets to recover original using jPCs
proj = State * M;
crossCondMeanAllTimes = meanAred * M;

% Do some annoying output formatting.
% Put things back so we have one entry per condition
index1 = 1;
index2 = 1;
Projection = initProjStruct(Data);

for c = 1:numTrials
   index1b = index1 + nSamples -1;  % we will go from index1 to this point
   index2b = index2 + nSamples -3; 
   Projection(c).proj = proj(index2:index2b,:); %#ok<*AGROW>
   Projection(c).scores = scores(index1:index1b,:);
   Projection(c).state = State(index2:index2b,:);
   Projection(c).X = X(index2:index2b,:);
   Projection(c).dX = dX(index2:index2b,:);
   Projection(c).d2X = d2X(index2:index2b,:);
   Projection(c).times = Data(1).times(analyzeIndices);
   Projection(c).m = (Projection(c).state \ Projection(c).dX)';
   [Projection(c).M,Projection(c).rot] = rotatefactors(Projection(c).m,'Method','procrustes','Target',M);
   Projection(c).mu = (Projection(c).state ./ Projection(c).dX);
   Projection(c).proj_rot = Projection(c).state * Projection(c).m * Projection(c).rot;
   index1 = index1+nSamples;
   index2 = index2+nSamples-2;
end

% % % % Optional: plot stem of PCs % % % %
if ~params.suppressPCstem
   fig = analyze.jPCA.stemPCvariance(explained_total,Projection,params);
else
   fig = [];
end

% Do indexing on individual array elements (trials) %
keepFcn = @(structArray,keepTime)recover_state_index(structArray,keepTime,tt(2:(end-1)));
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

% % % Recover all-dimensions reconstruction stats % % %
pc_vec = 1:params.numPCs;
SS = struct('all',struct,'top',struct);
SS.all = recover_explained_variance(State,dX,M,et,pc_vec,params.rankType);

% % % Recover top-dimensions reconstruction stats % % %
topVectors = SS.all.explained.sort.vector(1:2);
SS.top = recover_explained_variance(State,dX,M,et,topVectors);

% % (Optional): plot the rosette(s) to visualize trajectories % %
switch lower(params.rankType)
   case 'eig'
      vc = SS.all.explained.plane.eig;
   case 'varcapt'
      vc = SS.all.explained.plane.R2;
end
sortIndices = SS.all.explained.sort.plane;

% % % (Optional): generate & export trajectory rosette plots % % %
if params.batchExportFigs
   [figDir,rosetteDir,rosetteExpr,phaseDir] = defaults.files(...
      'jpca_fig_folder','jpca_rosettes_folder','jpca_rosettes_fname_expr',...
      'jpca_phase_folder' ...
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
   for vdpPlane = params.plane2plot
      iSort = sortIndices(vdpPlane);
      if ~isnan(vc(iSort)) && (vc(iSort) > 1e-9)
         p = analyze.jPCA.setRosetteParams(...
            'WhichPair',vdpPlane,'VarCapt',vc(iSort),...
            'batchExportFigs',params.batchExportFigs,...
            'Alignment',params.Alignment,...
            'Animal',params.Animal,...
            'Area',params.Area,...
            'Day',params.Day,...
            'markEachMetaEvent',params.markEachMetaEvent);
         [thisFig,RosetteProj{vdpPlane}] = ...
            analyze.jPCA.plotRosette(Projection,p);
         if params.batchExportFigs
            f = sprintf(rosetteExpr,...
               params.Animal,params.Alignment,params.Day,vdpPlane);
            analyze.jPCA.printFigs(thisFig,rosetteDir,f);
         else
            fig = [fig; thisFig];
         end
      end
   end
end

% % (Optional): Report % reconstruction % %
if ~params.suppressText
   fprintf(1,'\n\n\t--------- | --------------- | ------------------------ | --------------------\n');
   fprintf(1,'\t(Mapping) |');
   fprintf(1,'      <strong>Dims</strong>       |');
   fprintf(1,' [%% Eigenspace Explained] |');
   fprintf(1,' %% Variance Explained\n');
   fprintf(1,'\t--------- | --------------- | ------------------------ | --------------------\n');
   fprintf(1,'\t (<strong>Best</strong> M) | ');
   fprintf(1,' <strong>All  (  %3d  )</strong> |  ',params.numPCs);
   fprintf(1,'       [%6.2f%%]        | ', sum(SS.all.explained.eig));
   fprintf(1,' %10.2f%%\n', sum(SS.all.explained.R2));
   fprintf(1,'\t (<strong>Best</strong> M) | ');
   fprintf(1,'<strong>Top-2 (%7s)</strong> |  ',params.rankType);
   fprintf(1,'       [%6.2f%%]        | ', sum(SS.top.explained.eig));
   fprintf(1,' %10.2f%%\n', sum(SS.top.explained.R2));
end

% % Make the summary output structure % %
Summary.numTrials = numTrials;
Summary.times = Projection(1).times;
Summary.TotalVarExplainedPCs = et;
Summary.PCA.vectors = PCvectors;
Summary.PCA.mu = mu;
Summary.PCA.explained = explained;
Summary.PCA.scores = rawScores;
Summary.reachState = reachState;
Summary.graspState = graspState;
Summary.completeState = completeState;
Summary.supportState = supportState;
% (m053m716, CPL-specific) "Success" or "Failure" among condition labels
Summary.best = struct('M',M,'lambda',lambda_best);
Summary.SS = SS;
% Summary.circStats = circStats;
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
if ~params.suppressText
   fprintf(1,'\n\t\t\t\t[%s::%s::Day-%02d (%s)] <- <strong>END JPCA</strong>\n',...
      Data(1).AnimalID,Data(1).Alignment,Data(1).PostOpDay,Data(1).Area);
end

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
         'Area',iVal,...
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
      [Projection.Area] = deal(Data.Area);
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
      if isempty(params.Area)
         params.Area = Data(1).Area;
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

   function SS = recover_explained_variance(State,dState,M,e,dims,rankType)
      %RECOVER_EXPLAINED_VARIANCE Return struct with % explained var, etc.
      %
      %  SS = recover_explained_variance(State,dState,M,Mskew,e,dims);
      %
      %  Inputs
      %     State    - Matrix of "X" data (the independent variables)
      %     dState   - Matrix of "Y" data (dependent variables; derivative)
      %     M        - Matrix recovered by LS optimal regression
      %     e        - Proportion (0 - 1) of original data explained by
      %                 PCs that were used for jPCA estimate
      %     bestDims - Indices of dimensions to use for Mbest
      %
      %  Output
      %     SS       - Struct with fields corresponding to sums of squares
      %                 and square error etc.
      
      
      
      if nargin < 5
         dims = 1:size(State,2);
      end
      
      % Get the percent explained based on eigenvalues of transform
      % matrices:
      [Vm,Dm] = eig(M);
      M_explained = diag(abs(Dm)) ./ sum(diag(abs(Dm)));
      
      % Initialize output data struct
      SS = struct(...
            'info',struct(...
                  'M',M,...
                  'dims',dims,...
                  'explained',M_explained(dims).',...
                  'V',Vm,...
                  'D',Dm),...
            'TSS',struct, ...    % 
            'RSS',struct, ...    % Residual sum-of-squares
            'explained',struct ...
            );
      
      % Make M and Mskew in lower dims (less indexing notation):
      M = M(:,dims);
      thisProj = State * M;
  
      % Compute total sum-of-squares
      SS.TSS.dState = sum(bsxfun(@minus,dState,mean(dState,1)).^2,1);
      SS.TSS.total  = sum(SS.TSS.dState);
      
      % Compute explained sum-of-squares (sum-of-squares due to regression or SSR)
      SS.ESS   = sum(bsxfun(@minus,thisProj,mean(dState(:,dims),1)).^2,1);
      SS.ESS(SS.ESS > SS.TSS.total) = 0;
      
      % Compute residual sum-of-squares (sum-of-squares due to error or SSE)
      SS.RSS   = sum(bsxfun(@minus,thisProj,dState(:,dims)).^2,1);
      
      % Percent of original "eigenspace" (from eigenvalue magnitudes):
      SS.explained.eig = SS.info.explained .* e;
      
      % Percent reduction in variance using each fit:
      % Note that because we are doing linear regression, .R2 and .FVU
      % should be equivalent for .best, or .skew, as (1 - the other)
      SS.explained.R2 = SS.ESS ./ SS.TSS.total .* 100;
      
      SS.explained.FVU = SS.RSS ./ SS.TSS.total .* 100;
      
      if nargin < 6 % % Do not do any sorting if no `rankType` given % % 
         return;
      end
      
      % % Recover sort indices according to plane sort type % %
      nDim = numel(dims);
      nPlane = nDim/2;
      SS.explained.plane.eig = sum(reshape(SS.explained.eig,2,nPlane),1);
      SS.explained.plane.R2 = sum(reshape(SS.explained.R2,2,nPlane),1);
      if strcmpi(rankType, 'varcapt')
         sortQ = SS.explained.plane.R2;
      else
         sortQ = SS.explained.plane.eig;
      end
      [~,SS.explained.sort.plane] = sort(sortQ,'descend');
      SS.explained.sort.vector = [...
         (SS.explained.sort.plane-1).*2+1;...
          SS.explained.sort.plane.*2];
      SS.explained.sort.vector = (SS.explained.sort.vector(:)).';
   end

end





