function fig = durations(T,varargin)
%DURATIONS Make figure(s) of durations by Animal using Rate Table
%
%  fig = analyze.behavior.durations(T);
%  fig = analyze.behavior.durations(T,'var1',{val1},'var2',{val2},...);
%
% Inputs
%  T        - 'trials' type Rate Table
%  varargin - 
%
% Output
%  fig      - Figure handle
%
% See also: analyze.stat

[~,iUniqueTrial] = unique(T.Trial_ID);
T = T(iUniqueTrial,:);

fig = figure(...
      'Name','Trial Duration by Day',...
      'Units','Normalized',...
      'Color','w',...
      'Position',[0.43 0.48 0.43 0.37]...
      );
   
tsub = analyze.slice(T,varargin{:});
col = [0.8 0.1 0.1; 0.1 0.1 0.8];
[G,TID] = findgroups(tsub(:,'Group'));
X = linspace(3,30,100);

nTotal = size(TID,1);
nRow = floor(sqrt(nTotal));
nCol = ceil(nTotal/nRow);

for ii = 1:nTotal
   ax = subplot(nRow,nCol,ii);
   tThis = tsub(G==ii,:);
   gnames = findgroups(tThis(:,'AnimalID'));
   
   set(ax,'Parent',fig,'NextPlot','add',...
      'XLim',[2 30],'YLim',[0 1.5],'XTick',7:7:28,...
      'XColor','k','YColor','k','LineWidth',1.5,'FontName','Arial');
   splitapply(...
      @(poDay,duration,name)analyze.stat.addJitteredScatter(...
      ax,poDay,duration,name,col(ii,:)),...
      tThis.PostOpDay,tThis.Duration,tThis.AnimalID,gnames);

   analyze.stat.addLogisticRegression(ax,...
      tThis.PostOpDay+randn(size(tThis.PostOpDay)).*0.2,...
      tThis.Duration,[0 0 0],X,...
      'Color','k','LineWidth',1.5,'LineStyle','-','TX',30.5,...
      'addlabel',false);
   title(ax,string(TID.Group(ii)),'FontName','Arial','Color','k');
   ylabel(ax,'Trial Duration (sec)','FontName','Arial','Color','k');
   xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
end

if isempty(varargin)
   suptitle('All Trials'); 
else
   str = '';
   for ii = 2:2:numel(varargin)
      str = [str, sprintf('%s::',string(varargin{ii}))]; %#ok<AGROW>
   end
   str = str(1:(end-2));
   suptitle(str);
   
end

end