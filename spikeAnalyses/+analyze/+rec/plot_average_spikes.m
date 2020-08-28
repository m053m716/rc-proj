function [fig,Tsub] = plot_average_spikes(T,varargin)
%PLOT_AVERAGE_SPIKES    Plot mean spike rate profiles or count histograms 
%
%  fig = analyze.rec.plot_average_spikes(T);
%  [fig,Tsub] = analyze.rec.plot_average_spikes(T,'Name',value,...);
%
% Inputs
%  T        - Any table that has .Rate variable and .t UserData property, 
%             as well as .Alignment, .BlockID, and .Outcome
%  varargin - (Optional) 'Name',value input argument pairs
%           'Align' - 'Grasp' (def) | 'Reach' | 'Support' | 'Complete'
%           'Outcome' - {'Successful'} (def) | {'Unsuccessful'} |
%                       {'Successful','Unsuccessful'}
%           'Save' - false (def) | true (auto-save figures)
%           'Subset' - inf (def) | Set as scalar to create up to that many
%                                   random sub-sampled blocks. Otherwise if
%                                   it is inf, this iterates on all unique
%                                   blocks in the table.
%
% Output
%  fig      - Figure handle
%  Tsub     - (Optional) Subset used if `pars.Subset` is not inf

pars = struct;
pars.Align = 'Grasp';
pars.Outcome = {'Successful'};
pars.MinTrials = 5;
pars.RateVar = 'Rate';
pars.Save = false;
pars.Subset = inf;
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

T = utils.filterByNTrials(T,pars.MinTrials,pars.Outcome);

uBlock = unique(T.BlockID);
nBlock = numel(uBlock);
if nBlock > 1
   fcn = @analyze.rec.plot_average_spikes;
   if isinf(pars.Subset)
      fig = analyze.rec.iterate(fcn,T,pars);
      if nargout > 1
         Tsub = T;
      end
   else
      Tsub = T(ismember(T.BlockID,uBlock(randperm(nBlock,pars.Subset))),:);
      fig = analyze.rec.iterate(fcn,Tsub,pars);
   end
   if pars.Save
      if nargout < 1
         clear fig;
      end
   end

   return;
else
   Tsub = [];
end

poDay = T.PostOpDay(1);
if ~ismember('Rat',T.Properties.VariableNames)
   rat = string(T.AnimalID(1));
else
   rat = sprintf('RC-%02g',T.Rat(1));
end
t = T.Properties.UserData.t';

nTrial = numel(unique(T.Trial_ID));

if all(ismember(pars.Outcome,{'Unsuccessful','Successful'}))
   str = sprintf('%s - PO-%02g - All %s (%d trials)',rat,poDay,pars.Align,nTrial);
elseif ismember(pars.Outcome,{'Successful'})
   str = sprintf('%s - PO-%02g - Successful %s (%d trials)',rat,poDay,pars.Align,nTrial);
else
   str = sprintf('%s - PO-%02g - Unsuccessful %s (%d trials)',rat,poDay,pars.Align,nTrial);
end

fig = figure(...
   'Name',sprintf('Mean Spike Rates: %s',str),...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);

tsub = T(ismember(string(T.Outcome),pars.Outcome) & T.Alignment==pars.Align,:);
[xtick,y_lim,rate_colors] = defaults.rec_analyses(...
   'rate_xtick','rate_ylim','rate_colors');

if isfield(T.Properties.UserData,'MeanSpikeYLim')
   y_lim = T.Properties.UserData.MeanSpikeYLim;
end

[G,TID] = findgroups(tsub(:,{'Area','ChannelID','ICMS'}));
nCh = size(TID,1);
nRow = floor(sqrt(nCh));
nCol = ceil(nCh/nRow);

iArea = struct('CFA',0,'RFA',0);
x_lim = [t(1) t(end)];
X = sgolayfilt(tsub.(pars.RateVar),5,21,ones(1,21),2);

for iCh = 1:nCh
   ax = subplot(nRow,nCol,iCh);
   a = char(TID.Area(iCh));
   icms = char(TID.ICMS(iCh));
   id = string(TID.ChannelID(iCh));
   tag = sprintf('Ch-%s_%s-%s',id,a,icms);
   
   iArea.(a) = iArea.(a) + 1;
   
   set(ax,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
      'FontName','Arial','Tag',tag,'XLim',x_lim,'YLim',y_lim,...
      'XTick',xtick);
   x = X(G==iCh,:)';
   gfx__.plotWithShadedError(ax,t,x,...
      'Color',rate_colors.(a)(iArea.(a),:),...
      'FaceColor',rate_colors.(a)(iArea.(a),:),...
      'DisplayName',tag,...
      'Annotation','on',...
      'Tag',tag,...
      'FaceAlpha',0.5,...
      'UseMedian',true);
   title(ax,strrep(tag,'_',' '),'FontName','Arial','Color','k');
end
suptitle(str);
if pars.Save
   p = defaults.files('rec_analyses_fig_dir');
   p = fullfile(p,string(T.AnimalID(1)));
   if iscell(pars.Outcome)
      outStr = strjoin(pars.Outcome,'-');
   else
      outStr = pars.Outcome;
   end
   if exist(fullfile(p,outStr),'dir')==0
      mkdir(fullfile(p,outStr));
   end
   savefig(fig,fullfile(p,outStr,['Means - ' str '.fig']));
   saveas(fig,fullfile(p,outStr,['Means - ' str '.png']));
   delete(fig);
end

end