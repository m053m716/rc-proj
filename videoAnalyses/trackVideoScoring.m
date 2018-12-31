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

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CYCLE THROUGH EVERYTHING IN STRUCT TO SCORE
v = load(FNAME);
clc;
tStr = sec2time(v.scoringTime);
fprintf(1,'Batch Video Scoring\n-------------------\n');
fprintf('->\tProgress: %03g/%03g complete.\n->\tTotal scoring time: %s\n',...
   v.bIdx-1,numel(v.block),tStr);

while v.bIdx <= numel(v.block)
   ii = v.bIdx;
   
   if isnan(SUB_F(1))
      fname = fullfile(v.tankPath,...
      v.block(ii).name(1:5),...
      v.block(ii).name,...
      [v.block(ii).name SCORE_ID]);
   else
      fname = fullfile(v.tankPath,...
         v.block(ii).name(1:5),...
         v.block(ii).name,...
         [v.block(ii).name SUB_F],...
         [v.block(ii).name SCORE_ID]);
   end
   
   startTic = tic;
   waitfor(scoreVideo('FNAME_SCORE',fname));
   curToc = toc(startTic);
   v.scoringTime = v.scoringTime + curToc;
   tStr = sec2time(v.scoringTime);
   str = questdlg(sprintf('Was video completed? (%s)?',v.block(v.bIdx).name),...
      'Video completed?','Yes','No','Yes');
   if strcmp(str,'No')
      tmp = repmat('\b',1,49);
      fprintf(1,[tmp '%03g/%03g complete.\n->\tTotal scoring time: %s\n'],...
         ii-1,numel(v.block),tStr);
      tmp = repmat('-',1,37);
      fprintf([tmp '\n-->\tPlace saved, stopped scoring. <--\n' tmp '\n']);
      save(FNAME,'-struct','v');
      break;
   else
      v.bIdx = v.bIdx + 1;
      save(FNAME,'-struct','v');
      
      str = questdlg(sprintf('Score next trial (%s)?',v.block(v.bIdx).name),...
         'Continue scoring?','Yes','No','Yes');
      tmp = repmat('\b',1,49);
         fprintf(1,[tmp '%03g/%03g complete.\n->\tTotal scoring time: %s\n'],...
            ii,numel(v.block),tStr);
      
      if strcmp(str,'No')
         
         tmp = repmat('-',1,37);
         fprintf([tmp '\n-->\tPlace saved, stopped scoring. <--\n' tmp '\n']);
         break;
      
      end
   end
end

% If done, notify
if v.bIdx > numel(v.block)
   tmp = repmat('-',1,38);
   fprintf([tmp '\n-->\tPlace saved, scoring complete. <--\n' tmp '\n']);
end

end
