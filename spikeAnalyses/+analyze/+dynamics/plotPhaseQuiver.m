function fig = plotPhaseQuiver(M,varargin)
%PLOTPHASEQUIVER Plot the phase portrait given M the linearized system
%
%  fig = analyze.dynamics.plotPhaseQuiver(M);
%  fig = analyze.dynamics.plotPhaseQuiver(M,'Name',value,...);
%
% Inputs
%  M        - 2x2 matrix that is the linearized dynamical system coefficients
%  varargin - (Optional) <'Name',value> parameter argument pairs
%
% Output
%  fig      - Figure handle
%
% See also: Contents, population_firstorder_mls_regression_stats

pars = struct;
[xgc,ygc] = meshgrid(linspace(-2,2,5),linspace(-pi/2,pi/2,5));
pars.X0 = ([xgc(:), ygc(:)]); % Grid of initial conditions
[pars.XG,pars.YG] = meshgrid(linspace(-1.5*pi,1.5*pi,31),linspace(-1.5*pi,1.5*pi,31));
pars.X = [pars.XG(:),pars.YG(:)];
% pars.t = linspace(0,50*pi,101);
pars.t = 0:2.5:300; % Times from experiment (ms); M is scaled to those times

% Arrow parameters
% pars.ArrowScale = 0.85; %  Relative length of each "timestep" trajectory to trace
% pars.ArrowWidth = (pi./180) .* 15; % 15 degree excursion to edges of arrow
% pars.ArrowA = 0.70;   % Arrow "A-side" scalar using scaled magnitude
% pars.ArrowB = 0.70;   % Arrow "B-side" scalar using scaled magnitude
% pars.ArrowS = 0.75;  % Arrow base attachment depth relative to scaled magnitude
% pars.BreakArrows = true; % "NaNFlag" (break up arrows on coarse trajectories?)

pars.ArrowScale = 1; %  Relative length of each "timestep" trajectory to trace
pars.ArrowWidth = (pi./180) .* 2.5; % 15 degree excursion to edges of arrow
pars.ArrowA = 0.90;   % Arrow "A-side" scalar using scaled magnitude
pars.ArrowB = 0.90;   % Arrow "B-side" scalar using scaled magnitude
pars.ArrowS = 0.95;  % Arrow base attachment depth relative to scaled magnitude
pars.BreakArrows = false; % "NaNFlag" (break up arrows on coarse trajectories?)

% Line parameters
pars.LineWidth = 1.25;
pars.MarkerSize = 4;
pars.Position = [1.1 0.1 0.20 0.50];
pars.Color = [0.25 0.25 0.25];
pars.QuiverColor = [0.75 0.75 0.75];

% Figure/Axes parameters
pars.Title = '';
pars.LabelMaskRegion = [pi, 0.15*pi];
pars.XLim = [-5 5];
pars.YLim = [-5 5];

% Output
pars.FileName = '';

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

if iscell(M)
   if nargout > 0
      fig = gobjects(size(M));
      for ii = 1:numel(M)
         fig(ii) = analyze.dynamics.plotPhaseQuiver(M{ii},pars);
      end
   else
      for ii = 1:numel(M)
         analyze.dynamics.plotPhaseQuiver(M{ii},pars);
      end
   end
   return;
end

[V,~] = eig(M');
% lambda = diag(D);
fig = figure('Name','Phase Portrait Quiver',...
   'Color','w','Units','Normalized',...
   'Position',pars.Position,...
   'NumberTitle','off');
ax = axes(fig,...
   'XColor','k','YColor','k',...
   'XAxisLocation','origin','YAxisLocation','origin',...
   'LineWidth',1.5,'FontName','Arial','NextPlot','add',...
   'ColorOrder',[0 0 0],...
   'XTick',(-1.5*pi):(0.5*pi):(1.5*pi),...
   'YTick',(-1.5*pi):(0.5*pi):(1.5*pi),...
   'TickDir','both',...
   'XTickLabel',["","\bf\it-\pi","","","","\bf\it\pi",""],...
   'YTickLabel',["","\bf\it-\pi","","","","\bf\it\pi",""],...
   'XLim',pars.XLim,'YLim',pars.YLim);

f = @(X)M'*X;
if pars.BreakArrows
   k = 7;
   m = 5;
else
   k = 6;
   m = 4;
end
n = k*numel(pars.t);
mrk = m:k:n;

for ii = 1:size(pars.X0,1)
   x0 = pars.X0(ii,:);
%    [Xt,dXdt] = f(lambda,V,x0,pars.t);
   [~,Xt] = ode45(@(t,y)f(y),pars.t,x0');
   dXdt = Xt*M;
   theta = atan2(dXdt(:,2),dXdt(:,1))';
      
   r = sqrt(dXdt(:,1).^2 + dXdt(:,2).^2)';
   
   x = computeQuiverX(Xt(:,1)',theta,r.*pars.ArrowScale,...
      pars.ArrowWidth,pars.ArrowA,pars.ArrowB,pars.ArrowS,pars.BreakArrows);
   x = x(:);
   y = computeQuiverY(Xt(:,2)',theta,r.*pars.ArrowScale,...
      pars.ArrowWidth,pars.ArrowA,pars.ArrowB,pars.ArrowS,pars.BreakArrows); 
   y = y(:);      
   iRemove = checkLabelMaskRegion(x,pars.LabelMaskRegion,y) | ...
          checkLabelMaskRegion(y,pars.LabelMaskRegion,x);
   x(iRemove) = nan;
   y(iRemove) = nan;
   ic = line(ax,x0(1),x0(2),'LineStyle','none',...
      'Marker','o','MarkerSize',6,'MarkerFaceColor',[0.3 0.8 0.3],...
      'Color',[0.3 0.8 0.3],'DisplayName','Initial Condition');
   h = line(ax,x,y,...
      'Color',pars.Color,...
      'LineStyle','-',...
      'LineWidth',pars.LineWidth,...
      'MarkerIndices',mrk,...
      'Marker','.',...
      'MarkerSize',pars.MarkerSize,...
      'MarkerFaceColor',pars.Color,...
      'DisplayName',sprintf('%3d-ms trial',round(max(pars.t)))); 
end

dX = pars.X * M;
q = quiver(ax,pars.X(:,1),pars.X(:,2),dX(:,1),dX(:,2),...
   'LineWidth',1,...
   'DisplayName','\itdX/dt',...
   'Color',pars.QuiverColor);

aa = eye(2) \ V(:,1);
aX = [aa(1), -aa(1)] .* pars.XLim(2);
aY = [aa(2), -aa(2)] .* pars.YLim(2);
bb = eye(2) \ V(:,2);
bX = [bb(1), -bb(1)] .* pars.XLim(2);
bY = [bb(2), -bb(2)] .* pars.YLim(2);

if all(real(aY)==real(bY))
   a = line(ax,[imag(aX(1)) 0 imag(aX(2))],[imag(aY(1)) 0 imag(aY(2))],...
      'LineWidth',3,'Color','b','LineStyle',':','MarkerIndices',2,...
      'Marker','o','MarkerFaceColor','b','DisplayName','\itv_1');
else
   a = line(ax,real(aX),real(aY),...
      'LineWidth',3,'Color','b','LineStyle','--','DisplayName','\itv_1');
end

if all(real(aY)==real(bY))
   b = line(ax,real(bX),real(bY),...
      'LineWidth',3,'Color','r','LineStyle',':',...
      'MarkerFaceColor','r','DisplayName','\itv_2');
else
   b = line(ax,real(bX),real(bY),...
      'LineWidth',3,'Color','r','LineStyle','--','DisplayName','\itv_2');
end


legend([h;ic;q;a;b],...
   'TextColor','black','FontName','Arial','Location','southeast',...
   'AutoUpdate','off');

if ~isempty(pars.Title)
   title(ax,pars.Title,'FontName','Arial','Color','k');
end

if ~isempty(pars.FileName)
   fprintf(1,'Saving <strong>%s</strong>...',pars.FileName);
   saveas(fig,[pars.FileName '.png']);
   savefig(fig,[pars.FileName '.fig']);
   fprintf(1,'complete\n\n');
   if nargout < 1
      pause(1.5);
      delete(fig);
   end
end

   function iRemove = checkLabelMaskRegion(data,maskRegionArray,oppositeAxesData)
      iRemove = false(size(data));
      data(isnan(data)) = 0;
      for iLabel = 1:size(maskRegionArray,1)
         iDataInRange = abs(abs(data)-maskRegionArray(iLabel,1)) < maskRegionArray(iLabel,2);
         iOppDataInRange = (abs(oppositeAxesData) - 2*maskRegionArray(iLabel,2)) < 0;
         iRemove(iDataInRange & iOppDataInRange) = true;
      end
   end

   function x = computeQuiverX(X,theta,r,K,A,B,S,nanFlag)
      if nanFlag
         x = [nan(1,numel(X)); ...                   % "break up" each arrow
              X       ; ...                   % "base" of arrow
              X + r.*cos(theta);  ....        % "tip" of arrow
              X + r.*cos(theta+K).*A;  ...  % "side-A" of arrow
              X + r.*cos(theta).*S; ...     % "shallow" side of arrow
              X + r.*cos(theta-K).*B;  ...  % "side-B" of arrow
              X + r.*cos(theta);  ....        % "tip" of arrow
              ];  
      else
         x = [ ...                   
              X       ; ...                   % "base" of arrow
              X + r.*cos(theta);  ....        % "tip" of arrow
              X + r.*cos(theta+K).*A;  ...  % "side-A" of arrow
              X + r.*cos(theta).*S; ...     % "shallow" side of arrow
              X + r.*cos(theta-K).*B;  ...  % "side-B" of arrow
              X + r.*cos(theta);  ....        % "tip" of arrow
              ];   
      end
   end

   function y = computeQuiverY(Y,theta,r,K,A,B,S,nanFlag)
      if nanFlag
         y = [nan(1,numel(Y)); ...                   % "break up" each arrow
              Y       ; ...                   % "base" of arrow
              Y + r.*sin(theta);  ....        % "tip" of arrow
              Y + r.*sin(theta+K).*A;  ...  % "side-A" of arrow
              Y + r.*sin(theta).*S; ...     % "shallow" side of arrow
              Y + r.*sin(theta-K).*B;  ...  % "side-B" of arrow
              Y + r.*sin(theta);  ....        % "tip" of arrow
              ];
      else
         y = [ ...                   
           Y       ; ...                   % "base" of arrow
           Y + r.*sin(theta);  ....        % "tip" of arrow
           Y + r.*sin(theta+K).*A;  ...  % "side-A" of arrow
           Y + r.*sin(theta).*S; ...     % "shallow" side of arrow
           Y + r.*sin(theta-K).*B;  ...  % "side-B" of arrow
           Y + r.*sin(theta);  ....        % "tip" of arrow
           ];
      end
   end

%    function [Xt,dXdt,C,t] = f(lambda,V,x0,t)
%       if nargin < 4
%          t = linspace(0,pi,100);
%       end
%       if iscolumn(t)
%          t = t.';
%       end
%       dt = diff(t,1,2);
%       
%       C = V\x0;
%       
%       xt = C(1).*exp(lambda(1).*t).*V(:,1) + C(2).*exp(lambda(2).*t).*V(:,2);
%       dXdt = diff(xt,1,2)./dt;
%       Xt = (xt(:,1:(end-1)) + xt(:,2:end))./2;
%    end

   function Y = g(M,X)
      Y = X * M;
   end
   
end