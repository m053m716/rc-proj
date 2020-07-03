function exportSkullPlotMovie(P,Te,CID,varargin)
%EXPORTSKULLPLOTMOVIE Export evolution of "skull plot" for values over time
%
%  make.exportSkullPlotMovie(Td
%
% Inputs
%  P        - Projection array struct
%  Te       - Electrode organization table
%  CID      - Channel ID data table. If P is cell array, then this should
%              be cell array of same size.
%  varargin - Optional 'name',value pairs
%
% Output
%  -- none -- Produces an exported video with spatial data coregistered on
%              the skull layout based on electrode coordinates.
%
% See also: ratskull_plot, make.fig.skullPlot

% % Parse inputs % %
pars = struct;
pars.Position = [0.2 0.2 0.3 0.5];
pars.Units = 'Normalized';
pars.plane = 1;
pars.trial = 1;
pars.InitSize = 30;
pars.covXLim = [1 31];
pars.covYLim = [0 100];
pars.FrameRate = 10;
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

% Iterate if given as cell array %
if iscell(P)
   for ii = 1:numel(P)
      make.exportSkullPlotMovie(P{ii},Te,CID{ii},pars);
   end
   return;
end

Name = [P(pars.trial).AnimalID sprintf('--Post-Op-D%02d',P(pars.trial).PostOpDay)]; 
t = P(pars.trial).times; % Get time of occurrence for each data point
GroupID = P(pars.trial).Group;
if exist(pars.pname,'dir')==0
   mkdir(pars.pname);
end
fname = sprintf(pars.expr,Name,pars.plane,pars.trial);
fname_full = fullfile(pars.pname,fname);

% % Get relevant data from array struct % %
% rate = P(pars.trial).data';
pIdx = [2*(pars.plane-1)+1, 2*pars.plane];
W = P(pars.trial).W(:,pIdx,:);
w_a = makeSizeData(squeeze(W(:,1,:))');
w_b = makeSizeData(squeeze(W(:,2,:))');

% Get relevant subset of electrodes table %
eIdx = ismember(Te.ChannelID,CID.ChannelID);
Te = Te(eIdx,:);
X = Te.X;
Y = Te.Y;
Y(Te.Area=="RFA") = -abs(Y(Te.Area=="RFA")); % Put RFA always on bottom
Y(Te.Area=="CFA") =  abs(Y(Te.Area=="CFA")); % Put CFA always on top
ICMS = string(Te.ICMS);

% Make graphics objects containers for movie %
fig = figure(...
   'Name',Name,...
   'Units',pars.Units,...
   'Position',pars.Position,...
   'Color','w',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'Toolbar','none');
figure(fig);

% Top plot is for first component of jPC plane %
ax_top = subplot(2,1,1); 
set(ax_top,'XTick',[],'YTick',[],'Color','none','NextPlot','add','Parent',fig);
ratSkullObj_A = make.fig.skullPlot(GroupID,'axes',ax_top);
title(ax_top,Name,'FontName','Arial','FontWeight','bold','Color','k');
str = sprintf(' (jPC-%02d_x)',pars.plane);
ylabel(str,'FontName','Arial','FontWeight','bold','Color','k');
ratSkullObj_A.Name = str;
ratSkullObj_A.addScatterGroup(X,Y,pars.InitSize,ICMS); 

% Bottom plot is for second component of jPC plane %
ax_bot = subplot(2,1,2); 
set(ax_bot,'XTick',[],'YTick',[],'Color','none','NextPlot','add','Parent',fig);
str = sprintf(' (jPC-%02d_y)',pars.plane);
ratSkullObj_B = make.fig.skullPlot(GroupID,'axes',ax_bot);
% title(ax_bot,str,'FontName','Arial','FontWeight','bold','Color','k');
ttxt = title(ax_bot,'','FontName','Arial','FontWeight','bold','Color','k');
ylabel(str,'FontName','Arial','FontWeight','bold','Color','k');
ratSkullObj_B.Name = str;
ratSkullObj_B.addScatterGroup(X,Y,pars.InitSize,ICMS); 

% suptitle(Name);

% pq_mu = nanmean(nanmean(pq,1));
% pq_sd = nanstd(nanmean(pq,1));
% sz = utils.c2sizeData(pq,pq_mu,pq_sd);
% MV = ratSkullObj_A.buildMovieFrameSequence(t,sz,ax2);

% % Create VideoWriter object % %
v = VideoWriter(fname_full);
v.FrameRate = pars.FrameRate;
open(v);
tic;
for ii = 1:numel(t)
   ttxt.String = sprintf('%5.1f (ms)',t(ii));
   changeScatterGroupSizeData(ratSkullObj_A,w_a(:,ii));
   changeScatterGroupSizeData(ratSkullObj_B,w_b(:,ii));
   drawnow;
   writeVideo(v,getframe(fig));
end
fprintf(1,'Finished writing skull channel movie for %s.\n',Name);
toc;
close(v);
delete(fig);
delete(v);

   function sz = makeSizeData(W)
      %MAKESIZEDATA Transform jPCA weights to size data
      %
      %  sz = makeSizeData(W);
      %
      % Inputs
      %  W  - jPCA weights
      %
      % Output
      %  sz - Transformed so that it's a positive value for each W
      
      z = (W - mean(W,2))./std(W,[],2);
      sz = min(max(z .* 150 + 12,4),64);
      
   end
end