function phaseData = getPhase(Proj,whichPair,wlen,S)
%GETPHASE    Get the phase for a given plane over its timecourse
%
% phaseData = analyze.jPCA.getPhase(Proj);
% phaseData = analyze.jPCA.getPhase(Proj,whichPair);
% phaseData = analyze.jPCA.getPhase(Proj,whichPair,wlen);
% phaseData = analyze.jPCA.getPhase(Proj,whichPair,wlen,S);
% phaseData = analyze.jPCA.getPhase(Proj,[],wlen,S);
%  -> Uses up to top-3 jPC planes
%
% Inputs
%  Proj       - Matrix where rows are time steps and columns are each jPC 
%                 or PC projection. 
%  whichPair  - Specifies which plane to look at. (default: primary)
%  wlen       - Number of samples to "window" around states of interest for
%                 phase values
%  S          - 2 x k cell array, where S(1,:) is name of "State" of
%                 interest, and S(2,:) is the indexing field to use for it 
%                  (from `Proj`)
%
% Output
%  phaseData  - Struct array that has info about the phase data.

numConds = numel(Proj);

if nargin < 2
   whichPair = defaults.jPCA('phase_pair');
elseif isempty(whichPair)
   whichPair = (max(size(Proj(1).proj,2)/2,3)):-1:1;
end

if nargin < 3
   wlen = defaults.jPCA('phase_wlen');
end

if nargin < 4
   S = defaults.jPCA('phase_s');
end

if numel(whichPair) > 1
   phaseData = cell(1,max(whichPair));
   for iPair = whichPair
      phaseData{1,iPair} = analyze.jPCA.getPhase(Proj,iPair,wlen,S);
   end
   return;
end

d1 = 1 + 2*(whichPair-1);
d2 = d1+1;

for c=1:numConds
   data = Proj(c).proj(:,[d1,d2]);
   phase = atan2(data(:,2), data(:,1));  % Y comes first for atan2
   
   deltaData = diff(data);
   phaseOfDelta = atan2(deltaData(:,2), deltaData(:,1));  % Y comes first for atan2
   phaseOfDelta = [phaseOfDelta(1); phaseOfDelta];  %#ok<*AGROW> % so same length as phase
   radius = sum(data.^2,2).^0.5;
   
   % collect and format
   % make things run horizontally so they can be easily concatenated.
   phaseData(c).times = Proj(c).times;
   phaseData(c).phase = phase'; 
   phaseData(c).area = Proj(c).Area;
   phaseData(c).phaseOfDelta = phaseOfDelta'; 
   phaseData(c).radius = radius';
   phaseData(c).outcome = Proj(c).Outcome;
   phaseData(c).duration = Proj(c).Duration;
   
   % angle between state vector and Dstate vector
   % between -pi and pi
   d = analyze.jPCA.minusPi2Pi(...
      phaseData(c).phaseOfDelta - phaseData(c).phase);
   % Make `phaseDiff` struct
   phaseData(c).phaseDiff = ...
      getStatePhaseSamples(Proj(c),phaseData(c),d,S,wlen);
   phaseData(c).phaseDiff.All = struct;
   phaseData(c).phaseDiff.All.t = Proj(c).times;
   phaseData(c).phaseDiff.All.delta = d;
   phaseData(c).wAvgDPWithPiOver2 = ...
      analyze.jPCA.averageDotProduct(d,pi/2);
   [phaseData(c).mu,ul,ll] = analyze.jPCA.CircStat2010d.circ_mean(d',radius);
   phaseData(c).cb95 = ul - ll;
   [phaseData(c).k,phaseData(c).k0] = ...
      analyze.jPCA.CircStat2010d.circ_kurtosis(d',radius);
   phaseData(c).label = Proj(c).Condition;
end

   function phaseDiff = getStatePhaseSamples(Proj,phaseData,d,S,wlen)
      %GETSTATEPHASESAMPLES Returns phase difference "state" on samples of interest
      %
      %  phaseDiff = getStatePhaseSamples(Proj,phaseData,d,S,wlen);
      %
      %  Inputs
      %     Proj - Struct array element from main input to `getPhase`
      %     phaseData - Struct array element from main output of `getPhase`
      %     d - Vector of all phase differences for this trial
      %     S - 2 x k cell array, where S(1,:) is name of "State" of
      %        interest, and S(2,:) is the indexing field to use for it 
      %        (from `Proj`)
      phaseDiff = struct;
      for iState = 1:size(S,2)
         ev = S{1,iState};
         id = S{2,iState};
         phaseDiff.(ev) = struct;
         [phaseDiff.(ev).t,vec] = getTimes(phaseData.times,Proj.(id),wlen);
         phaseDiff.(ev).delta = d(vec);
      end
   end

   function [t,vec] = getTimes(t,index,wlen)
      %GETTIMES Return times centered on a specific index
      %
      %  [t,vec] = getTimes(t,index,wlen)
      %  
      %  Inputs
      %     t - Vector of times to sample from
      %     index - Some index (scalar) in `t`
      %     wlen - Number of samples to "window" around `t` (must be
      %              odd-valued)
      %
      %  Output
      %     t - Subset of original `t` based on `index`
      %     vec - Sample index vector used to obtain `t` subset
      
      if isnan(index)
         t = [];
         vec = [];
         return;
      end
      nT = numel(t);
      nsAround = floor(wlen/2);
      vec = max(1,index-nsAround):min(index+nsAround,nT);
      t = t(vec);
   end
end