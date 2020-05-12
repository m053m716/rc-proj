function [F,surgDict] = moveToIsilon(block,varargin)
%% MOVETOISILON	Move bunch of files from DiskStation to Isilon
%
%	[F,surgDict] = MOVETOISILON(block);
%	[F,surgDict] = MOVETOISILON(block,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    block        :     Data struct in 'info.mat'. Similar to the struct
%                          returned when calling 'dir' to get a list of
%                          files in directory, but it only has 'folder' and
%                          'name' fields, and then 'day' and 'ch' fields as
%                          well.
%
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     F           :     Cell array where each row is an animal. First
%                          column is animal name. Second column is a struct
%                          returned from the 'dir' command pertaining to
%                          all blocks corresponding to that animal.
%
%   surgDict      :     "Dictionary" struct that gives the original date of
%                          surgery for a given animal. 
%
%
% By: Max Murphy  v1.0  12/28/2018  Original Version (R2017a)

%% DEFAULTS
IN_DIR = 'J:\Rat\BilateralReach\Data';

TRANSFER = {'_Digital';...
            '_FilteredCAR';...
            '_RawData'; ...
            '_Scoring.mat'};
         
OUT_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
OUT_INFO = 'info.mat';


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% MOVE EVERYTHING IN "BLOCK" OVER TO "OUT_DIR"
surgDict = struct;
fprintf('Transferring...%03g%%\n',0);
for iB = 1:numel(block)
   name = block(iB).name;   
   [dateNum,~,rat] = parseRecDate(name);
   ratField = strrep(rat,'-','');
   if ~isfield(surgDict,ratField)
      surgDate = dateNum - block(iB).day;
      surgDict.(ratField) = surgDate;
   end
   b = fullfile(IN_DIR,rat,name);
   
   destBlock = fullfile(OUT_DIR,rat,name);
   if exist(destBlock,'dir')==0
      mkdir(destBlock);
   end
   
   for iT = 1:numel(TRANSFER)
      folderName = [name TRANSFER{iT}];
      toMove = fullfile(b,folderName);
      if (exist(toMove,'dir')==0) && (exist(toMove,'file')==0)
         warning('%s not found.',toMove);
         fprintf('Transferring...%03g%%\n',floor(iB/numel(block)*100));
      else
         movefile(toMove,fullfile(destBlock,folderName),'f');
      end      
   end
   fprintf('\b\b\b\b\b%03g%%\n',floor(iB/numel(block)*100));
end

in = load(fullfile(OUT_DIR,OUT_INFO),'F');
for iF = 1:size(in.F,1)
   in.F{iF,2} = dir(fullfile(OUT_DIR,in.F{iF,1},[in.F{iF,1} '_2*'])); 
end
F = in.F;

end