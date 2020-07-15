function [Y,stat] = addLinearRegression(ax,x,y,c,X,varargin)
%ADDLINEARREGRESSION Helper for splitapply to add lines for animals
%
%  [Y,stat] = addLinearRegression(ax,x,y,c,X);
%
%  Uses median of dependent variable for offset and median of all
%  pairs of distances of dependent variable for slope estimate.
%
% Inputs
%  ax    - Target axes to add line to
%  x     - X-Data (independent variable for linear regression)
%  y     - Y-Data (dependent variable for linear regression)
%  c     - Color of line
%  X     - Points to use in projection to actually plot fit
%
% Output
%  Y     - Model output for each day
%  stat  - Statistics for model fit
%
%  Adds line to `axObj` object

% DEFAULTS TO PLOT
if nargin < 5
   X  = 3:30; % Plot line using prediction at these points
end
if nargin >= 6
   ipar = strcmpi(varargin(1:2:end),'TX');
   if any(ipar)
      ipar = 2*(find(ipar,1,'first')-1)+1;
      TX = varargin{ipar+1};
      varargin([ipar,ipar+1]) = [];
   else
      TX = 30.5;
   end
else
   TX = 30.5;
end

% Put data into correct orientation for `pdist`
if ~iscolumn(x)
   x = x.';
end

if ~iscolumn(y)
   y = y.';
end

if (numel(unique(x)) < 2) || (numel(unique(y)) < 2)
   Y  = {nan(size(X))};
   stat = {struct('R2',nan,'RSS',nan,'TSS',nan,'x',[],'y',[],...
      'yhat',[],'pts',struct,'f',@(x)x,'weights',[])};
   return;
end

% Get weights
if nargin >= 6
   ipar = strcmpi(varargin(1:2:end),'weights');
   if any(ipar)
      ipar = 2*(find(ipar,1,'first')-1)+1;
      weights = varargin{ipar+1};
      varargin([ipar,ipar+1]) = [];
   else
      weights = nan;
   end
else
   weights = nan;
end

% Get differences and median slope, intercept
[Beta,Beta0] = analyze.stat.recover_line(x,y,...
   'UseScaling',false,...
   'Weights',weights);
if isempty(Beta)
   Y = {nan(size(X))};
   stat = {struct('R2',nan,'RSS',nan,'TSS',nan,'x',[],'y',[],...
      'yhat',[],'pts',struct,'f',@(x)x,'weights',[])};
   return;
end
f   = @(x)reshape(Beta0 + Beta.*x,numel(x),1);

% Plot
Y = f(X);
stat = struct;
[stat.R2,stat.RSS,stat.TSS] = analyze.stat.getR2(y,f(x),weights);
stat.x = x;
stat.y = y;
stat.yhat = f(x);
stat.pts = struct('X',X,'Y',Y);
stat.f = f;
stat.weights = weights;

if numel(varargin)>0
   ipar = strcmpi(varargin(1:2:end),'addlabel');
   if any(ipar)
      ipar = 2*(find(ipar,1,'first')-1)+1;
      addlabel = varargin{ipar+1};
      if ischar(addlabel)
         tag = addlabel;
         addlabel = true;
      elseif isstring(addlabel)
         tag = addlabel;
         addlabel = true;
      else
         tag = "";
      end
      varargin([ipar,ipar+1]) = [];
   else
      addlabel = false;
      tag = "";
   end
else
   addlabel = false;
   tag = "";
end

if numel(varargin)>0
   ipar = strcmpi(varargin(1:2:end),'plotline');
   if any(ipar)
      ipar = 2*(find(ipar,1,'first')-1)+1;
      plotline = varargin{ipar+1};
      varargin([ipar,ipar+1]) = [];
   else
      plotline = true;
   end
else
   plotline = true;
end

if plotline
   hReg = line(ax,X,Y,'Color',c,'LineStyle','--',...
      'LineWidth',1.25,'Tag','Median Regression',varargin{:});
   hReg.Annotation.LegendInformation.IconDisplayStyle = 'off';
   if numel(varargin)>0
      if any(strcmpi(varargin(1:2:end),'DisplayName')) && ~addlabel
         hReg.Annotation.LegendInformation.IconDisplayStyle = 'on';
      else
         hReg.Annotation.LegendInformation.IconDisplayStyle = 'off';
      end
   else
      hReg.Annotation.LegendInformation.IconDisplayStyle = 'off';
   end
end

if addlabel
   expr = '%sR^2 = %4.2f';
   if ~isnan(weights(1))
      if any(weights~=1)
         expr = '%sR^2_{adj} = %4.2f';
      end
   end
   if TX < 15
      text(ax,TX,Y(1),sprintf('%sR^2 = %4.2f',tag,stat.R2),...
         'FontName','Arial','BackgroundColor','w',...
         'Color',c,'FontSize',12,'FontWeight','bold');
   else
      text(ax,TX,Y(end),sprintf('%sR^2 = %4.2f',tag,stat.R2),...
         'FontName','Arial','BackgroundColor','w',...
         'Color',c,'FontSize',12,'FontWeight','bold');
   end
end
stat = {stat};
Y = {reshape(Y,1,numel(Y))};
end