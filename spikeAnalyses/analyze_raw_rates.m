%ANALYZE_RAW_RATES  Generate raw spike rate statistics for comparing to previous works
%
% We just want to see here if the rates we are getting make sense based on
% our priors about what is happening in the regions we are recording from.

clc;
clearvars -except R
if exist('R','var')==0
   R = getfield(load(defaults.files('raw_rates_table_file'),'R'),'R');
end

% Set parameters
ALIGN   = {'Reach';'Grasp';'Support'};
TASK_EPOC = [-450 150];
PRE_EPOC = [-1350 -750]; 

% Generate output array of generalized linear mixed effects objects
glme = analyze.stat.fit_spike_count_glme(R,ALIGN,'Successful',TASK_EPOC);
glme = [glme; ...
   {analyze.stat.fit_spike_count_glme(R,'Reach','Successful',PRE_EPOC)}];

% Organize into data table
Align = [ALIGN; 'Reach'];
Outcome = repmat({'Successful'},numel(Align),1);
tStart = [repmat(TASK_EPOC(1),numel(ALIGN),1); PRE_EPOC(1)];
tStop  = [repmat(TASK_EPOC(2),numel(ALIGN),1); PRE_EPOC(2)];
G = table(Outcome,Align,tStart,tStop,glme);
G.Outcome = string(G.Outcome);
G.Align = string(G.Align);
G.Properties.VariableUnits = {'','','ms','ms',''};
G.Properties.VariableDescriptions = {'Trial result',...
   'Behavioral alignment event','Relative start time',...
   'Relative end time','Generalized Linear Mixed-Effects Model'};
G.Properties.Description = ...
   'Raw spike counts Generalized Linear Mixed Effects models';