function phaseData = getPhase(Proj, whichPair, label)
%% GETPHASE    Get the phase for a given plane over its timecourse
%
%  --------
%   INPUTS
%  --------
%    Proj      :     Matrix where rows are time steps and columns are each
%                       jPC or PC projection. 
%
%  whichPair   :     Specifies which plane to look at. (default: primary)

%%
numConds = numel(Proj);

if nargin < 3
   label = ones(1,numConds);
end

if nargin < 2
   whichPair = 1;
end


d1 = 1 + 2*(whichPair-1);
d2 = d1+1;

for c=1:numConds
%    if use_orth
%       data = Proj(c).proj_orth(:,[d1,d2]);
%    else
%       data = Proj(c).proj(:,[d1,d2]);
%    end
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
   phaseData(c).phaseOfDelta = phaseOfDelta'; 
   phaseData(c).radius = radius';
   
   % angle between state vector and Dstate vector
   % between -pi and pi
   phaseData(c).phaseDiff = jPCA.minusPi2Pi(phaseData(c).phaseOfDelta - phaseData(c).phase);
%    phaseData(c).wAvgDPWithPiOver2 = jPCA.averageDotProduct(phaseData(c).phaseDiff,pi/2,phaseData(c).radius);
   phaseData(c).wAvgDPWithPiOver2 = jPCA.averageDotProduct(phaseData(c).phaseDiff,pi/2);
   phaseData(c).label = label(c);
end

end