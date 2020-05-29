function rotate2jPCA(Projection, Summary, times, totalSteps, step, reusePlot)
% ROTATE2JPCA Rotate a trajectory to the corresponding jPCA projection
%
%  analyze.jPCA.rotate2jPCA(Projection,Summary,times,totalSteps);
%  analyze.jPCA.rotate2jPCA(__,step,reusePlot);

if nargin < 5
   analyze.jPCA.rotate2jPCA(Projection,Summary,times,totalSteps,1,false);
   drawnow;
   for ii = 2:totalSteps
      analyze.jPCA.rotate2jPCA(Projection,Summary,times,totalSteps,ii,true);
      drawnow;
   end
   return;
end

numConds = length(Projection);

for c = 1:numConds
    data = Projection(c).tradPCAprojAllTimes;
    
    dataRot = data * (Summary.jPCs)^(step/totalSteps);
    
    Projection(c).projAllTimes = real(dataRot);  % hijack this field so that we can easily plot it
end


params.reusePlot = reusePlot;
params.times = times;
params.plotPlanEllipse = false;
params.useLabel = false;
params.useAxes = false;
params.planMarkerSize = 7.5;
analyze.jPCA.phaseSpace(Projection, Summary, params);