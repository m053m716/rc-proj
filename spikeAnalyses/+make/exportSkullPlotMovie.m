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
pars = defaults.movies('single_skull');

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

% Iterate if given multiple trials %
if numel(pars.trial) > 1
   thisPars = pars;
   for ii = 1:numel(pars.trial)
      thisPars.trial = pars.trial(ii);
      make.exportSkullPlotMovie(P,thisPars);
   end
   return;
end

% Iterate if given multiple planes %
if numel(pars.plane) > 1
   thisPars = pars;
   for ii = 1:numel(pars.plane)
      thisPars.plane = pars.plane(ii);
      make.exportSkullPlotMovie(P,thisPars);
   end
   return;
end

if isnan(pars.trial)
   pars.trial = 1;
   useXCmean = true; % "Use XC Mean" as in plot mean average trajectory
else
   useXCmean = false;
end
p = P(pars.trial);
if isnan(pars.plane)
   pars.plane = min(randi(floor(size(p.W,2)/2),1,1),3);
end

% % % End input parsing; get metadata about THIS trial % % %

if useXCmean
   Name = [p.AnimalID sprintf('--%s--Post-Op-D%02d--Average',p.Alignment,p.PostOpDay)];
else
   Name = [p.AnimalID sprintf('--%s--Post-Op-D%02d',p.Alignment,p.PostOpDay)];
end
t = p.times; % Get time of occurrence for each data point
GroupID = p.Group;
pname = fullfile(pars.pname,pars.sub_folder);
if exist(pname,'dir')==0
   mkdir(pname);
end

if useXCmean
   trialStr = 'Average';
   fname = sprintf(pars.expr,Name,pars.plane,trialStr,pars.tag);
else
   trialStr = sprintf('Trial-%03d',pars.trial);
   fname = sprintf(pars.expr,Name,pars.plane,trialStr,pars.tag);
end
fname_full = fullfile(pname,fname);

% Get relevant subset of electrodes table %
CID = p.CID;
nCh = size(CID,1);
X = CID.X;
Y = CID.Y;
icms_flag = any(strcmpi(CID.Properties.VariableNames,'ICMS'));

% Set convention for always showing RFA on bottom and CFA on top, since it
% is easiest to just draw the injection sites on the bottom each time and
% either color them in or not.
Y(CID.Area=="RFA") = -abs(Y(CID.Area=="RFA")); % Put RFA always on bottom
Y(CID.Area=="CFA") =  abs(Y(CID.Area=="CFA")); % Put CFA always on top

% % Get relevant data from array struct % %
switch lower(pars.ProjType)
   case 'jpc'
      projSS = 'skew';
      wField = 'W';
   otherwise
      projSS = 'best';
      wField = 'W_best';
end
sortBy = lower(pars.SortBy);
errField = sprintf('W_%s_res',projSS);
pIdx = p.misc.(projSS).explained.sort.vec.(sortBy)([2*(pars.plane-1)+1, 2*pars.plane]);

% % If trial is NaN, then just show the cross-condition mean % %
if useXCmean
   % Get cross-trial mean as well as cross-condition mean.
   mu = nanmean(cat(3,P.data),3);
   p.data = mu;
   if icms_flag % Then it should go by individual channels
      Proj = analyze.jPCA.recover_channel_weights(p,...
         'subtract_mean',false,...
         'subtract_xc_mean',pars.subtract_xc_mean);
   else
      Proj = analyze.jPCA.recover_channel_weights(p,...
         'groupings','Area',...
         'subtract_mean',false,...
         'subtract_xc_mean',pars.subtract_xc_mean);
   end
   W = real(Proj.(wField)(:,pIdx,:)) + imag(p.(wField)(:,pIdx,:));
   ERR = Proj.(errField);
else
   Proj = P;
   W = real(p.(wField)(:,pIdx,:)) + imag(p.(wField)(:,pIdx,:));
   ERR = p.(errField);
end

% Create graphics objects
labs = {'jPC-X'; 'jPC-Y'; 'Residual'};

varCapt = nanmean(p.misc.(projSS).explained.varcapt(pIdx));
eigCapt = nansum(p.misc.(projSS).explained.eig(pIdx));
dataStr = sprintf('Data Captured: %4.1f%% | R^2_{mean}: %4.2f',...
                  eigCapt,varCapt/100);
               
% % Create the axes layout % %
gObj = make.fig.skullLayout(...
   2, ...            % # Rows
   3, ...            % # Columns 
   {1,[2,3]}, ...    % Axes indices for "non-skull" subplots
   {4,5,6}, ...      % Axes indices for "Skull" subplots
   'Name',Name, ...  % Begin <'ParamName',ParamValue> pairs
   'Units',pars.Units, ...
   'Position',pars.Position, ...
   'GroupID',{GroupID}, ... 
   'SkullLabel',labs, ...
   'SkullTitle',{dataStr; ''; '||Error Contribution||'});
% % % % % % % % % % % % % % % %

fig = gObj.Figure;
set(gObj.NonSkullAxes(1).XLabel,'String','jPC-X',...
   'Color','w',...
   'FontName','Arial',...
   'FontSize',14,...
   'FontWeight','bold',...
   'Visible','on');
set(gObj.NonSkullAxes(1).YLabel,'String','jPC-Y',...
   'Color','w',...
   'FontName','Arial',...
   'FontSize',14,...
   'FontWeight','bold',...
   'Visible','on');

pars.TrajParams.Animal = p.AnimalID;
pars.TrajParams.Alignment = p.Alignment;
pars.TrajParams.Day = p.PostOpDay;
pars.TrajParams.Area = "Successes Only";
pars.TrajParams.Figure = fig;
pars.TrajParams.Axes = gObj.NonSkullAxes(1);
pars.TrajParams.phaseSpaceAx = gObj.NonSkullAxes(1);
pars.TrajParams.plane2plot = pars.plane; 
pars.TrajParams.rankType = sortBy;
pars.TrajParams.projType = projSS;
pars.TrajParams.projField = pars.ProjField;

if useXCmean
   pars.TrajParams.highlight_trial = [];
else
   pars.TrajParams.highlight_trial = pars.trial;
end
colormap(gObj.NonSkullAxes(1),pars.ColorMap);

set(gObj.SkullAxes(2).Title,'FontSize',pars.TimeFontSize);

% Initialize "Channel" or "Group" scatters
if icms_flag
   w_a = makeSizeData(squeeze(W(:,1,:))','zscore');
   w_b = makeSizeData(squeeze(W(:,2,:))','zscore');
   w_e = makeSizeData(squeeze(nanmean(abs(ERR),2))','zscore');
   for iObj = 1:numel(gObj.SkullObj)
      addScatterGroup_ICMS(gObj.SkullObj(iObj),...
         X,Y,pars.InitSize,string(CID.ICMS));
   end
else
   [w_a,pol_a] = makeSizeData(squeeze(W(:,1,:))',pars.SizeMethod);
   [w_b,pol_b] = makeSizeData(squeeze(W(:,2,:))',pars.SizeMethod);
   w_e = makeSizeData(squeeze(nanmean(abs(ERR),2))',pars.SizeMethod);
   for iObj = 1:numel(gObj.SkullObj)
      addScatterGroup(gObj.SkullObj(iObj),...
         X,Y,pars.InitSize,repmat(pars.GroupColors(3,:),nCh,1),'Group');
   end
end

% % Add axes with plot of what the trial-average jPCs look like:
ax = gObj.NonSkullAxes(2);
if useXCmean
   score = (mu / p.misc.PCs');
   if strcmpi(pars.ProjType,'skew')
      avg = score(:,1:size(p.misc.Mskew,1)) * analyze.jPCA.convert_Mskew_to_jPCs(p.misc.Mskew);
   else
      avg = real(score(:,1:size(p.misc.Mskew,1)) * p.misc.Mbest);
   end
   ax.NextPlot = 'add';
   hMu = line(ax,avg(:,pIdx(1)),avg(:,pIdx(2)),...
      'LineWidth',2,'Color','m','Marker','o','MarkerFaceColor','y',...
      'MarkerIndices',[],'MarkerSize',10,...
      'DisplayName',sprintf('Plane-%02d_{mean}',pars.plane));
   pars.rosette = defaults.jPCA('rosette_params');
   pars.rosette.Arrow.Axes = ax;
   pars.rosette.Arrow.FaceColor = [1 0 1];
   pars.rosette.Arrow.BaseSize = 16;
   pars.rosette.Arrow.RoughScale = 0.015;
   
   analyze.jPCA.arrowMMC(...
      nanmean([avg((end-10):(end-5),pIdx(1)),avg((end-10):(end-5),pIdx(2))],1),... % "point"
      nanmean([avg((end-5):end,pIdx(1)),avg((end-5):end,pIdx(2))],1),... % "nextpoint"
      pars.rosette);
   pr = cat(3,P.(pars.ProjField));
   xPr = squeeze(pr(:,pIdx(1),:));
   yPr = squeeze(pr(:,pIdx(2),:));
   line(ax,xPr(:,1),yPr(:,1),...
      'Color','c','LineStyle','-','LineWidth',1.75,'DisplayName',...
      'Trial');
   pars.rosette.Arrow.FaceColor = [0 1 1];
   analyze.jPCA.arrowMMC(...
      nanmean([xPr((end-10):(end-5),1),yPr((end-10):(end-5),1)],1),... % "point"
      nanmean([xPr((end-5):end,1),yPr((end-5):end,1)],1),... % "nextpoint"
      pars.rosette);
   if size(pr,3) > 1
      for iTrial = 2:size(pr,3)
         hl = line(ax,xPr(:,iTrial),yPr(:,iTrial),...
            'Color','c','LineStyle','-','LineWidth',1.75,'DisplayName',...
            'Trial');
         hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
         analyze.jPCA.arrowMMC(...
            nanmean([xPr((end-10):(end-5),iTrial),yPr((end-10):(end-5),iTrial)],1),... % "point"
            nanmean([xPr((end-5):end,iTrial),yPr((end-5):end,iTrial)],1),... % "nextpoint"
            pars.rosette);
      end
   end
   
   ax.Title.String = sprintf('All Trials: Plane-%02d',pars.plane);
else
   pr = p.(pars.ProjField);
   ax.XLim = [t(1), t(end)];
   ax.NextPlot = 'add';
   hMu = gobjects(2,1);
   hMu(1) = line(ax,t,pr(:,pIdx(1)),'Color','m','LineWidth',2.5,...
      'DisplayName','jPC-X',...
      'LineStyle','-.','Marker','o','MarkerFaceColor','y',...
      'MarkerIndices',[],'MarkerSize',10);
   hMu(2) = line(ax,t,pr(:,pIdx(2)),'Color','m','LineWidth',2.5,...
      'DisplayName','jPC-Y',...
      'LineStyle',':','Marker','o','MarkerFaceColor','y',...
      'MarkerEdgeColor','k','MarkerIndices',[],'MarkerSize',10);
   if ~isnan(p.graspIndex)
      hl = line(ax,ones(1,2).*t(p.graspIndex),ax.YLim * 0.75,'LineStyle',':',...
         'LineWidth',2,'Color',[0.5 0.5 0.5],'DisplayName','Grasp');
      hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
      text(ax,t(p.graspIndex),ax.YLim(2)*0.775,'Grasp',...
         'FontName','Arial','Color',[0.5 0.5 0.5],'Margin',5,...
         'FontWeight','bold','FontSize',12,'BackgroundColor','k',...
         'VerticalAlignment','bottom','HorizontalAlignment','center');
   end
   if ~isnan(p.reachIndex)
      hl = line(ax,ones(1,2).*t(p.reachIndex),ax.YLim * 0.75,'LineStyle',':',...
         'LineWidth',2,'Color',[0.75 0.75 0.75],'DisplayName','Reach');
      hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
      text(ax,t(p.reachIndex),ax.YLim(1)*0.775,'Reach',...
         'FontName','Arial','Color',[0.75 0.75 0.75],'Margin',5,...
         'FontWeight','bold','FontSize',12,'BackgroundColor','k',...
         'VerticalAlignment','top','HorizontalAlignment','center');
   end
   if ~isnan(p.supportIndex)
      hl = line(ax,ones(1,2).*t(p.supportIndex),ax.YLim * 0.75,'LineStyle',':',...
         'LineWidth',2,'Color',[1.00 1.00 1.00],'DisplayName','Support');
      hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
      text(ax,t(p.supportIndex),ax.YLim(1)*0.775,'Support',...
         'FontName','Arial','Color',[1.00 1.00 1.00],'Margin',5,...
         'FontWeight','bold','FontSize',12,'BackgroundColor','k',...
         'VerticalAlignment','top','HorizontalAlignment','center');
   end
   ax.Title.String = sprintf('Trial-%03d::Plane-%02d',...
      pars.trial,pars.plane);
end
legend(ax,'Location','Northwest','TextColor','w','FontName','Arial',...
      'Box','off','Color',[0 0 0],'FontWeight','bold','FontSize',10);
tBar = [t(end),t(end)-250];
hl = line(ax,tBar,ones(1,2).*ax.YLim(2)*0.9,'Color','g',...
      'LineWidth',2.5,'LineStyle','-','DisplayName','100-ms');
hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
text(ax,mean(tBar),ax.YLim(2)*0.95,'250-ms','Color','g',...
   'FontName','Arial','BackgroundColor','k','VerticalAlignment','bottom',...
   'HorizontalAlignment','Center','FontWeight','bold');


% % Create VideoWriter object % %
v = VideoWriter(fname_full,pars.profile);
v.FrameRate = pars.FrameRate;
open(v);
tic;
tPrev = t(1);
eventIndices = [p.reachIndex, p.graspIndex, p.completeIndex, p.supportIndex];
eventTimes = t(eventIndices(~isnan(eventIndices)));
eventNames = ["Reach","Grasp","Complete","Support"];
eventNames(isnan(eventIndices)) = [];

nRepeatFrames = round(pars.FrameRate * pars.EventPauseDuration);
hl_marker = line(gObj.NonSkullAxes(1),nan,nan,'Marker','s',...
   'MarkerFaceColor','none','Color','y','LineWidth',2.5,...
   'MarkerSize',48,'MarkerEdgecolor','y');
hl_marker.Annotation.LegendInformation.IconDisplayStyle = 'off';
hl_label = text(gObj.NonSkullAxes(1),nan,nan,"",...
   'BackgroundColor','black','Color','y','FontName','Arial',...
   'FontSize',14,'FontWeight','bold');

if icms_flag
   for ii = 1:numel(t)
      if ii >= 3
         tStart = find(t >= (t(ii)-pars.TrajParams.tail),1,'first');
         % only times that match one of these will be used
         pars.TrajParams.times = t(tStart:ii);
         pars.TrajParams = analyze.jPCA.phaseSpace_min(Proj,pars.TrajParams);
      end

      % Update time in title to show time-lapse rate
      eventFlag = eventTimes == t(ii);
      if ((t(ii) - tPrev) > pars.TimeTextUpdateIncrement) || any(eventFlag)
         gObj.SkullAxes(2).Title.String = sprintf('%5.1f (ms)',t(ii));
         tPrev = t(ii);
      end
      set(hMu,'MarkerIndices',ii);
      
      % Update sizes only
      changeScatterGroupSizeData(gObj.SkullObj(1),w_a(:,ii));
      changeScatterGroupSizeData(gObj.SkullObj(2),w_b(:,ii));
      changeScatterGroupSizeData(gObj.SkullObj(3),w_e(:,ii));
      drawnow;
      writeVideo(v,getframe(fig));
      if any(eventFlag)
         set(hl_marker,...
            'XData',p.(pars.ProjField)(ii,pIdx(1)),...
            'YData',p.(pars.ProjField)(ii,pIdx(2)));
         set(hl_label,...
            'Position',[p.(pars.ProjField)(ii,pIdx(1)),...
                        p.(pars.ProjField)(ii,pIdx(2))+0.5,0],...
            'String',eventNames(eventFlag));
         for iRepeat = 1:floor(nRepeatFrames/2)
            set(hMu,'MarkerSize',min(hMu(1).MarkerSize+1,20));
            set(hl_marker,'MarkerSize',max(hl_marker.MarkerSize-2,24));
            drawnow;
            writeVideo(v,getframe(fig));
         end
         for iRepeat = ceil(nRepeatFrames/2):nRepeatFrames
            set(hMu,'MarkerSize',max(hMu(1).MarkerSize-1,10));
            set(hl_marker,'LineWidth',min(hl_marker.MarkerSize+0.1,3.5));
            drawnow;
            writeVideo(v,getframe(fig));
         end
         set(hl_label,'Position',[nan,nan,0],'String',"");
         set(hl_marker,'XData',nan,'YData',nan,...
            'MarkerSize',48,'LineWidth',2.5);
      end
   end
else
   % COLORS : 1 -> Negative -> Red | 2 -> Positive -> Blue %
   col_A = round(pol_a/2 + 1.5); 
   col_B = round(pol_b/2 + 1.5);  
   w_a = num2cell(w_a);
   w_b = num2cell(w_b);
   w_e = num2cell(w_e);
   A = flipud(get(getScatterGroup(gObj.SkullObj(1),'Group'),'Children'));
   B = flipud(get(getScatterGroup(gObj.SkullObj(2),'Group'),'Children'));
   E = flipud(get(getScatterGroup(gObj.SkullObj(3),'Group'),'Children'));
   NameArray = {'SizeData','CData'};
   
   for ii = 1:numel(t)
      if ii >= 3
         tStart = find(t >= (t(ii)-pars.TrajParams.tail),1,'first');
         % only times that match one of these will be used
         pars.TrajParams.times = t(tStart:ii);
         pars.TrajParams = analyze.jPCA.phaseSpace_min(Proj,pars.TrajParams);
      end

      % Update times in title to show time-lapse rate
      eventFlag = eventTimes == t(ii);
      if ((t(ii) - tPrev) > pars.TimeTextUpdateIncrement) || any(eventFlag)
         gObj.SkullAxes(2).Title.String = sprintf('%5.1f (ms)',t(ii));
         tPrev = t(ii);
      end
      set(hMu,'MarkerIndices',ii);
      
      % Update both color and size
      ValueArrayA = ...
         [w_a(:,ii), mat2cell(pars.GroupColors(col_A(:,ii),:),...
                              ones(1,nCh),3)];
      ValueArrayB = ...
         [w_b(:,ii), mat2cell(pars.GroupColors(col_B(:,ii),:),...
                              ones(1,nCh),3)];
      set(A,NameArray,ValueArrayA);
      set(B,NameArray,ValueArrayB);
      set(E,{'SizeData'},w_e(:,ii));
      drawnow;
      writeVideo(v,getframe(fig));
      if any(eventFlag)
         set(hl_marker,...
            'XData',p.(pars.ProjField)(ii,pIdx(1)),...
            'YData',p.(pars.ProjField)(ii,pIdx(2)));
         set(hl_label,...
            'Position',[...
               p.(pars.ProjField)(ii,pIdx(1)),...
               p.(pars.ProjField)(ii,pIdx(2))+0.5,0],...
            'String',eventNames(eventFlag));
         for iRepeat = 1:floor(nRepeatFrames/2)
            set(hMu,'MarkerSize',min(hMu(1).MarkerSize+1,20));
            set(hl_marker,'MarkerSize',max(hl_marker.MarkerSize-2,24));
            drawnow;
            writeVideo(v,getframe(fig));
         end
         for iRepeat = ceil(nRepeatFrames/2):nRepeatFrames
            set(hMu,'MarkerSize',max(hMu(1).MarkerSize-1,10));
            set(hl_marker,'LineWidth',min(hl_marker.MarkerSize+0.1,3.5));
            drawnow;
            writeVideo(v,getframe(fig));
         end
         set(hl_label,'Position',[nan,nan,0],'String',"");
         set(hl_marker,'XData',nan,'YData',nan,...
            'MarkerSize',48,'LineWidth',2.5);
      end
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
