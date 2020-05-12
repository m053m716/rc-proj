function [xPC,mu] = exportXPCAfigs(gData)
%% EXPORTXPCAFIGS    xPCobj = exportXPCAfigs(gData); % Export figures
%
% By: Max Murphy v1.0   2019-11-13  Original version (R2017a)

%% DO EXPORT FOR RATE FROM - ALL - AREAS FIRST
OUT_PATH = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA';
AREA = {'ALL','CFA','RFA'};
GROUP = {'Intact','Ischemia'};
NAME_STR = 'PCA - Cross Days - %s - %s - %s - PO-%g to PO-%g - %s - %s';

INC = {...
   utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);...
   utils.makeIncludeStruct({'Reach','Grasp','PelletPresent'},{'Outcome'});...
   ...utils.makeIncludeStruct({'Grasp','PelletPresent'},{'Reach'}); ...
   };

INC_LABEL = {...
   'Successful'; ...
   'Unsuccessful'; ...
   ...'GraspOnly'; ...
   };

ALIGN = defaults.group('align');
DAY = [...
   5  28;...
   5  16;...
   17 28];
DAY_LABEL = {'AllDays','Early','Late'};
ICMS = {{'DF','PF','DF-PF','PF-DF'},...
   {'DF','PF','DF-PF','PF-DF','O','NR'}};
ICMS_LABEL = {'ForelimbICMS','AllICMS'};

xPC = struct;

if numel(DAY_LABEL) ~= size(DAY,1)
   error('DAY_LABEL number of elements must equal DAY number of rows.');
end

if numel(ICMS_LABEL) ~= numel(ICMS)
   error('ICMS_LABEL and ICMS must contain same number of elements.');
end

if numel(INC_LABEL) ~= numel(INC)
   error('INC_LABEL and INC must contain same number of elements.');
end

clc;

for iG = 1:numel(GROUP)
   xPC.(GROUP{iG}) = struct;
   mu.(GROUP{iG}) = struct;
   for iA = 1:numel(AREA)
      xPC.(GROUP{iG}).(AREA{iA}) = struct;
      mu.(GROUP{iG}).(AREA{iA}) = struct;
      for iD = 1:numel(DAY_LABEL)
         xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}) = struct;
         mu.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}) = struct;
         for iICMS = 1:numel(ICMS)
            xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}) = struct;
            mu.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}) = struct;
            for iINC = 1:numel(INC)
               fstr = sprintf('%s-%s-%s',GROUP{iG},AREA{iA},ICMS_LABEL{iICMS});
               outpath = fullfile(OUT_PATH,fstr);
               if exist(outpath,'dir')==0
                  mkdir(outpath);
               end
               xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}).(INC_LABEL{iINC}) = xPCobj(gData.(GROUP{iG}),...
                  ALIGN,INC{iINC},AREA{iA},DAY(iD,1),DAY(iD,2),ICMS{iICMS});
               
               if ~xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}).(INC_LABEL{iINC}).InitSuccessful
                  continue;
               end
               mu.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}).(INC_LABEL{iINC}) = ...
                  xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}).(INC_LABEL{iINC}).X;

               fig = checkCrossDayMeanPCs(xPC.(GROUP{iG}).(AREA{iA}).(DAY_LABEL{iD}).(ICMS_LABEL{iICMS}).(INC_LABEL{iINC}));
               save_xPCA_fig(fig,sprintf(NAME_STR,ALIGN,GROUP{iG},AREA{iA},...
                  DAY(iD,1),DAY(iD,2),ICMS_LABEL{iICMS},INC_LABEL{iINC}),outpath);
            end
         end
      end
   end
end

save('Cross-Day_Rate_Averages.mat','mu','-v7.3');

end
