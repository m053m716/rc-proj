function [dateNum,dateString,rat] = parseRecDate(blockName)
%% PARSERECDATE   Sub-function to get recording date from name
%
%  [dateNum,dateString] = PARSERECDATE(blockName);
%
%  --------
%   INPUTS
%  --------
%  blockName      :     TDT recording block name. (e.g. 'RC-02_2012_05_01')
%
%  --------
%   OUTPUT
%  --------
%   dateNum       :     Serial Matlab datenum (useful for computing
%                          differences in terms of number of days).
%
%  dateString     :     Matlab datestr used to compute dateNum.
%
%     rat         :     Name of rat (char)
%
% By: Max Murphy  v1.0  12/28/2018  Original version (R2017a)

%%
str = strsplit(blockName,{'-','_'});
ratnum = str2double(str{2});
str{2} = num2str(ratnum,'%02d');

rat = strjoin(str([1,2]),'-');

dateString = strjoin(str([3,4,5]),'-');
dateNum = datenum(dateString,'yyyy-mm-dd');

end