function [a_cfa, a_rfa] = getAccuracyContribution(trialData,y,varargin)
%% GETACCURACYCONTRIBUTION   Gets accuracy contribution for 2 areas
%
%  [a_cfa,a_rfa] = GETACCURACYCONTRIBUTION(trialData,y);
%  [a_cfa,a_rfa] = GETACCURACYCONTRIBUTION(trialData,y,'NAME',value,...);
%
% By: Max Murphy v1.0   08/02/2018  Original version (R2017b)

%% DEFAULTS
GROUP = {'BOTH';'CFA';'RFA'};
N_MARKER = 16;

% Plot options
PLOT_DIST = false;
AUTO_SAVE_FIG = false;
FIG_SAVE_DIR = 'fit_ErrorFig';
DIST_BINS = linspace(0, 1500, 151);
DIST_LIM = [0 1500];

% Output data options
AUTO_SAVE_DATA = false;
DATA_SAVE_DIR = 'fit_ErrorData';


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if size(trialData,1) ~= numel(GROUP)
   error('Mismatch between number of elements in GROUP (%d) and fit (%d).\n',...
      numel(GROUP),size(trialData,1));
end

%% EXTRACT FIT
nTrial = size(trialData,2);
rmse = nan(nTrial*N_MARKER,3);
vec = 0:(N_MARKER-1);

iCount = 0;
for ii = 1:N_MARKER:size(rmse,1)
   iCount = iCount + 1;
   idx = vec + ii;
   for ik = 1:numel(GROUP)
      rmse(idx,ik) = sqrt(mean((trialData{ik,iCount}.OutputData - ...
                          y{ik,iCount}.OutputData).^2,1));
   end   
end


%% CONVERT FORMAT OF FIT


if PLOT_DIST
   close all force %#ok<UNRCH>
   for ii = 1:numel(GROUP)
      figure('Name',[GROUP{ii} ' histogram'],...
             'Units','Normalized',...
             'Position',[0.1*ii 0.1*ii 0.6 0.6],...
             'Color','w');
      histogram(rmse(:,ii),DIST_BINS);
      title(GROUP{ii},'FontName','Arial','FontSize',16,'Color','k');
      xlabel('Fit (RMSE)','FontName','Arial','FontSize',14,'Color','k');
      ylabel('Count','FontName','Arial','FontSize',14,'Color','k');
      xlim(DIST_LIM);
      
      if AUTO_SAVE_FIG
         if exist(FIG_SAVE_DIR,'dir')==0
            mkdir(FIG_SAVE_DIR);
         end
         
         name = strsplit(trialData{ii,1}.Name, ' - ');
         name = strjoin(name([1,2,4]),' - ');
         
         fname = fullfile(FIG_SAVE_DIR,[name '_RMSE']);
         
         savefig(gcf,[fname '.fig']);
         saveas(gcf,[fname '.png']);
         
         delete(gcf);
         
      end
   end
end

%% RETURN OUTPUT
a_cfa = nan(nTrial,1);
a_rfa = nan(nTrial,1);

iCount = 0;
for ii = 1:N_MARKER:size(rmse,1)
   
   iCount = iCount + 1;
   idx = vec + ii;
   
   a_cfa(iCount) = mean(1 - log((rmse(idx,1) + rmse(idx,2))./rmse(idx,1)));
   a_rfa(iCount) = mean(1 - log((rmse(idx,1) + rmse(idx,3))./rmse(idx,1)));
end

name = strsplit(trialData{1,1}.Name, ' - ');
name = strjoin(name([1,2]),' - ');

fprintf(1,'\n%s\n--------------------------------\n',name);
fprintf(1,'CFA accuracy contribution: %g +/- %g\n',...
   nanmean(a_cfa),...
   nanstd(a_cfa));
fprintf(1,'RFA accuracy contribution: %g +/- %g\n',...
   nanmean(a_rfa),...
   nanstd(a_rfa));

if AUTO_SAVE_DATA
   if exist(DATA_SAVE_DIR,'dir')==0 %#ok<UNRCH>
      mkdir(DATA_SAVE_DIR);
   end
   
   fname = fullfile(DATA_SAVE_DIR,[name '_accuracy.mat']);
   save(fname,'a_cfa','a_rfa','rmse','-v7.3');
end

end