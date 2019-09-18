function fig = plotJPCAdata(J,rowIdx,align,outcome,area,pcName,pcPlane)
%% PLOTJPCADATA   Plot jPC coefficients for each day
%
%  fig = PLOTJPCADATA(J);
%
%  --------
%   INPUTS
%  --------
%     J     :     Table obtained by using GETPROP method to retrieve 'Data'
%                    property of all child blocks from GROUP object.
%
%  rowIdx   :     Row of J to plot
%
%  pcName   :     Char array. 'jPCs' // 'PCs' // 'jPCs_highD' (def)
%
%  pcPlane  :     Index of plane to use (def: 1)
%
% By: Max Murphy  v1.0  2019-06-11  Original version (R2017a)

%% DEFAULTS
AREA = defaults.group('area_opts');
ICMS = defaults.group('icms_opts');
MRK = {'o';'s'};
SZ = [20,40];
COL = {'r','b'};

XLIM = [-1 1];
YLIM = [-1 1];

%% PARSE INPUT
if nargin < 7
   pcPlane = 1;
end

if nargin < 6
   pcName = 'jPCs_highD';
end

if nargin < 5
   area = 'Full';
end

if nargin < 4
   outcome = 'All';
end

if nargin < 3
   align = 'Grasp';
end

if nargin < 2
   close all force;
   fig = [];
   for iJ = 1:size(J,1)
      fig = [fig; plotJPCAdata(J,iJ,align,outcome,area,pcName,pcPlane)]; %#ok<*AGROW>
   end
   return;
elseif numel(rowIdx) > 1
   close all force;
   fig = [];
   for iJ = 1:numel(rowIdx)
      fig = [fig; plotJPCAdata(J,rowIdx(iJ),align,outcome,area,pcName,pcPlane)]; %#ok<*AGROW>
   end
   return;
end

%%
fig = figure('Name',sprintf('%s scatter by group',pcName),...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.3 0.3 0.4 0.4]);

areaIdx = {J.ChannelInfo{rowIdx}.area};
icmsIdx = {J.ChannelInfo{rowIdx}.icms};
dim1 = 2*(pcPlane-1)+1;
dim2 = 2*pcPlane;

D = J.Data(rowIdx).(align).(outcome).jPCA.(area);
score = J.Score(rowIdx);
legText = [];

% for ii = 1:numel(AREA)
%    for ij = 1:numel(ICMS)
%       idx = contains(areaIdx,AREA{ii}) & contains(icmsIdx,ICMS{ij});
%       if sum(idx)==0
%          continue;
%       end
%       scatter(D.Summary.(pcName)(idx,dim1),...
%          D.Summary.(pcName)(idx,dim2),...
%          SZ(ij),COL{ii},'filled',MRK{ij});
%       legText = [legText; {strjoin([AREA(ii),ICMS(ij)],'-')}];
%       hold on;
%    end
% end
for ii = 1:numel(AREA)

   idx = contains(areaIdx,AREA{ii});
   if sum(idx)==0
      continue;
   end
   scatter(D.Summary.(pcName)(idx,dim1),...
      D.Summary.(pcName)(idx,dim2),...
      SZ(ii),COL{ii},'filled',MRK{ii});
   legText = [legText; AREA(ii)];
   hold on;

end
text(XLIM(2)*0.7,YLIM(2)*0.8,sprintf('Score: %g%%',round(score*100)),...
   'FontName','Arial','FontSize',14,'Color','m','FontWeight','bold');
text(XLIM(2)*0.7,YLIM(2)*0.6,sprintf('Var: %g%%',...
   round(D.Summary.varCaptEachPlane(pcPlane)*100)),...
   'FontName','Arial','FontSize',14,'Color','b','FontWeight','bold');
legText = [legText; {'Mean Success'}];
plot(D.Summary.crossCondMean(:,dim1),D.Summary.crossCondMean(:,dim2),...
   'Color','k','LineWidth',2);
legend(legText,'Location','NorthWest');

xlabel(sprintf('jPC_%g',dim1),'FontName','Arial','FontSize',14,'Color','k');
ylabel(sprintf('jPC_%g',dim2),'FontName','Arial','FontSize',14,'Color','k');
title(sprintf('jPC-plane_%g',pcPlane),'FontName','Arial','FontSize',16,'Color','k');
% xlim(XLIM);
% ylim(YLIM);

end