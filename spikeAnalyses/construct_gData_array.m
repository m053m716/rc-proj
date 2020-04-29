function [gData,ticTimes] = construct_gData_array(RAT,skip_save)
%CONSTRUCT_GDATA_ARRAY  gData = construct_gData_array(RAT,skip_save);
%
%  gData = construct_gData_array(RAT);
%  gData = construct_gData_array(RAT,skip_save);
%
%  -- Inputs --
%  RAT : Cell array of rat names
%  skip_save : Default = false; Set true to skip saving gData object

% Parse Input
if nargin < 1
   RAT = defaults.experiment('rat');
end

if nargin < 2
   skip_save = false;
end

% Build array
ratArray = [];
ticTimes.ratArrayTic = tic;
tank = defaults.files('tank');
for ii = 1:numel(RAT) % ~ 2 minutes (have to manually score though)
   ratArray = [ratArray; rat(fullfile(tank,RAT{ii}))]; %#ok<*AGROW>
end
gData = [group('Ischemia',ratArray([1:4,8:9]));
         group('Intact',ratArray([5:7,10]))];
clear ratArray

if ~skip_save
   ticTimes = saveGroupData(gData,ticTimes);
end

end