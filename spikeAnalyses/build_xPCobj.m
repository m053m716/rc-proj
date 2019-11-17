function [x,y] = build_xPCobj(gData,poDay)
%% BUILD_XPCOBJ   Helper function for building xPCobj that keeps PCA stuff


%% GET INPUT
if nargin < 2
   poDay = 3:28;   
end
group = {gData.Name}.';


%% BUILD PARENT OBJECT
x = xPCobj(...
   gData,...   % Main data object handle
   'Grasp',... % Alignment of neural data
   utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]),...% behavior
   {'RFA','CFA'},... % Include channels with these AREA codes
   min(poDay),...     % "Start" Post-Op Day (must be >=)
   max(poDay),...    % "Stop" Post-Op Day (must be <=)
   {'DF','PF','DF-PF','PF-DF'}... % Include channels w/ these ICMS codes
   );
doRatefreqEstimate(x);
doPCfreqEstimate(x);


%% BUILD AND ASSIGN CHILD OBJECTS
y = xPCobj(numel(group)*numel(poDay));
idx = 1;
for iG = 1:numel(group)
   for iD = 1:numel(poDay)
      y(idx) = xPCobj(gData.(group{iG}),...
         'Grasp',...
         utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]),...
         {'RFA','CFA'},...
         poDay(iD),poDay(iD),...
         {'DF','PF','DF-PF','PF-DF'});
      idx = idx + 1;
   end
end
doRatefreqEstimate(y);
doPCfreqEstimate(y);

setParent(y,x);
setChildObj(x,y); 

end