function exportSkullPlotMovie(P,varargin)
%EXPORTSKULLPLOTMOVIE Export evolution of "skull plot" for values over time
%
%  make.exportSkullPlotMovie(P,__,'name',value,...);
%
% Inputs
%  P        - Projection array struct
%  varargin - Optional 'name',value pairs
%
% Output
%  -- none -- Produces an exported video with spatial data coregistered on
%              the skull layout based on electrode coordinates.
%
% See also: ratskull_plot, make.fig.skullPlot, 
%           make.exportSkullPlotMovie/makeSizeData

% % Parse inputs % %
pars = struct;
pars.Position = [0.2 0.2 0.3 0.5];
pars.SizeMethod = 'square';
pars.Units = 'Normalized';
pars.plane = nan;
pars.trial = nan;
pars.InitSize = 30;
pars.covXLim = [1 31];
pars.covYLim = [0 100];
pars.font_params = {'FontName','Arial','FontWeight','bold','Color','w'};
pars.FrameRate = 10;
pars.gcol = [1 0 0; ... % index 1: blue
             0 0 1];    % index 2: red
pars.traj = defaults.jPCA('movie_params');
[pars.pname,pars.expr] = ...
   defaults.files('movie_loc','movie_fname_expr');

fn = fieldnames(pars);
if numel(varargin) >= 1
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

% % Parse inputs from table if 'MultiJPCA' table is given % %
if istable(P)
   if utils.check_table_type(P,'MultiJPCA')
      P = analyze.jPCA.recover_channel_weights(D,varargin{:});
   else
      error('Invalid table type, should be result of `multi_jPCA`');
   end
end

% Iterate if given as cell array %
if iscell(P)
   for ii = 1:numel(P)
      make.exportSkullPlotMovie(P{ii},pars);
   end
   return;
end

if isnan(pars.trial) 
   pars.trial = randi(numel(P),1,1);
end

p = P(pars.trial);

if isnan(pars.plane)
   pars.plane = min(randi(floor(size(p.W,2)/2),1,1),3);
end
Name = [p.AnimalID sprintf('--%s--Post-Op-D%02d',p.Alignment,p.PostOpDay)]; 
t = p.times; % Get time of occurrence for each data point
GroupID = p.Group;
if exist(pars.pname,'dir')==0
   mkdir(pars.pname);
end
fname = sprintf(pars.expr,Name,pars.plane,pars.trial);
fname_full = fullfile(pars.pname,fname);

% % Get relevant data from array struct % %
% rate = p.data';
pIdx = [2*(pars.plane-1)+1, 2*pars.plane];
W = p.W(:,pIdx,:);

% Get relevant subset of electrodes table %
CID = p.CID;
nCh = size(CID,1);
X = CID.X;
Y = CID.Y;

Y(CID.Area=="RFA") = -abs(Y(CID.Area=="RFA")); % Put RFA always on bottom
Y(CID.Area=="CFA") =  abs(Y(CID.Area=="CFA")); % Put CFA always on top

% Make graphics objects containers for movie %
fig = figure(...
   'Name',Name,...
   'Units',pars.Units,...
   'Position',pars.Position,...
   'Color',[0 0 0],...
   'NumberTitle','off',...
   'MenuBar','none',...
   'Toolbar','none');
figure(fig);

% Top plot
ax_top = subplot(2,2,[1,2]);
set(ax_top,'XTick',[],'YTick',[],'XLim',[-5 5],'YLim',[-5 5],...
   'NextPlot','add','Parent',fig,...
   'XColor','none','YColor','none','Color','k');
pars.traj.Axes = ax_top;
pars.traj.phaseSpaceAx = ax_top;
pars.traj.min_trials = 0;
pars.traj.Animal = p.AnimalID;
pars.traj.Alignment = p.Alignment;
pars.traj.Day = p.PostOpDay;
pars.traj.Area = "Successes Only";
pars.traj.Figure = fig;
pars.traj.tail = 100;
pars.traj.plane2plot = pars.plane;
pars.traj.highlight_trial = pars.trial;
colormap(ax_top,'cool');

% Bottom-left is for first component of jPC plane %
ax_bot_left = subplot(2,2,3); 
set(ax_bot_left,'XTick',[],'YTick',[],'FontName','Arial',...
   'Color','none','NextPlot','add','Parent',fig);
ratSkullObj_A = make.fig.skullPlot(GroupID,'axes',ax_bot_left);
str = sprintf(' (jPC-%02d_x)',pars.plane);
title(ax_bot_left,Name,pars.font_params{:});
ylabel(ax_bot_left,str,pars.font_params{:});
ratSkullObj_A.Name = str;

% Bottom-right is for second component of jPC plane %
ax_bot_right = subplot(2,2,4); 
set(ax_bot_right,'XTick',[],'YTick',[],...
   'YAxisLocation','right','FontName','Arial',...
   'Color','none','NextPlot','add','Parent',fig);
str = sprintf(' (jPC-%02d_y)',pars.plane);
ratSkullObj_B = make.fig.skullPlot(GroupID,'axes',ax_bot_right);
% title(ax_bot,str,'FontName','Arial','FontWeight','bold','Color','k');
ttxt = title(ax_bot_right,'',pars.font_params{:},'FontSize',24);
ylabel(ax_bot_right,str,pars.font_params{:});
ratSkullObj_B.Name = str;

set(fig,'Color',[0 0 0]);

% Initialize "Channel" or "Group" scatters
icms_flag = any(strcmpi(CID.Properties.VariableNames,'ICMS'));
if icms_flag
   w_a = makeSizeData(squeeze(W(:,1,:))','zscore');
   w_b = makeSizeData(squeeze(W(:,2,:))','zscore');
   ratSkullObj_A.addScatterGroup_ICMS(X,Y,pars.InitSize,string(CID.ICMS)); 
   ratSkullObj_B.addScatterGroup_ICMS(X,Y,pars.InitSize,string(CID.ICMS)); 
else
   [w_a,pol_a] = makeSizeData(squeeze(W(:,1,:))',pars.SizeMethod);
   [w_b,pol_b] = makeSizeData(squeeze(W(:,2,:))',pars.SizeMethod);
   addScatterGroup(ratSkullObj_A,X,Y,pars.InitSize,zeros(nCh,3),'Group'); 
   addScatterGroup(ratSkullObj_B,X,Y,pars.InitSize,zeros(nCh,3),'Group'); 
end

% % Create VideoWriter object % %
v = VideoWriter(fname_full);
v.FrameRate = pars.FrameRate;
open(v);
tic;
if icms_flag
   for ii = 1:numel(t)
      if ii >= 3
         tStart = find(t >= (t(ii)-pars.traj.tail),1,'first');
         % only times that match one of these will be used
         pars.traj.times = t(tStart:ii);
         pars.traj = analyze.jPCA.phaseSpace(P,pars.traj);
      end
      
      % Update time in title to show time-lapse rate
      ttxt.String = sprintf('%5.1f (ms)',t(ii));
      
      % Update sizes only
      changeScatterGroupSizeData(ratSkullObj_A,w_a(:,ii));
      changeScatterGroupSizeData(ratSkullObj_B,w_b(:,ii));
      drawnow;
      writeVideo(v,getframe(fig));
   end
else
   col_A = round(pol_a/2 + 1.5); % 1 -> Negative -> Red
   col_B = round(pol_b/2 + 1.5); % 2 -> Positive -> Blue
   w_a = num2cell(w_a);
   w_b = num2cell(w_b);
   A = flipud(get(getScatterGroup(ratSkullObj_A,'Group'),'Children'));
   B = flipud(get(getScatterGroup(ratSkullObj_B,'Group'),'Children'));
   NameArray = {'SizeData','CData'};
   for ii = 1:numel(t)
      if ii >= 3
         tStart = find(t >= (t(ii)-pars.traj.tail),1,'first');
         % only times that match one of these will be used
         pars.traj.times = t(tStart:ii);
         pars.traj = analyze.jPCA.phaseSpace(P,pars.traj);
      end
      
      % Update times in title to show time-lapse rate
      ttxt.String = sprintf('%5.1f (ms)',t(ii));
      
      % Update both color and size
      ValueArrayA = ...
         [w_a(:,ii), mat2cell(pars.gcol(col_A(:,ii),:),ones(1,nCh),3)];
      ValueArrayB = ...
         [w_b(:,ii), mat2cell(pars.gcol(col_B(:,ii),:),ones(1,nCh),3)];
      set(A,NameArray,ValueArrayA);
      set(B,NameArray,ValueArrayB);
      drawnow;
      writeVideo(v,getframe(fig));
   end
end
fprintf(1,'Finished spatial activations movie for %s.\n',Name);
toc;
close(v);
delete(fig);
delete(v);

   function [sz,pol] = makeSizeData(W,type)
      %MAKESIZEDATA Transform jPCA weights to size data
      %
      %  [sz,pol] = makeSizeData(W,type);
      %
      % Inputs
      %  W     - jPCA weights
      %  type  - 'zscore' | 'square' | 'meansquare'
      %     * 'zscore' : scale by mean, standard deviation, then rescale to
      %                  only positive value range using fixed constants.
      %                 -> Uses `min` and `max` to constrain allowed output
      %                       value ranges
      %     * 'square' : scale using fixed constant times square of
      %                  observed values, plus some offset representing the
      %                  minimum allowed size.
      %     * 'meansquare' : Same as 'square' but uses square deviations
      %                       from mean value instead of from zero.
      %
      % Output
      %  sz    - Transformed so that it's a positive value for each W
      %  pol   - "Polarity" (sign) of each value of W
      %
      % See also: make.exportSkullPlotMovie
      
      pol = sign(W);
      switch lower(type)
         case {'zscore','z','normalize'}
            z = (W - mean(W,2))./std(W,[],2);
            sz = min(max(z .* 150 + 12,4),64);
         case {'square','s'}
            sz = W.^2 .* 2048 + 32;
         case {'meansquare','ms'}
            z = W - mean(W,2);
            sz = z.^2 .* 2048 + 32;
         otherwise 
            error('Unexpected case: <strong>"%s"</strong>',type);
      end
   end
end