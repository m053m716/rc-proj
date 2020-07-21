function fig = blocks(S,response,varargin)
%BLOCKS  Shows figure(s) of response variable by Block using Rate Table
%
%  fig = analyze.behavior.blocks(S,response);
%  fig = analyze.behavior.blocks(S,resposne,...
%           'var1',{val1},'var2',{val2},...);
%
% Inputs
%  S        - See analyze.behavior.score
%  response - Name of "response" variable from data table
%  varargin - Optional 'Name',value filters to add to restrict what is
%              plotted, consisting of Variable names and viable values.
%
% Output
%  fig      - Figure handle
%
% See also: analyze.stat, analyze.behavior, analyze.behavior.score
%           analyze.behavior.outcomes, analyze.behavior.durations,
%           behavior_timing.mlx

pars = struct;
pars.AxesParams = {...
   'NextPlot','add',...
   'XLim',[2 30],'XTick',7:7:28,...
   'XColor','k','YColor','k',...
   'LineWidth',1.5,'FontName','Arial'};
pars.Colors = [0.8 0.1 0.1; 0.1 0.1 0.8];
pars.FigParams = {...
   'Name','Trial Duration by Day',...
   'Units','Normalized',...
   'Color','w'};
pars.FigPosition = [0.43 0.48 0.43 0.37];
pars.FontParams = {'FontName','Arial','Color','k'};
pars.RegressionParams = {...
   'Color','k',...
   'LineWidth',1.5,...
   'TX',30.5,...
   'addlabel',false};
pars.ScatterPars = struct;
   pars.ScatterPars.AddLabel = false;
   pars.ScatterPars.Annotation = 'off';
   pars.ScatterPars.Jitter = 0.25;
   pars.ScatterPars.MarkerEdgeAlpha = 0.25;
   pars.ScatterPars.MarkerFaceAlpha = 0.25;
   pars.ScatterPars.MarkerSize = 12;
   pars.ScatterPars.RegressionType = 'logistic';
   pars.ScatterPars.ScatterParams = {};
   pars.ScatterPars.ShowAnimals = true;
   pars.ScatterPars.TX = 30.5;
   pars.ScatterPars.XPlot = linspace(3,30,100);
pars.SliceParams = {}; % "Filter" slice
pars.Title = '';
pars.XPlot = linspace(2.5,31,250);
pars.YLim = [];

fn = fieldnames(pars);

if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
pars.ScatterPars.RegressionParams = pars.RegressionParams;

if ~isempty(pars.YLim)
   pars.AxesParams = [pars.AxesParams, ...
      'YLimMode','manual',...
      'YLim', pars.YLim];
end

pars.FigParams = [pars.FigParams, ...
   'Position', pars.FigPosition];
fig = figure(pars.FigParams{:});
   
S_sub = analyze.slice(S,pars.SliceParams{:});
[G,TID] = findgroups(S_sub(:,'Group'));


nTotal = size(TID,1);
nRow = floor(sqrt(nTotal));
nCol = ceil(nTotal/nRow);

iResponse = find(strcmpi(S.Properties.VariableNames,response),1,'first');
response = S.Properties.VariableNames{iResponse};

if isempty(S.Properties.VariableUnits{iResponse})
   yLab = strrep(response,'_',' ');
else
   yLab = sprintf('%s (%s)',strrep(response,'_',' '),...
      S.Properties.VariableUnits{iResponse});
end

ls = ["-","--","-.",":"];
rat_col = defaults.experiment('rat_color');

for ii = 1:nTotal
   col = pars.Colors(ii,:);
   ax = subplot(nRow,nCol,ii);
   S_group = S_sub(G==ii,:);
   gnames = findgroups(S_group(:,'AnimalID'));
   C = rat_col.(string(TID.Group(ii)));
   set(ax,'Parent',fig,pars.AxesParams{:});
   [~,hReg] = splitapply(...
      @(poDay,y,name)analyze.stat.addJitteredScatter(...
      ax,poDay,y,name,col,pars.ScatterPars),...
      S_group.PostOpDay,S_group.(response),S_group.AnimalID,gnames);
   
   hReg = vertcat(hReg{:});
   for iReg = 1:numel(hReg)
      idx = mod(iReg-1,4)+1;
      set(hReg(iReg),'LineStyle',ls(idx),'Color',C(iReg,:));
   end
   analyze.stat.addLogisticRegression(ax,...
      S_group.PostOpDay+randn(size(S_group.PostOpDay)).*0.2,...
      S_group.(response),[0 0 0],pars.XPlot,...
      pars.RegressionParams{:});
   title(ax,string(TID.Group(ii)),pars.FontParams{:});
   ylabel(ax,yLab,pars.FontParams{:});
   xlabel(ax,'Post-Op Day',pars.FontParams{:});
   legend(ax,...
      'Location','northeast',...
      'TextColor','black',...
      'Box','off',...
      'Color','none',...
      'FontName','Arial',...
      'NumColumns',2);
end
suptitle(pars.Title);    


end