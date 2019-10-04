%% TESTBENCH_TIMER  For use with "Run and Time" in Editor Tab
%
% Usage: enter whatever command would go to Command Window and then this
% script acts as a wrapper, allowing "Run and Time" execution while
% specifying the parameters for a particular method of the GROUP, RAT, or
% BLOCK object.

%% Timer for plotting

% fig = plotRateAverages(gData(1).Children(1),'Grasp','Successful');

%% Timer for object initialization (with rate extraction)
ratObj = rat(fullfile('P:\Extracted_Data_To_Move\Rat\TDTRat\RC-43'),'Grasp',true,false);