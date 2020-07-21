function [h,hReg] = addJitteredScatter(ax,x,y,animal_id,color,pars)
%ADDJITTEREDSCATTER Adds jittered scatter plot to current axes
%
%  [h,hReg] = analyze.stat.addJitteredScatter(ax,x,y,animal_id,color,pars);
%
% Inputs
%  ax        - Axes handle
%  x         - Vector of PostOpDays probably
%  y         - Vector of response variable from `Gr` table
%  animal_id - Vector of AnimalID from `Gr` table
%  color     - Color of markers
%  pars      - (Optional) parameters struct
%
% Output
%  h         - Handle to scatter graphics object
%  hReg      - Handle to regression graphics object
%
% For use with `splitapply` workflow.
%
% See also: analyze.stat.scatter_var

if nargin < 5
   color = [0 0 0];
end

if nargin < 6
   pars = struct;
   pars.AddLabel = false;
   pars.Annotation = 'on';
   pars.Jitter = 0.25;
   pars.MarkerEdgeAlpha = 0.25;
   pars.MarkerFaceAlpha = 0.25;
   pars.MarkerSize = 12;
   pars.RegressionType = 'logistic';
   pars.ScatterParams = {};
   pars.ShowAnimals = true;
   pars.TX = 30.5;
   pars.XPlot = linspace(3,30,100);
end

ID = string(animal_id);
ID = char(ID(1));
if ~isfield(pars,'Marker')
   marker = defaults.experiment('marker');
   pars.Marker = marker.(strrep(ID,'-',''));   
   if ischar(pars.AddLabel)
      pars.AddLabel = [pars.AddLabel(1:(end-2)) '::' ID ': '];
   end
end

if ~isfield(pars,'RegressionParams')
   pars.RegressionParams = {'addlabel',pars.AddLabel,'TX',pars.TX};
end

xj = x + randn(size(x)).*pars.Jitter;
h = scatter(ax,xj,y,'filled',...
   'Marker',pars.Marker,...
   'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
   'MarkerEdgeAlpha',pars.MarkerEdgeAlpha,...
   'SizeData',pars.MarkerSize,...
   'LineWidth',1.5,...
   pars.ScatterParams{:},...
   'MarkerEdgeColor',color,...
   'MarkerFaceColor',color,...
   'DisplayName',strcat(ID,"_{trials}")); 
h.Annotation.LegendInformation.IconDisplayStyle = pars.Annotation;

if pars.ShowAnimals
   switch lower(pars.RegressionType)
      case 'linear'
         [~,~,hReg] = analyze.stat.addLinearRegression(ax,xj,y,color,...
            pars.XPlot,pars.RegressionParams{:},...
            'Displayname',ID);
      case 'logistic'
         [~,~,hReg] = analyze.stat.addLogisticRegression(ax,xj,y,color,...
            pars.XPlot,pars.RegressionParams{:},...
            'DisplayName',ID);
   end
end


end