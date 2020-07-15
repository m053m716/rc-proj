function fig = show(T,response,varargin)
%SHOW  Shows figure(s) of response variable by Animal using Rate Table
%
%  fig = analyze.behavior.show(T,response);
%  fig = analyze.behavior.show(T,resposne,'var1',{val1},'var2',{val2},...);
%
% Inputs
%  T        - 'trials' type Rate Table
%  response - Name of "response" variable from data table
%  varargin - Optional 'Name',value filters to add to restrict what is
%              plotted, consisting of Variable names and viable values.
%
% Output
%  fig      - Figure handle
%
% See also: analyze.stat, analyze.behavior, 
%           analyze.behavior.outcomes, analyze.behavior.durations,
%           behavior_timing.mlx

if ismember('Trial_ID',T.Properties.VariableNames)
   [~,iUniqueTrial] = unique(T.Trial_ID);
   T = T(iUniqueTrial,:);
end

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

iResponse = find(strcmpi(T.Properties.VariableNames,response),1,'first');
response = T.Properties.VariableNames{iResponse};

if isempty(T.Properties.VariableUnits{iResponse})
   yLab = strrep(response,'_',' ');
else
   yLab = sprintf('%s (%s)',strrep(response,'_',' '),...
      T.Properties.VariableUnits{iResponse});
end

for ii = 1:nTotal
   ax = subplot(nRow,nCol,ii);
   tThis = tsub(G==ii,:);
   gnames = findgroups(tThis(:,'AnimalID'));
   
   set(ax,'Parent',fig,'NextPlot','add',...
      'XLim',[2 30],'YLim',[0 1.5],'XTick',7:7:28,...
      'XColor','k','YColor','k','LineWidth',1.5,'FontName','Arial');
   splitapply(...
      @(poDay,y,name)analyze.stat.addJitteredScatter(...
      ax,poDay,y,name,col(ii,:)),...
      tThis.PostOpDay,tThis.(response),tThis.AnimalID,gnames);

   analyze.stat.addLogisticRegression(ax,...
      tThis.PostOpDay+randn(size(tThis.PostOpDay)).*0.2,...
      tThis.(response),[0 0 0],X,...
      'Color','k','LineWidth',1.5,'LineStyle','-','TX',30.5,...
      'addlabel',false);
   title(ax,string(TID.Group(ii)),'FontName','Arial','Color','k');
   ylabel(ax,yLab,'FontName','Arial','Color','k');
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