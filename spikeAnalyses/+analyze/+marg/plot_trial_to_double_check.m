function fig = plot_trial_to_double_check(Data,J,iTrial)
%PLOT_TRIAL_TO_DOUBLE_CHECK Plot exported jPCA trial vs Original
%
%  fig = analyze.marg.plot_trial_to_double_check(Data,J);
%  fig = analyze.marg.plot_trial_to_double_check(Data,J,iTrial);
%
%  Inputs
%     Data     - Struct array exported for `analyze.jPCA` methods
%     J        - Subset of data table used to export `Data`
%     iTrial   - Index of trial to export. If left unset, just picks a random
%                 integer constrained by the size of `Data`
%
%  Output
%     fig      - Figure handle

if nargin < 3
   iTrial = randi(numel(Data),1,1);
end

% Get Trial "Key"
thisTrial = Data(iTrial).Trial_ID;

% Get times and rates from Original data for this trial
t = J.Properties.UserData.t.';
r = J.Rate(ismember(J.Trial_ID,thisTrial) & ...
           J.Alignment==Data(iTrial).Alignment,:).';
        
% Get times and rates from exported data struct
tq = Data(iTrial).times;
rq = Data(iTrial).A;

cm = getColorMap(size(rq,2),'vibrant');

fig = figure(...
   'Name','jPCA Trial Export Comparison',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.4 0.8]...
   ); 
ax_top = subplot(2,2,1);
ax_top = fix_ax_props(ax_top);
for iCh = 1:size(r,2)
   line(ax_top,t,r(:,iCh),...
      'Color',cm(iCh,:),'LineWidth',1.25,...
      'Tag',sprintf('Channel-%02g',iCh)); 
end
title(ax_top,'Original','FontName','Arial','Color','k'); 
xlabel(ax_top,'Time (ms)','FontName','Arial','Color','k'); 
ylabel(ax_top,'Spike Rate','FontName','Arial','Color','k'); 
xlim(ax_top,[tq(1) tq(end)]);
ylim(ax_top,[-5 5]);

ax_bot = subplot(2,2,3);
ax_bot = fix_ax_props(ax_bot);
for iCh = 1:size(rq,2)
   line(ax_bot,tq,rq(:,iCh),...
      'Color',cm(iCh,:),'LineWidth',1.25,...
      'Tag',sprintf('Channel-%02g',iCh)); 
end
title(ax_bot,'Interpolated','FontName','Arial','Color','k'); 
xlabel(ax_bot,'Time (ms)','FontName','Arial','Color','k');
ylabel(ax_bot,'Spike Rate','FontName','Arial','Color','k'); 
xlim(ax_bot,[tq(1) tq(end)]);
ylim(ax_bot,[-5 5]);

ax_err = subplot(2,2,[2,4]);
ax_err = fix_ax_props(ax_err);
err = nan(size(r));
nSample = size(rq,1);
for iT = 1:size(r,1)
   [~,iSample] = min(abs(tq-t(iT)));
   vec = max(iSample-3,1):min(iSample+3,nSample);
   err(iT,:) = min(sqrt((rq(vec,:) - r(iT,:)).^2),[],1);
end
histogram(ax_err,err(:),...
   'EdgeColor','none','FaceColor',[0.5 0.5 0.5]);
title(ax_err,'Resample SE','FontName','Arial','Color','k'); 

suptitle(['Trial: ' strrep(thisTrial,'_','\_')]);

   function ax = fix_ax_props(ax)
      %FIX_AX_PROPS  Fix axes properties to standard values
      %
      %  ax = fix_ax_props(ax)
      %
      %  Inputs
      %     ax - Axes object to fix
      %
      %  Output
      %     ax - Axes object with updated properties
      
      ax.NextPlot = 'add';
      ax.XColor = 'k';
      ax.YColor = 'k';
      ax.LineWidth = 1.5;
      ax.FontName = 'Arial';
      ax.FontSize = 12;
   end

end