function postOpDay = parsePostOpDate(T)
%% PARSEPOSTOPDATE   Sub-function to get recording date from name
%
%  [dateNum,dateString] = PARSEPOSTOPDATE(blockName);
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
rat = T.Name{1};
rat = strrep(rat,'-','');

dateNum = nan(size(T,1),1);
for ii = 1:size(T,1)
   dateNum(ii) = datenum(T.Date(ii));
end

load('info.mat','surgDict');
if ~ismember(rat,fieldnames(surgDict))
   postOpDay = nan;
   fprintf(1,'%s not in surgery date struct (surgDict).\n',rat);
else
   postOpDay = dateNum - surgDict.(rat);
end

end