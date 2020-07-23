function fig = plotAreaDynamics(D,varargin)
%PLOTAREADYNAMICS Show "shared activations" by area
%
%  fig = analyze.dynamics.plotAreaDynamics(D);
%  fig = analyze.dynamics.plotAreaDynamics(D,'Name','value',...);
%
% Inputs
%  D        - Data table (see rates_to_jPCA.m script)
%  varargin - (Optional) 'Name',value input argument pairs
%
% Output
%  fig      - Figure handle
%
% See also: analyze.dynamics, analyze.dynamics.primaryPCDynamicsByArea,
%           analyze.jPCA, analyze.jPCA.phaseSpace_min

pars = struct;
pars.AreaLabel = 'RFA::CFA';
pars.BottomAxesParams = {...
   'Units','Normalized',...
   'Position',[0.13 0.11 0.775 0.365],...
   'Color','none',...
   'NextPlot','add',...
   'XColor','w',...
   'YColor','w',...
   'FontName','Arial',...
   'XLim',[-500 300],...
   'YLim',[-6.5 6.5], ...
   'LineWidth',1.5 ...
   };
pars.FigureParams = {...
   'Units','Normalized',...
   'Color','k',...
   'Position',[0.1496 0.2500 0.4000 0.6000],...
   'NumberTitle','off' ...
   };
pars.FirstLineParams = { ...
   'Color','w',...
   'LineStyle',':',...
   'LineWidth',2 ...
   };
pars.LegendParams = { ...
   'Location','West', ...
   'TextColor','white',...
   'FontName','Arial'...
   };
pars.ProjectionField = 'dX_PC_Proj';
pars.SaveLoc = defaults.files('area_dynamics_fig_dir');
pars.SecondLineParams = { ...
   'Color','w',...
   'LineStyle','--',...
   'LineWidth',2 ...
   };
pars.SubFolder = '';
pars.Tag = '';
pars.TopAxesParams = {...
   'Units','Normalized',...
   'Position',[0.13 0.55 0.775 0.365],...
   'Color','none',...
   'NextPlot','add',...
   'XColor','w',...
   'YColor','w',...
   'FontName','Arial',...
   'XLim',[-2 2],...
   'YLim',[-2 2], ...
   'LineWidth',1.5 ...
   };
pars.Trial = 1;

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

if size(D,1) > 1
   if nargout > 0
      fig = gobjects(size(D,1),1);
      for iD = 1:size(D,1)
         fig(iD) = analyze.dynamics.plotAreaDynamics(D(iD,:),pars);
      end
   else
      for iD = 1:size(D,1)
         analyze.dynamics.plotAreaDynamics(D(iD,:),pars);
      end
   end
   return;
end

fig = figure('Name','Dynamics by Area',pars.FigureParams{:});
topAx = axes(fig,pars.TopAxesParams{:});

t = D.Projection{1}(1).times;
mu = D.Projection{1}(1).PC_T.proj_mu;
P = D.Projection{1}(1);
P.dX_PC_Proj = mu;
analyze.jPCA.phaseSpace_min(P,...
   'projField',pars.ProjectionField,...
   'Animal',D.AnimalID(1),...
   'Alignment',D.Alignment(1),...
   'Area',pars.AreaLabel,...
   'rankType','eig',...
   'pIdx',1,...
   'plane2plot',1,...
   'axLim',[-2 2 -2 2],...
   'times',t,...
   'timeField','times',...
   'Day',D.PostOpDay(1),...
   'Figure',fig,...
   'Axes',topAx ...
   );

bottomAx = axes(fig,pars.BottomAxesParams{:});
area = string(D.Projection{1}(pars.Trial).PC_T.TID.Area);
X = D.Projection{1}(pars.Trial).dX_PC;
t = D.Projection{1}(pars.Trial).Zt;
line(bottomAx,t,X(:,1),...
   pars.FirstLineParams{:},...
   'Color',[0.8 0.2 0.2],...
   'DisplayName',sprintf('%s_{T-%02d}-1',area(1),pars.Trial)); 
line(bottomAx,t,X(:,2),...
   pars.FirstLineParams{:},...
   'Color',[0.9 0.3 0.3],...
   'DisplayName',sprintf('%s_{T-%02d}-2',area(1),pars.Trial)); 
line(bottomAx,t,X(:,3),...
   pars.FirstLineParams{:},...
   'Color',[1.0 0.4 0.4],...
   'DisplayName',sprintf('%s_{T-%02d}-3',area(1),pars.Trial)); 
line(bottomAx,t,X(:,4),...
   pars.SecondLineParams{:},...
   'Color',[0.2 0.2 0.8],...
   'DisplayName',sprintf('%s_{T-%02d}-1',area(2),pars.Trial));
line(bottomAx,t,X(:,5),...
   pars.SecondLineParams{:},...
   'Color',[0.3 0.3 0.9],...
   'DisplayName',sprintf('%s_{T-%02d}-2',area(2),pars.Trial));
line(bottomAx,t,X(:,6),...
   pars.SecondLineParams{:},...
   'Color',[0.4 0.4 1.0],...
   'DisplayName',sprintf('%s_{T-%02d}-3',area(2),pars.Trial));
legend(bottomAx,pars.LegendParams{:});

text(bottomAx,-300,-1.5,sprintf('(%5.2f%% Explained || R^2 = %0.4f)',...
   mean([sum(D.Projection{1}(1).PC_T.explained(1:3))...
         sum(D.Projection{1}(1).PC_T.explained(4:6))]),...
   mean(D.Summary{1}.SS.area_pcs.explained.varcapt)/100),...
   'FontName','Arial','FontSize',14,'FontWeight','bold','Color','w');

title(bottomAx,D.AFP_Classification(1),...
   'Color','w','FontName','Arial','FontWeight','bold');

if nargout > 0
   return;   
end

saveLoc = fullfile(pars.SaveLoc,pars.SubFolder);
if exist(saveLoc,'dir')==0
   mkdir(saveLoc);
end
name = sprintf('%s_%s-%s_Post-Op-%02d_Area-Dynamics%s',...
   D.AFP_Classification(1),D.AnimalID(1),D.Alignment(1),D.PostOpDay(1),...
   pars.Tag);
fname = fullfile(saveLoc,name);
savefig(fig,[fname '.fig']);
saveas(fig,[fname '.png']);
delete(fig);
end