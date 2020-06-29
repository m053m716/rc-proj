function fig = plotCoefficients(B,BNames,Group,Name,varargin)
%PLOTCOEFFICIENTS Plot coefficients by Group, Name
%
%  fig = analyze.stat.plotCoefficients(B,BNames,Group,Name,varargin);
%  fig = analyze.stat.plotCoefficients(B,BNames);
%        -> Plot all unique combinations of 'Group' and 'Names' from BNames
%
% Inputs
%  B        - Array of random coefficient estimates
%              -> Can also provide this as `stats` dataset recovered by:
%                    `[B,BNames,stats] = randomEffects(glme)`;
%              -> Can provide as 3-column array: [mu, lb, ub] for each
%                 estimate
%  BNames   - Table of random coefficient names
%  Group    - Subset of 'Group' column from 'BNames' to include
%              -> Specify as empty to skip entering and instead use all
%                 unique elements of BNames.Group
%  Name     - Subset of 'Name' column from 'BNames' to include (def:
%              {'Intercept'})
%              -> Specify as empty to skip entering and instead use all
%                 unique elements of BNames.Name
%  varargin - <'Name',value> pairs of random coefficients
%              Each of the following are (name,value in alternating order)
%              -> 'axParams'   - Cell array of default axes parameters
%              -> 'figParams'  - Cell array of default figure parameters
%              -> 'fontParams' - Cell array of default font parameters
%              -> 'DefName'    - Default value for `Name` input if none
%              -> 'PlotType'   - 'stem' or 'line' or 'scatter'
%                 -> 'stemParams' - Cell array of 'Name' value pairs for
%                    "stem" plot case
%                 -> 'lineParams' - Cell array of 'Name' value pairs for
%                    the "line" plot case
%                 -> 'scatterParams' - Cell array of 'Name' value pairs for
%                    the "scatter" plot case
%              -> 'cbParams' - Cell array of 'Name' value pairs for
%                    the confidence line added in "line" or "scatter" cases
%              -> 'legParams' - Cell array of 'Name' value pairs for legend
%              -> 'pParams' - Cell array of 'Name' value pairs for sig
%                             markers
%              -> 'Figure'     - Default is empty; can give as fig handle
%              -> 'titleString' - Constant portion of axes label
%              -> 'sigMarkerY'  - Location of "significance" asterisk
%                                (Y-axis; default: 0.9)
%              -> 'fixedYLim'   - Fixed y-scale (to allow plot comparisons)
%                                (Default: [-1 1]; set to [nan nan] to
%                                auto-scale y-axes instead)
%              -> 'pValueAlpha' - Alpha threshold for significance marker
%                                   being added (default: 0.01)
%              -> 'XAxisLabelRotationDegrees' - (default: 60)
%              
%
% Output
%  fig      - Figure handle
%
% See also: analyze.stat

% % Parse inputs % %
p = struct;
p.DefName = {'Intercept'};
p.PlotType = 'scatter';
p.cbParams = {'LineStyle','-','Marker','sq','MarkerFaceColor','k','MarkerEdgeColor','none','MarkerSize',6,'Color','r','LineWidth',1.25};
p.scatterParams = {'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','none','MarkerSize',12};
p.stemParams = {'LineStyle','-','LineWidth',1.5,'Marker','o','Color','k','MarkerFaceColor','b','MarkerEdgeColor','b'};
p.lineParams = {'LineStyle',':','LineWidth',2.0,'Marker','o','Color','k','MarkerFaceColor','b','MarkerEdgeColor','none'};
p.legParams = {'TextColor','black','FontName','Arial','FontSize',10};
p.legLocation = 'South';
p.pParams = {'LineStyle','none','Marker','*','MarkerFaceColor',[0.9 0.7 0.3],'MarkerEdgeColor',[0.9 0.7 0.3],'MarkerSize',8,'LineWidth',1.5};
p.sigMarkerY = 0.9;
p.XAxisLabelRotationDegrees = 60;
p.fixedYLim = [-1 1];
p.pValueAlpha = 0.05;
p.titleString = 'Coefficient Estimate';
p.Figure = [];
[p.axParams,p.figParams,p.fontParams] = defaults.stat(...
   'axParams','figParams','fontParams');
fn = fieldnames(p);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      p.(fn{idx}) = varargin{iV+1};
   end   
end

if nargin < 4
   if isempty(p.DefName)
      Name = unique(BNames.Name);
   else
      Name = p.DefName;
   end
elseif isempty(Name)
   Name = unique(BNames.Name);
end

if nargin < 3
   Group = unique(BNames.Group);
elseif isempty(Group)
   if ismember('Group',BNames.Properties.VariableNames)
      Group = unique(BNames.Group);
   else
      [ll,gg] = parseNameParts(BNames);
      BNames.Level = ll;
      BNames.Group = gg;
      Group = unique(gg);
   end
end

if ~ismember('Group',BNames.Properties.VariableNames)
   [ll,gg] = parseNameParts(BNames);
   BNames.Level = ll;
   BNames.Group = gg;
   Group = unique(gg);
end

if isnumeric(B)
   switch size(B,2)
      case 1 % Vector of coeff values only
         lb = nan(size(B));
         ub = nan(size(B));
         pVal = nan(size(B));
      case 2 % Coeff values + sd
         sd = B(:,2);
         B = B(:,1);
         lb = B - 2*sd;
         ub = B + 2*sd;
         pVal = nan(size(B));
      case 3 % Coeff values + B(:,2)-lower; B(:,3)-upper
         lb = B(:,2);
         ub = B(:,3);
         B = B(:,1);
         pVal = nan(size(B));
      case 4 % Coeff values + bounds + p-values
         lb = B(:,2);
         ub = B(:,3);
         pVal  = B(:,4);
         B = B(:,1);
      otherwise
         error(['RC:' mfilename ':BadInputSize'],...
            ['\n\t->\t<strong>[PLOTCOEFFICIENTS]:</strong> ' ...
             'Weird dataset shape, check `B` input.']);
   end
elseif isa(B,'classreg.regr.lmeutils.titleddataset')
   stats = B;
   B = stats.Estimate;
   lb = stats.Lower;
   ub = stats.Upper;
   pVal  = stats.pValue;
   if numel(varargin)>1
      if ~any(strcmpi(varargin(1:3:end),'PlotType'))
         p.PlotType = 'scatter';
      end
   end
end

% % Make graphics objects and stem plots % %
if isempty(p.Figure)
   fig = figure(...
      'Name','Model Coefficients Plot',...
      p.figParams{:});
else
   fig = p.Figure;
end

% % Determine number of axes and layout % %
bnames = BNames(ismember(BNames.Group,Group) & ismember(BNames.Name,Name),:);
[G,tid] = findgroups(bnames(:,{'Group','Name'}));
   
alpha_str = ['Significant (\alpha = ' num2str(p.pValueAlpha,'%5.3f') ')'];
nTotal = max(G);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
hasSigPoint = false;
for iU = 1:nTotal
   X = tid.Group{iU};
   Y = strrep(strrep(tid.Name{iU},'(',''),')','');
   iThis = G == iU;
   coefs = B(iThis);
   vec = 1:sum(iThis);
   ax = subplot(nRow,nCol,iU);
   set(ax,p.axParams{:});
   sep = nan(1,sum(iThis));
   cb = [lb(iThis).';ub(iThis).';sep];
   cb = cb(:);
   vec_cb = [vec; vec; sep];
   vec_cb = vec_cb(:);
   str = sprintf('(%s by %s)',Y,X);
   xl = [0 (max(vec)+1)];
   % First, add line indicating zero for this axes 
   %  (if CB does not cross, is significant)
   hZ = line(ax,xl,[0 0],'LineWidth',1.5,'Color',[0.75 0.75 0.75]);
   hZ.Annotation.LegendInformation.IconDisplayStyle = 'off';
   
   % Next, plot the actual coefficients
   switch lower(p.PlotType)
      case {'line','plot'}
         line(ax,vec,coefs,p.lineParams{:},'DisplayName',p.titleString);
         line(ax,vec_cb,cb,p.cbParams{:},...
            'DisplayName','95% Confidence Bounds');
      case 'scatter'
         line(ax,vec,coefs,p.scatterParams{:},'DisplayName',p.titleString);
         line(ax,vec_cb,cb,p.cbParams{:},...
            'DisplayName','95% Confidence Bounds');
      case 'stem'
         stem(ax,vec,coefs,p.stemParams{:},'DisplayName',p.titleString);
      otherwise
         error(['RC:' mfilename ':BadCase'],...
            ['\n\t->\t<strong>[PLOTCOEFFICIENTS]:</strong> ' ...
             'Unrecognized value for `PlotType` parameters: %s'],...
            p.PlotType);
   end
   pThis = pVal(iThis);
   pIdx = pThis <= p.pValueAlpha;
   if any(pIdx)
      if any(isnan(p.fixedYLim))
         yscl = 0.05 .* coefs;
      else
         yscl = p.sigMarkerY;
      end
      yP = ones(size(vec)).*yscl;
      yP(~pIdx) = nan;
      if hasSigPoint
         hSig = line(ax,vec,yP,p.pParams{:},'DisplayName',alpha_str);
         hSig.Annotation.LegendInformation.IconDisplayStyle = 'off';
      else
         line(ax,vec,yP,p.pParams{:},'DisplayName',alpha_str);
         hasSigPoint = true;
      end
   end
   
   xlabel(ax,strrep(X,'_',' '),p.fontParams{:});
   ylabel(ax,strrep(Y,'_',' '),p.fontParams{:});
   if ~any(isnan(p.fixedYLim))
      ylim(ax,p.fixedYLim);
   end
   xlim(ax,xl);
   ax.XTick = vec;
   ax.XTickLabels = bnames.Level(iThis);
   ax.XTickLabelRotation = p.XAxisLabelRotationDegrees;
   title(ax,sprintf('%s %s',p.titleString,str),p.fontParams{:});
   legend(ax,p.legParams{:},'Location',p.legLocation);
end

   function [Level,Group] = parseNameParts(BetaNames)
      %PARSENAMEPARTS Parse names from beta names (for Fixed Effects)
      %
      %  [Level,Group] = parseNameParts(BetaNames);
      %
      % Inputs
      %  BetaNames - Table with only 'Name' variable
      %
      % Output
      %  Level     - Cell array of parsed "levels"
      %  Group     - Cell array of parsed "groupings"
      
      Level = cell(size(BetaNames,1),1);
      Group = cell(size(BetaNames,1),1);
      for ii = 1:size(BetaNames,1)
         name = BetaNames.Name{ii};
         if strcmpi(name,'(Intercept)')
            Group{ii} = 'Intercept';
            Level{ii} = 'Intercept';
            continue;
         end
         nameParts = strsplit(name,':');
         nTerm = numel(strsplit(name,':'));
         Group{ii} = sprintf('Fixed-Effect (%d-way)',nTerm);
         lev = '';
         for iTerm = 1:nTerm
            levParts = strsplit(nameParts{iTerm},'_');
            if numel(levParts)==1
               lev = [lev, sprintf('%s x ',levParts{1})]; %#ok<AGROW>
            else
               lev = [lev, sprintf('%s x ',levParts{2})]; %#ok<AGROW>
            end
         end
         Level{ii} = lev(1:(end-3));
      end
   end

end