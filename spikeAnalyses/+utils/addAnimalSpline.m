function T = addAnimalSpline(T,varName,k,varargin)
%ADDANIMALSPLINE Adds cublic spline to fit time series with k knots
%
%  T = utils.addAnimalSpline(T,varName); -> Default is 3 knots
%  T = utils.addAnimalSpline(T,varName,k);
%
% Inputs
%  T        - Data table with 'AnimalID' variable (or specify this using
%              'Name',value inputs)
%  varName  - Variable name to add spline term
%              --> Resulting variable is appended to table with name
%                 [varName '_spline'] (unless tag is modified in
%                 'Name',value inputs)
%  k        - (Optional) number of knots for spline
%
% Output
%  T        - Data table with spline output assigned to each animal
%
% See also: utils, trial_duration_stats

if nargin < 3
   k = 3;
end

pars = struct;
pars.Grouping = 'AnimalID';
pars.Tag = '_spline';
pars.Time = 'Day';
fn = fieldnames(pars);

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if ~ismember(pars.Time,T.Properties.VariableNames)
   error('No Time variable: %s (table must contain it)',pars.Time);
end

if ~ismember(pars.Grouping,T.Properties.VariableNames)
   error('No Random Grouping variable for spline effect: %s (table must contain it)',pars.Grouping);
end

if ~ismember(varName,T.Properties.VariableNames)
   error('Specified `varName` (%s) is not a variable in the input table!',varName);
end

outVar = [varName pars.Tag];
[G,TID] = findgroups(T(:,{pars.Grouping,pars.Time}));
TID.(varName) = splitapply(@nanmean,T.(varName),G);
G = findgroups(TID(:,pars.Grouping));

TID.(outVar) = cell2mat(splitapply(@(t,x)computeSpline(t,x,k),TID.(pars.Time),TID.(varName),G));

if isstruct(T.Properties.UserData)
   tmp = T.Properties.UserData;
else
   tmp = struct;
end

T = outerjoin(...
   T,TID,...
   'Keys',{pars.Grouping,pars.Time},...
   'LeftVariables',setdiff(T.Properties.VariableNames,outVar),...
   'RightVariables',{outVar},...
   'Type','left' ...
   );

T.Properties.UserData = tmp;


   function y = computeSpline(t,x,k)
      %COMPUTESPLINE Does the knotted spline part
      %
      %  y = computeSpline(t,x,k);
      %
      % Inputs:
      %  t - Time variable (independent variable)
      %  x - Measurement (dependent variable)
      %  k - Number of points where measurement is to be "knotted"
      %
      % Output
      %  y - Smoothed spline effect corresponding to measurements of `x`
      
      nObs = numel(t);
      iKnot = round(linspace(1,nObs,k));
      pp = csape(t(iKnot),x(iKnot),'clamped');
      y = fnval(pp,t);
      y = {reshape(y,numel(y),1)};
   end


end