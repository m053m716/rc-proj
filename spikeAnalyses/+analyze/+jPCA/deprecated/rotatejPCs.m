function rotatejPCs(Projection,Summary,rot,nStep)
% ROTATEJPCS Rotate jPC projection from one alignment to another
%
%  analyze.jPCA.rotatejPCs(Projection,Summary,rot,nStep);
%  
%  Inputs
%     Projection - Data struct array of projected trajectories recovered
%                    using `analyze.jPCA.jPCA`
%     Summary    - Data parameters struct returned from `analyze.jPCA.jPCA`
%     rot        - Rotation matrix for data transformation (e.g. for jPCs)
%     nStep      - Total number of times to apply `rot`
%
%  Output
%     Draws the phase space for that many projections.

if nargin < 3
   analyze.jPCA.rotatejPCs(Projection,Summary,times,totalSteps,1,false);
   drawnow;
   for ii = 2:totalSteps
      analyze.jPCA.rotatejPCs(Projection,Summary,times,totalSteps,ii,true);
      drawnow;
   end
   return;
end

params = defaults.jPCA('movie_params');
params.useRot = true;
params.times = Projection(1).times;
params.Animal = Projection(1).AnimalID;
params.Alignment = Projection(1).Alignment;
params.Day = Projection(1).PostOpDay;
if isempty(params.Figure)
   if isempty(params.Axes)
      [params.Figure,params.Axes] = ...
         analyze.jPCA.blankFigure(params.axLim,...
         'Units','Pixels',...
         'Position',params.pixelSize,...
         'Color','k',...
         'Name','Rotated Projections');
   else
      params.Figure = get(params.Axes,'Parent');
   end
end
set(params.Axes,'Color','none');

Projection = analyze.jPCA.updateState(Projection,Summary.jPCs);
params = analyze.jPCA.phaseSpace(Projection,Summary,params);
drawnow;
for iStep = 1:nStep
   R = rot ^ (iStep / nStep);
   Projection = analyze.jPCA.updateState(Projection,Summary.jPCs,R);
   analyze.jPCA.phaseSpace(Projection,Summary,params);
   drawnow;
end
   
   
end