%% TESTBENCH_TIMER  For use with "Run and Time" in Editor Tab
%
% Usage: enter whatever command would go to Command Window and then this
% script acts as a wrapper, allowing "Run and Time" execution while
% specifying the parameters for a particular method of the GROUP, RAT, or
% BLOCK object.

%% Timer for plotting

% fig = plotRateAverages(gData(1).Children(1),'Grasp','Successful');

%% Timer for object initialization (with rate extraction)
RAT = {     ...
   'RC-02'; ... % re-extract spike rates
   'RC-04'; ... % re-extract spike rates
   'RC-05'; ... % re-extract spike rates
   'RC-08'; ... % re-extract spike rates
   'RC-14'; ... % re-extract spike rates
   'RC-18'; ... % re-extract spike rates
   'RC-21'; ... % re-extract spike rates
   'RC-26'; ... % re-extract spike rates
   'RC-30'; ... % re-extract spike rates
   'RC-43'  ... % re-extract spike rates
   };

for ii = 1:numel(RAT) % ~ 2 minutes (have to manually score though)
   ratObj = rat(fullfile('P:\Extracted_Data_To_Move\Rat\TDTRat',RAT{ii})); %#ok<*AGROW>
   clear ratObj;
end