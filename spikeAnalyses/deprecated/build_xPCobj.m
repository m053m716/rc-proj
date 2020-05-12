function [x,y] = build_xPCobj(gData,poDay,useGroups,include)
%% BUILD_XPCOBJ   Helper function for building xPCobj that keeps PCA stuff


%% GET INPUT
if nargin < 2
   poDay = 3:28;   
end

if nargin < 3
   useGroups = true;
end

if nargin < 4
   include = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);
end

if useGroups
   group = {gData.Name}.';
else
   group = {'All'};
end

%% BUILD PARENT OBJECT
if isa(gData,'group')
   x = xPCobj(...
      gData,...   % Main data object handle
      'Grasp',... % Alignment of neural data
      include,...% behavior
      {'RFA','CFA'},... % Include channels with these AREA codes
      min(poDay),...     % "Start" Post-Op Day (must be >=)
      max(poDay),...    % "Stop" Post-Op Day (must be <=)
      {'DF','PF','DF-PF','PF-DF'}... % Include channels w/ these ICMS codes
      );
elseif isa(gData,'rat')
   x = xPCobj(numel(gData));
   nChildren = 0;
   for iX = 1:numel(x)
      x(iX) = xPCobj(...
         gData(iX),...   % Main data object handle
         'Grasp',... % Alignment of neural data
         include,...% behavior
         {'RFA','CFA'},... % Include channels with these AREA codes
         min(poDay),...     % "Start" Post-Op Day (must be >=)
         max(poDay),...    % "Stop" Post-Op Day (must be <=)
         {'DF','PF','DF-PF','PF-DF'}... % Include channels w/ these ICMS codes
         );
      nChildren = nChildren + numel(gData(iX).Children);
   end
else
   error('First input is invalid data type: %s',class(gData));
end
doRatefreqEstimate(x);
doPCfreqEstimate(x);


%% BUILD AND ASSIGN CHILD OBJECTS
if isa(gData,'group')
   y = xPCobj(numel(group)*numel(poDay));
   idx = 1;
   for iG = 1:numel(group)
      for iD = 1:numel(poDay)
         if useGroups
            g = gData.(group{iG});
         else
            g = gData;
         end
         y(idx) = xPCobj(g,...
            'Grasp',...
            include,...
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
elseif isa(gData,'rat')
   y = xPCobj(nChildren);
   idx = 1;
   for iG = 1:numel(gData)
      poDay = getNumProp(gData(iG).Children,'PostOpDay');
      iStart = idx;
      for iD = 1:numel(poDay)
         
         y(idx) = xPCobj(gData(iG),...
            'Grasp',...
            include,...
            {'RFA','CFA'},...
            poDay(iD),poDay(iD),...
            {'DF','PF','DF-PF','PF-DF'});
         idx = idx + 1;
      end
      iStop = idx - 1;
      doRatefreqEstimate(y(iStart:iStop));
      doPCfreqEstimate(y(iStart:iStop));
      setParent(y(iStart:iStop),x(iG));
      setChildObj(x(iG),y(iStart:iStop)); 
   end
end

end