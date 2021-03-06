function fig = plotSliceSampleTrends(glme_best,varargin)
%PLOTSLICESAMPLETRENDS Use model-based surrogates with slicesample to generate by-day trends with 95% confidence bounds
%
%  fig = analyze.dynamics.plotSliceSampleTrends(glme_best);
%  fig = analyze.dynamics.plotSliceSampleTrends(glme_best,'Name',value,...);
%
% Inputs
%  glme_best - GeneralizedLinearMixedModel produced in 
%                 population_firstorder_mls_regression_stats
%  varargin  - (Optional) 'Name',value pairs
%
% Output
%  fig       - Figure handle
%
%  See Figure 3.
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats
%           slicesample (R2006a+)

pars = struct;
pars.NRep = 10000;
pars.C = struct('Ischemia',...
            struct('Reach',[0.8 0.2 0.2],...
                   'Grasp',[1.0 0.4 0.4]), ...
                'Intact',...
             struct('Reach',[0.2 0.2 0.8],...
                    'Grasp',[0.4 0.4 1.0]));

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

% Add helper repository %
utils.addHelperRepos();

% Create graphics for output %
fig = figure('Name','Population Dynamics Fit Trends',...
   'Color','w','Units','Normalized','Position',[0.3 0.4 0.5 0.35]);
ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','NextPlot','add','XLim',[0 30],'YLim',[0 1]);
xlabel(ax,'Post-Op Day',...
   'FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'R^2_{MLS}',...
   'FontName','Arial','Color','k','FontWeight','bold');
title(ax,'Linearized Dynamics Fit by Day',...
   'FontName','Arial','Color','k','FontWeight','bold');
T = glme_best.Variables;
T.R2_Best = glme_best.response;
if ismember('Explained_Best',T.Properties.VariableNames)
   expName = 'Explained_Best';
else
   expName = 'Explained';
end
T(T.(expName) < 0.15,:) = [];
[G,TID] = findgroups(T(:,{'GroupID','Alignment'}));

for iG = 1:size(TID,1)
   % Get color for this grouping
   c = pars.C.(string(TID.GroupID(iG))).(TID.Alignment(iG));
   str = sprintf('%s::%s',string(TID.GroupID(iG)),TID.Alignment(iG));
   idx = G==iG;
   
   data = T(idx,[glme_best.PredictorNames; 'R2_Best']);

   X = data.PostOpDay;
   Z = data.R2_Best;
   [iDay,x] = findgroups(X);

   mu = splitapply(@(r2)nanmean(r2),Z,iDay);
   cb95 = cell2mat(splitapply(@(r2)analyze.stat.getCB95(r2),Z,iDay));
   xq = (min(x):max(x))';
   muq = interp1(x,mu,xq,'makima');
   cb95q = interp1(x,cb95,xq,'makima');
   
   muq = sgolayfilt(muq,5,15,ones(1,15),1);
   cb95q = sgolayfilt(cb95q,5,15,ones(1,15),1);
   cb95q(:,1) = min(cb95q(:,1),muq);
   cb95q(:,2) = max(cb95q(:,2),muq);
   
   gfx__.plotWithShadedError(ax,xq,muq,cb95q,...
      'FaceColor',c,...
      'DisplayName',str,...
      'Annotation','on',...
      'LineWidth',2.5);
   drawnow;
end

legend(ax,'TextColor','k','FontName','Arial');

end