function rotate2jPCA(Projection,Summary,step)
% ROTATE2JPCA Rotate a trajectory to the corresponding jPCA projection
%
%  analyze.jPCA.rotate2jPCA(Projection,Summary,step);

if nargin < 3
   analyze.jPCA.rotate2jPCA(Projection,Summary,times,totalSteps,1);
   drawnow;
   for ii = 2:totalSteps
      analyze.jPCA.rotate2jPCA(Projection,Summary,times,totalSteps,ii);
      drawnow;
   end
   return;
end

for c = 1:numel(Projection)
   data = Projection(c).state;
   dataRot = data * (Summary.jPCs)^(step/totalSteps);
   Projection(c).rotated_state = real(dataRot); 
end
analyze.jPCA.phaseSpace(Projection,Summary,params);
end