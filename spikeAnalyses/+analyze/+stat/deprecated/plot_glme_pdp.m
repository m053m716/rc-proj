function [fig,ax] = plot_glme_pdp(glme,Gr,varargin)
%PLOT_GLME_PDP Plot generalized linear mixed-effects model partial-dependence plot
%
%  [fig,ax] = analyze.stat.plot_glme_pdp(glme,Gr);
%  [__] = analyze.stat.plot_glme_pdp(glme,Gr,'name',value,...);
%
% Inputs
%  glme - Fit glme object
%  Gr   - Data table used to fit glme
%  varargin - (Optional) Pairs of 'Name',value input arguments
%     * 'fig' - Figure handle
%     * 'ax'  - Axes handle
%
% Output
%  fig - Generated figure handle
%  ax  - Generated axes handle

% Set parameters
p = struct('ax',[],'fig',[],...
   'varX','PostOpDay','varY','Duration',...
   'nPtQuery',10,'view',[140,30],'conditional','none');
fn = fieldnames(p);
for iV = 1:2:numel(varargin)
   iP = strcmpi(fn,varargin{iV});
   if sum(iP)==1
      p.(fn{iP}) = varargin{iV+1};
   end
end

if isempty(p.fig)
   if isempty(p.ax)
      fig = figure('Name','Partial Dependence GLME',...
         'Units','Normalized',...
         'NumberTitle','off',...
         'Color','w',...
         'Position',[0.1 0.1 0.8 0.8]);
   else
      fig = get(p.ax,'Parent');
      while(~isa(fig,'matlab.ui.Figure'))
         fig = get(fig,'Parent');
      end
   end
else
   fig = p.fig;
end

if isempty(p.ax)
   ax = axes(fig);
else
   ax = p.ax;
end

X = cell(1,2);
name = cell(1,2);
X{1} = Gr.(p.varX);
name{1} = p.varX;
X{2} = Gr.(p.varY);
name{2} = p.varY;

if isnumeric(X{1}) && isnumeric(X{2})
   pt1 = linspace(min(X{1}),max(X{1}),p.nPtQuery)';
   pt2 = linspace(min(X{2}),max(X{2}),p.nPtQuery)';
elseif isnumeric(X{1})
   pt1 = linspace(min(X{1}),max(X{1}),p.nPtQuery)';
   pt2 = [];   
elseif isnumeric(X{2})
   pt1 = [];
   pt2 = linspace(min(X{2}),max(X{2}),p.nPtQuery)';
else
   pt1 = [];
   pt2 = [];
end

if strcmpi(p.conditional,'absolute') || strcmpi(p.conditional,'centered')
   uX = unique(X{1});
   ax = gobjects(2,1);
   for ii = 1:2
      ax(ii) = subplot(1,2,ii);
      ax(ii) = plotPartialDependence(glme,uX,...
         'Conditional',p.conditional,...
         'ParentAxisHandle',ax(ii));
      title(ax(ii),name{ii});
   end
else
   ax = plotPartialDependence(glme,{p.varX,p.varY},...
      'QueryPoints',{pt1, pt2},...
      'Conditional',p.conditional,...
      'ParentAxisHandle',ax);
end
view(ax,p.view(1),p.view(2)) % Modify the viewing angle

end