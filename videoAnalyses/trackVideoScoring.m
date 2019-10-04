function trackVideoScoring(varargin)
%% TRACKVIDEOSCORING   Keep track of video scoring progress
%
%  TRACKVIDEOSCORING;
%  TRACKVIDEOSCORING('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017a)

%% DEFAULTS
FNAME = fullfile(pwd,'RC-BehaviorData-Update.mat');
SUB_F = '_Digital';
SCORE_ID = '_Scoring.mat';
TRIAL_ID = '_Trials.mat';
PAW_ID = '_Paw.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CYCLE THROUGH EVERYTHING IN STRUCT TO SCORE
v = load(FNAME);
clc;
tStr = utils.sec2time(v.scoringTime);
fprintf(1,'Batch Video Scoring\n-------------------\n');
fprintf('->\tProgress: %03g/%03g complete.\n->\tTotal scoring time: %s\n',...
   v.bIdx-1,numel(v.block),tStr);

while v.bIdx <= numel(v.block)
   ii = v.bIdx;
   fprintf(1,'\n-->\tCurrent block: %s <--\n',v.block(ii).name);
   
   if isnan(SUB_F(1))
      pname = fullfile(v.tankPath,...
         v.block(ii).name(1:5),...
         v.block(ii).name);
   else
      pname = fullfile(v.tankPath,...
         v.block(ii).name(1:5),...
         v.block(ii).name,...
         [v.block(ii).name SUB_F]);
   end
      
   
   fname = fullfile(pname,...
      [v.block(ii).name SCORE_ID]);
   if exist(fname,'file')==0
      fname = fullfile(pname,...
         [v.block(ii).name TRIAL_ID]);
      if exist(fname,'file')==0
         fname_paw = fullfile(pname,...
            [v.block(ii).name PAW_ID]);
         if exist(fname_paw,'file')==0
            warning('No way to guess scoring structure. %s skipped.',v.block(ii).name);
            curToc = 0;
         else
            utils.extractTrials(fname_paw);
            startTic = tic;
            waitfor(scoreVideo('FNAME_TRIALS',fname));
            curToc = toc(startTic);
         end            
      else
         startTic = tic;
         waitfor(scoreVideo('FNAME_TRIALS',fname));
         curToc = toc(startTic);
      end         
   else
      startTic = tic;
      waitfor(scoreVideo('FNAME_SCORE',fname));
      curToc = toc(startTic);
   end
      

   
   
   v.scoringTime = v.scoringTime + curToc;
   tStr = utils.sec2time(v.scoringTime);
   str = questdlg(sprintf('Was video completed? (%s)?',v.block(v.bIdx).name),...
      'Video completed?','Yes','No','Yes');
   if strcmp(str,'No')
      tmp = repmat('\b',1,50);
      fprintf(1,[tmp '%03g/%03g complete.\n->\tTotal scoring time: %s\n'],...
         ii-1,numel(v.block),tStr);
      tmp = repmat('-',1,37);
      fprintf('%s\n-->\tPlace saved, stopped scoring. <--\n%s\n',tmp,tmp);
      save(FNAME,'-struct','v');
      break;
   else
      v.bIdx = v.bIdx + 1;
      save(FNAME,'-struct','v');
      
      if v.bIdx <= numel(v.block)
         str = questdlg(sprintf('Score next trial (%s)?',v.block(v.bIdx).name),...
            'Continue scoring?','Yes','No','Yes');
      else
         str = 'Yes';
      end
      tmp = repmat('\b',1,50);
      fprintf(1,[tmp '%03g/%03g complete.\n->\tTotal scoring time: %s\n'],...
         ii,numel(v.block),tStr);
      
      if strcmp(str,'No')
         
         tmp = repmat('-',1,37);
         fprintf(1,...
            '%s\n-->\tPlace saved, stopped scoring. <--\n%s\n',tmp,tmp);
         break;
         
      end
   end
end

% If done, notify
if v.bIdx > numel(v.block)
   tmp = repmat('-',1,38);
   fprintf([tmp '\n-->\tPlace saved, scoring complete. <--\n' tmp '\n']);
else
   fprintf(1,'\n\n\t-->\tCurrent block: %s <--\n\n',v.block(v.bIdx).name);
end

end
