function [fig, Proj_Out] = plotMultiRosette(Proj,p,varargin)
%PLOTMULTIROSETTE  Plot multiple rosettes
%
% [fig,Proj] = analyze.jPCA.plotMultiRosette(Proj,p,varargin);
%
% Inputs
%  Proj        - Matrix where rows are time steps and columns are each
%                       jPC or PC projection. 
%  p           - (Optional) Parameters struct with following fields:
%
%     * `WhichPair` - Specifies which plane to look at
%     * `VarCapt`   - Specifies percent (0 to 1) of variance captured by
%                       this plane
%     * `XLim`      - Axes x-limits
%     * `YLim`      - Axes y-limites
%     * `FontName`  - Name of font ('Arial')
%     * `FontSize`  - Size of text labels (16-pt)
%     * `FontWeight`- 'bold' (default) or 'normal'
%     * `Figure`    - Figure handle (default is empty)
%     * `Axes`      - Axes handle (default is empty)
%  varargin    - 'Name',value syntax for modifying fields of `p` directly.
%
% Output
%  fig         - Figure handle or array of figure handles
%  Proj_Out    - Input data array with additional zero offset (traj_offset)
%                 field if that was done for visualization

% Check input arguments
if nargin < 2
   p = defaults.jPCA('rosette_params');
elseif isempty(p)
   p = defaults.jPCA('rosette_params');
elseif ischar(p)
   varargin = [p, varargin];
   p = defaults.jPCA('rosette_params');
end

% Parse 'Name',value pairs
fn = fieldnames(p);
for iV = 1:2:numel(varargin)
   iField = ismember(lower(fn),lower(varargin{iV}));
   if sum(iField)==1
      p.(fn{iField}) = varargin{iV+1};
   end
end

% Get "short" time-basis
[t_lims_short,S] = defaults.jPCA('t_lims_short','phase_s');
p.tLims = t_lims_short;
allDays = [Proj.PostOpDay];
[ud,iU] = unique(allDays);
nFig = numel(ud);
fig = gobjects(nFig,1);

Proj_Out = cell(size(fig));
for iD = 1:nFig
   fig_offset = [randn(1)*0.025 randn(1)*0.025 0 0];
   fig(iD) = figure(...
      'Name',sprintf('%s: Post-Op Day %d',Proj(iU(iD)).AnimalID,ud(iD)),...
      'Color','w',...
      'Units','Normalized',...
      'Position',p.FigurePosition+fig_offset...
      );
   p.Figure = fig(iD); % To pass to `plotRosette`
   thisProj = Proj(allDays==ud(iD));
   Proj_Out{iD} = cell(2,2);
   for iS = 1:size(S,2)
      p.Axes = subplot(2,2,iS);
      set(p.Axes,...
         'NextPlot','add',...
         'XColor',p.XColor,...
         'YColor',p.YColor,...
         'XLimMode','manual',...
         'XLim',p.XLim,...
         'YLimMode','manual',...
         'YLim',p.YLim,...
         'LineWidth',p.AxesLineWidth...
         );
       title(p.Axes,S{1,iS},...
         'FontName','Arial',...
         'FontWeight','bold',...
         'Color','k');
       p.iSource = S{2,iS};
       tOff = [thisProj.(p.iSource)];
       thisProj_specific = thisProj(~(isnan(tOff) | isinf(tOff)));
       [fig(iD),Proj_Out{iD}{iS}] = analyze.jPCA.plotRosette(...
          thisProj_specific,p);
   end   
end

end