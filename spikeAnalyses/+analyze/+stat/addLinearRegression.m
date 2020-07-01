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
      'yhat',[],'pts',struct,'f',@(x)x)};
   return;
end

% Get differences and median slope, intercept
dY = pdist(y,@(y1,y2)minus(y1,y2));
dX = pdist(x,@(x1,x2)minus(x1,x2));
iBad = isinf(dY) | isinf(dX) | isnan(dY) | isnan(dX);
if ~any(~iBad)
   Y = {nan(size(X))};
   stat = {struct('R2',nan,'RSS',nan,'TSS',nan,'x',[],'y',[],...
      'yhat',[],'pts',struct,'f',@(x)x)};
   return;
end
Beta  = median(dY(~iBad) ./ dX(~iBad));
Beta0 = median(y);
x0 = median(x);
f   = @(x)reshape(Beta0 + Beta.*(x - x0),numel(x),1);

% Plot
Y = f(X);
stat = struct;
[stat.R2,stat.RSS,stat.TSS] = analyze.stat.getR2(f,x,y);
stat.x = x;
stat.y = y;
stat.yhat = f(x);
stat.pts = struct('X',X,'Y',Y);
stat.f = f;

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
end

if addlabel
   text(ax,TX,Y(end),sprintf('%sR^2 = %4.2f',tag,stat.R2),...
      'FontName','Arial',...
      'Color',c,'FontSize',12);
end
stat = {stat};
Y = {reshape(Y,1,numel(Y))};
end