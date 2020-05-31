function [Projection, Summary] = jPCA(Data,varargin)
%JPCA Recover rotatory projections from spiking rate time-series
%
% [Projection, Summary] = analyze.jPCA.jPCA(Data);
% [Projection, Summary] = analyze.jPCA.jPCA(Data,params);
% [Projection, Summary] = analyze.jPCA.jPCA(Data,'param1Name',param1Val,...)
%
% OUTPUTS:
%   Projection is a struct with one element per condition.
%   It contains the following fields:
%       .proj           The projection into the 6D jPCA space.
%       .times          Those times that were used
%       .projAllTimes   Pojection of all the data into the jPCs (which were derived from a subset of the data)
%       .allTimes       All the times (exactly the same as Data(1).times)
%       .tradPCAproj    The traditional PCA projection (same times as for 'proj')
%       .tradPCAprojAllTimes   Above but for all times.
%
%   Summary contains the following fields:
%       .jPCs           The jPCs in terms of the PCs (not the full-D space)
%       .PCs            The PCs (each column is a PC, each row a neuron)
%       .jPCs_highD     The jPCs, but in the original high-D space.  This is just PCs * jPCs, and is thus of size neurons x numPCs
%       .varCaptEachJPC The data variance captured by each jPC
%       .varCaptEachPC  The data variance captured by each PC
%       .R2_Mskew_2D    Fit quality (fitting dx with x) provided by Mskew, in the first 2 jPCs.
%       .R2_Mbest_2D    Same for the best M
%       .R2_Mskew_kD    Fit quality (fitting dx with x) provided by Mskew, in all the jPCs (the number of which is set by 'numPCs'.
%       .R2_Mbest_kD    Same for the best M
%
%       There are some other useful currently undocumented 
%       (but often self-explanatory) fields in 'Summary'
%
%  Summary also contains the following, useful for projecting new data 
%  into the jPCA space.  Also useful for getting from what is in 
%  'Projection' back into the high-D land of PSTHs. 
%
%  Note that during preprocessing we FIRST normalize, and then 
%  (when doing PCA) subtract the overall mean firing rate (no relationship 
%  to the cross-condition mean subtraction).  For new data you must do this
%  in the same order (using the ORIGINAL normFactors and mean firing rats.
%  
%  To get from low-D to high D you must do just the reverse: add back the 
%  mean FRs and the multiply by the normFactors.
%
%       .preprocessing.normFactors = normFactors;
%       .preprocessing.meanFReachNeuron = meanFReachNeuron;
%
% INPUTS:
% The input 'Data' needs to be a struct, with one entry per condition.
% For a given condition, Data(c).A should hold the data (e.g. firing rates).
% Each column of A corresponds to a neuron, and each row to a timepoint.
%
% Data(c).times is an optional field.  If you provide it, then
% params.analyzeTimes will be used to select sample indices. If no
% params.analyzeTimes is provided, all samples are used.
%
%  If you don't provide it, a '.times' field
% is created that starts at 1.  'analyzeTimes' then refers to those times.
%
% 'params' is optional, and can contain the following fields:
%   .analyzeTimes  Default is empty; if it's empty all times are used.
%   .numPCs        Default is 6. The number of traditional PCs to use (all jPCs live within this space)
%   .normalize     Default is 'true'.  Whether or not to normalize each neurons response by its FR range.
%   .softenNorm    Default is 10.  Determines how much we undernormalize for low FR neurons.  0 means
%                  complete normalization.  10 means a neuron with FR range of 10 gets mapped to a range of 0.5.
%   .meanSubtract  Default is true:  
%                    -> Whether or not we remove the across-condition mean from each neurons rate.
%   .suppressBWrosettes    if present and true, the black & white rosettes are not plotted
%   .suppressHistograms    if present and true, the blue histograms are not plotted
%   .suppressText          if present and true, no text is output to the command window
%
%  As a note on projecting more data into the same space.  
%  This can be done with the function 'projectNewData'.  
%  However, if you are going to go this route then you should turn OFF 
%  'meanSubtract'. 
%  If you wish to still mean subtract the data you should  do it by hand 
%  yourself.
%  That way you can make a principled decision regarding how to treat the 
%  original data versus the new-to-be-projected data.  
%
%  For example, you may subtract off the mean manually across 108 
%  conditions.  You might then leave out one condition and compute the 
%  jPCA plane (with meanSubtract set to false).
%
%  You could then project the remaining condition into that plane using 
%  'projectNewData'.

% % Get these variables for convenience % %
numTrials = length(Data);
numTimes = size(Data(1).A,1);

% % % Parse Input arguments % % %
if nargin < 2
   params = defaults.jPCA('jpca_params');
else
   if isstruct(varargin{1})
      params = varargin{1};
      varargin(1) = [];
   else
      params = defaults.jPCA('jpca_params');
   end
   for iV = 1:2:numel(varargin)
      params.(varargin{iV}) = varargin{iV+1};
   end
end

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

% In case "conditionLabels" is specified as "outcome" or "outcomes"
if isfield(params,'outcomes')
   params.conditionLabels = params.outcomes;
   params = rmfield(params,'outcomes');
elseif isfield(params,'outcome')
   params.conditionLabels = params.outcome;
   params = rmfield(params,'outcome');
elseif isnan(params.conditionLabels(1))
   fn = fieldnames(Data);
   iField = contains(lower(fn),'outcome');
   if any(iField)
      fnThis = fn{iField};
      params.conditionLabels = [Data.(fnThis)];
   end
end

% do we mean subtract
if length(Data)==1
   params.meanSubtract = false; 
end  % cannot mean subtract if there is only one condition
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
analyzeMask = repmat(analyzeIndices,numTrials,1);  % used to mask bigA
t = Data(1).times(analyzeIndices);

% these are used to take the derivative
bunchOtruth = true(sum(analyzeIndices)-1,1);
maskT1 = repmat( [bunchOtruth;false],numTrials,1);  % skip the last time for each condition
maskT2 = repmat( [false;bunchOtruth],numTrials,1);  % skip the first time for each condition
if sum(analyzeIndices) < params.minTimeSamplesToWarn
   warning([],...
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
   sumA = sumA + bsxfun(@times, Data(c).A, 1./normFactors);  % using the same normalization as above
end
meanA = sumA/numTrials;
if params.meanSubtract  % subtract off the across-condition mean from each neurons response
   bigA = bigA-repmat(meanA,numTrials,1);
end

% % % Apply traditional PCA % % % 
smallA = bigA(analyzeMask,:);
[PCvectors,rawScores] = pca(smallA,'Economy',true);  % apply PCA to the analyzed times
meanFReachNeuron = mean(smallA);  % this will be kept for use by future attempts to project onto the PCs

% these are the directions in the high-D space (the PCs themselves)
if params.numPCs > size(PCvectors,2)
   error(['JPCA:' mfilename ':InvalidParameter'],...
      ['\n\t->\t<strong>[JPCA]:</strong> More principal components '...
       'were requested than there are dimensions of data\n']);
end
PCvectors = PCvectors(:,1:params.numPCs);  % cut down to the right number of PCs

% % % % % % % % % % % % % % % % %
% % % CRITICAL STEP UP NEXT % % %
% % % % % % % % % % % % % % % % %

% This is what we are really after: the projection of the data onto the PCs
Ared = rawScores(:,1:params.numPCs);  % cut down to the right number of PCs

% Some extra steps
%
% projection of all the data
% princomp subtracts off means automatically so we need to do that too when projecting all the data
bigAred = bsxfun(@minus, bigA, mean(smallA)) * PCvectors(:,1:params.numPCs); % projection of all the data (not just teh analyzed chunk) into the low-D space.
% need to subtract off the mean for smallA, as this was done automatically when computing the PC
% scores from smallA, and we want that projection to match this one.

% projection of the mean

meanAred = bsxfun(@minus, meanA, mean(smallA)) * PCvectors(:,1:params.numPCs);  % projection of the across-cond mean (which we subtracted out) into the low-D space.

% will need this later for some indexing
nSamples = size(Ared,1)/numTrials;

% % Get M & Mskew % %
% Compute dState, and use that to find the best M and Mskew that predict 
% dState (using "preState", which is simply the "minuend").

% We are interested in the eqn that explains the derivative as a function 
% of the state: dState = M*preState

% Apply masks to get and later times within each condition
dState = Ared(maskT2,:) - Ared(maskT1,:);
preState = Ared(maskT1,:);  % just for convenience, keep the earlier time in its own variable

% first compute the best M (of any type)
% note, we have converted dState and Ared to have time running horizontally
M = (dState'/preState');  % M takes the state and provides a fit to dState
% Note on sizes of matrices:
% dState' and preState' have time running horizontally and state dimension running vertically
% We are thus solving for dx = Mx.
% M is a matrix that takes a column state vector and gives the derivative

% now compute Mskew using John's method
% Mskew expects time to run vertically, transpose result so Mskew in the same format as M
% (that is, Mskew will transform a column state vector into dx)
Mskew = analyze.jPCA.skewSymRegress(dState,preState)';  % this is the best Mskew for the same equation

% % Decompose Mskew to get the jPCs % %

% get the eigenvalues and eigenvectors
[V,D] = eig(Mskew); % V are the eigenvectors, D contains the eigenvalues
lambda = diag(D); % eigenvalues

% the eigenvalues are usually in order, but not always.  We want the biggest
[~,sortIndices] = sort(abs(lambda),1,'descend');
lambda = lambda(sortIndices);  % reorder the eigenvalues
lambda = imag(lambda);  % get rid of any tiny real part

V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)

% Eigenvalues will be displayed to confirm that everything is working
% unless we are asked not to output text
if ~isfield(params,'suppressText') || ~params.suppressText
   clc;
   disp('eigenvalues of Mskew: ');
   for i = 1:length(lambda)
      if (lambda(i) > 0)
         fprintf('                  %1.3fi', lambda(i));
      else
         fprintf('     %1.3fi \n', lambda(i));
      end
   end
end

jPCs = zeros(size(V));
for pair = 1:params.numPCs/2
   vi1 = 1+2*(pair-1);
   vi2 = 2*pair;
   
   VconjPair = V(:,[vi1,vi2]);  % a conjugate pair of eigenvectors
   evConjPair = lambda([vi1,vi2]); % and their eigenvalues
   VconjPair = analyze.jPCA.getRealVs(VconjPair,evConjPair,Ared,nSamples);
   
   jPCs(:,[vi1,vi2]) = VconjPair;
end
% % Reproject data using recovered jPCs % %
proj = Ared * jPCs;
projAllTimes = bigAred * jPCs;

tradPCA_AllTimes = bsxfun(@minus, bigA, mean(smallA)) * PCvectors;  % mean center in exactly the same way as for the shorter time period.
crossCondMeanAllTimes = meanAred * jPCs;

% Do some annoying output formatting.
% Put things back so we have one entry per condition
index1 = 1;
index2 = 1;
for c = 1:numTrials
   index1b = index1 + nSamples -1;  % we will go from index1 to this point
   index2b = index2 + numTimes -1;  % we will go from index2 to this point
   
   Projection(c).proj = proj(index1:index1b,:); %#ok<*AGROW>
   Projection(c).tradPCAproj = Ared(index1:index1b,:);
   Projection(c).times = Data(1).times(analyzeIndices);
   Projection(c).projAllTimes = projAllTimes(index2:index2b,:);
   Projection(c).tradPCAprojAllTimes = tradPCA_AllTimes(index2:index2b,:);
   Projection(c).allTimes = Data(1).times;
   
   index1 = index1+nSamples;
   index2 = index2+numTimes;
end

% % If zero-centering about some index, do that now % % 
if params.zeroCenters
   % Check if there is a zeroTime
   if ~isnan(params.zeroTime)
      [~,zIndx] = min(abs(Data(1).times-params.zeroTime));
      zIndx = zIndx(1); % If multiple closest, use first
   else
      zIndx = 1; % Otherwise it's just the first sample index
   end
   
   % Iterate, applying this to all trials.
   f = {'proj'};
   fcn = @(pro)analyze.jPCA.zeroCenterPoints(pro,zIndx,f,f);
   Projection = arrayfun(fcn,Projection);
end

% % Add "planState" and "finalState" fields for bookkeeping - MM
keepFcn = @(structArray,keepTime)recover_state_index(structArray,keepTime,t);

if isnan(params.tPlan(1))
   if isfield(Data,'tPlan')
      params.tPlan = [Data.tPlan];
   else
      params.tPlan = ones(size(Projection)).*t(1);
   end
elseif numel(params.tFinal)~=numel(Projection)
   params.tFinal = ones(size(Projection)).*params.tFinal;
end

if isnan(params.tFinal(1))
   if isfield(Data,'tFinal')
      params.tFinal = [Data.tFinal];
   else
      params.tFinal = ones(size(Projection)).*t(end);
   end
elseif numel(params.tFinal)~=numel(Projection)
   params.tFinal = ones(size(Projection)).*params.tFinal;
end

planState = cell2mat(arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tPlan).');
finalState = cell2mat(arrayfun(@(s,tKeep)keepFcn(s,tKeep),Projection,params.tFinal).');

% % % SUMMARY STATS % % %
% % Compute R^2 for the fit provided by M and Mskew % %
% R^2 Full-D
fitErrorM = dState'- M*preState';
fitErrorMskew = dState'- Mskew*preState';
varDState = sum(dState(:).^2);  % original data variance

R2_Mbest_kD = (varDState - sum(fitErrorM(:).^2)) / varDState;  % how much is explained by the overall fit via M
R2_Mskew_kD = (varDState - sum(fitErrorMskew(:).^2)) / varDState;  % how much by is explained via Mskew

% unless asked to not output text
if ~exist('params', 'var') || ~isfield(params,'suppressText') || ~params.suppressText
   fprintf('%% R^2 for Mbest (all %d dims):   %1.2f\n', params.numPCs, R2_Mbest_kD);
   fprintf('%% R^2 for Mskew (all %d dims):   %1.2f  <<---------------\n', params.numPCs, R2_Mskew_kD);
end

% R2 2-D primary jPCA plane
fitErrorM_2D = jPCs(:,1:2)' * fitErrorM;  % error projected into the primary plane
fitErrorMskew_2D = jPCs(:,1:2)' * fitErrorMskew;  % error projected into the primary plane

dState_2D = jPCs(:,1:2)' * dState'; % project dState into the primary plane
varDState_2D = sum(dState_2D(:).^2); % and get its variance

R2_Mbest_2D = (varDState_2D - sum(fitErrorM_2D(:).^2)) / varDState_2D;  % how much is explained by the overall fit via M
R2_Mskew_2D = (varDState_2D - sum(fitErrorMskew_2D(:).^2)) / varDState_2D;  % how much by is explained via Mskew

if ~exist('params', 'var') || ~isfield(params,'suppressText') || ~params.suppressText
   fprintf('%% R^2 for Mbest (primary 2D plane):   %1.2f\n', R2_Mbest_2D);
   fprintf('%% R^2 for Mskew (primary 2D plane):   %1.2f  <<---------------\n', R2_Mskew_2D);
end

% % Compute variance captured by the jPCs % %
origVar = sum(sum( bsxfun(@minus, smallA, mean(smallA)).^2));
varCaptEachPC = sum(Ared.^2) / origVar;  % this equals latent(1:params.numPCs) / sum(latent)
varCaptEachJPC = sum((Ared*jPCs).^2) / origVar;
varCaptEachPlane = reshape(varCaptEachJPC, 2, params.numPCs/2);
varCaptEachPlane = sum(varCaptEachPlane);

% % Make the summary output structure % %
rankType = 'eig';
if isfield(params,'rankType')
   rankType = params.rankType;
end

if strcmp(rankType, 'varCapt')
   [~,sortIndices] = sort(varCaptEachPlane,'descend');
else
   sortIndices = 1:numel(varCaptEachPlane/2);
end

% % Done computing the projections, plot the rosette % %

% do this unless params contains a field 'suppressBWrosettes' that is true
vc = varCaptEachPlane;
if ~isfield(params,'suppressBWrosettes')
   for jPCplane = params.plane2plot
      iSort = sortIndices(jPCplane);
      if ~isnan(varCaptEachPlane(iSort)) && (vc(iSort) > 1e-9)
         analyze.jPCA.plotRosette(Projection,jPCplane,vc(iSort));
      end
   end
elseif ~params.suppressBWrosettes
   for jPCplane = params.plane2plot
      iSort = sortIndices(jPCplane);
      if ~isnan(varCaptEachPlane(iSort)) && (vc(iSort) > 1e-9)
         analyze.jPCA.plotRosette(Projection,jPCplane,vc(iSort));
      end
   end
end

% % Analysis of whether things really look like rotations (makes plots) % %
circStats = cell(size(params.plane2plot));
for jPCplane = params.plane2plot
   phaseData = analyze.jPCA.getPhase(Projection, jPCplane);  % does the key analysis
   % plots the histogram.  'params' is just what the user passed, so plots can be suppressed
   circStats{jPCplane} = analyze.jPCA.plotPhaseDiff(phaseData,jPCplane,params);
end

Summary.numTrials = numTrials;
Summary.times = Projection(1).times;
Summary.allTimes = Projection(1).allTimes;
Summary.jPCs = jPCs;
Summary.PCs = PCvectors;
Summary.jPCs_highD = PCvectors * jPCs;
Summary.varCaptEachJPC = varCaptEachJPC;
Summary.varCaptEachPC = varCaptEachPC;
Summary.varCaptEachPlane = varCaptEachPlane;
Summary.sortIndices = sortIndices;
Summary.planState = planState;
Summary.finalState = finalState;
Summary.outcomes = params.conditionLabels; % CPL -- Use "Success" or "Failure" among condition labels
Summary.Mbest = M;
Summary.Mskew = Mskew;
Summary.fitErrorM = fitErrorM;
Summary.fitErrorMskew = fitErrorMskew;
Summary.R2_Mskew_2D = R2_Mskew_2D;
Summary.R2_Mbest_2D = R2_Mbest_2D;
Summary.R2_Mskew_kD = R2_Mskew_kD;
Summary.R2_Mbest_kD = R2_Mbest_kD;
Summary.circStats = circStats;
Summary.crossCondMean = crossCondMeanAllTimes(analyzeIndices,:);
Summary.crossCondMeanAllTimes = crossCondMeanAllTimes;
Summary.preprocessing.normFactors = normFactors;  % Used for projecting new data from the same neurons into the jPC space
Summary.preprocessing.meanFReachNeuron = meanFReachNeuron; % You should first normalize and then mean subtract using this (the original) mean
% conversely, to come back out, you must add the mean back on and then MULTIPLY by the normFactors
% to undo the normalization.
Summary.params = params;

   function c = recover_state_index(projArray,keepTime,t)
      %RECOVER_STATE_INDEX  Recovers "state" index of certain time 
      %
      %  c = recover_state_index(projArray,keepTime,t);
      %
      %  Inptus
      %     projArray - Array of projection data (`Projection` struct)
      %     keepTime  - Time (ms) to keep
      %     t         - Vector of comparison trials (sample times; rows)
      %
      %  Output
      %     c         - Cell array that is the "State" at that trial
      %                    instant corresponding to `keepTime`
      
      [~,keepIndex] = min(abs(t-keepTime)); 
      c = {projArray.proj(keepIndex,:)};
   end

end





