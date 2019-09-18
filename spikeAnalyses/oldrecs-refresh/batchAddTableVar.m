function err = batchAddTableVar(F,fieldName,colIdx,varType,value,varargin)
%% BATCHADDTABLEVAR  Add a specific table variable column
%
%  err = BATCHADDTABLEVAR(F);
%  err = BATCHADDTABLEVAR(F,fieldName);
%  err = BATCHADDTABLEVAR(F,fieldName,colIdx);
%  err = BATCHADDTABLEVAR(F,fieldName,colIdx,varType);
%  err = BATCHADDTABLEVAR(F,fieldName,colIdx,varType,value);
%  err = BATCHADDTABLEVAR(F,fieldName,colIdx,varType,value,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F        :     nAnimal x 2 cell array for keeping BLOCKS organized.
%
%  fieldName   :     (String) name of variable name to add to table.
%                    or (cell array of strings) names of variables to add
%                    to table.
%
%  colIdx      :      (Optional) Scalar specifying the column where this
%                                variable is to be inserted. For example, a
%                                table with 6 rows would normally append
%                                the column as the 7th. However, if colIdx
%                                is specified as 5, then the 5th column is
%                                the new variable and column 6 is the
%                                previous column from column 5 (so there
%                                are still 7 columns). If fieldName is a
%                                cell array of strings, then colIdx must
%                                match the number of elements of fieldName.
%
%  varType     :     (Optional) [1 x nFieldsAdded] vector of varTypes:
%                       -> 0: "Trials" (basically an unused variable type)
%                       -> 1: "Timestamps" (scalar; seconds)
%                       -> 2: "Counts" (scalar; integer 0-9)
%                       -> 3: "No/Yes" (0 or 1)
%                       -> 4: "Unsuccessful/Successful" (0 or 1)
%                       -> 5: "L/R" (0 or 1)
%
%  value       :      (Optional) N x 1 vector of values to use for the
%                                appended variable. By default if this is
%                                not specified, the value is set to NaN for
%                                each added variable. If a cell array of
%                                strings is specified for fieldName, then
%                                this should be an N x K matrix of values,
%                                where K is the number of cell elements
%                                added.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     err      :     List of any error blocks.
%
% By: Max Murphy  v1.0  12/30/2018  Original version (R2017a)

%% DEFAULTS
DIG_DIR = '_Digital';
SCORE_ID = '_Scoring.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH F, LOAD SCORING TABLE, ADDTABLEVAR, SAVE AND REPEAT
err = [];
fprintf('Modifying scoring tables...%03g%%\n',0);
for iA = 1:size(F,1)
   for iB = 1:numel(F{iA,2})
      try
         fName = fullfile(F{iA,2}(iB).folder,...
               F{iA,2}(iB).name,...
               [F{iA,2}(iB).name DIG_DIR],...
               [F{iA,2}(iB).name SCORE_ID]);
            
         load(fName,'behaviorData');
         switch nargin
            case 1
               behaviorData = addTableVar(behaviorData);
            case 2
               behaviorData = addTableVar(behaviorData,fieldName);
            case 3
               behaviorData = addTableVar(behaviorData,fieldName,colIdx);
            case 4
               behaviorData = addTableVar(behaviorData,fieldName,colIdx,varType);
            otherwise
               behaviorData = addTableVar(behaviorData,fieldName,colIdx,varType,value);
         end
         save(fName,'behaviorData','-v7.3');
         
      catch me
         err = [err; {F{iA,2}(iB), me}];  %#ok<AGROW>
      end 
      pct = floor(((iA-1)/size(F,1)+iB/(numel(F{iA,2})*size(F,1)))*100);
      fprintf('\b\b\b\b\b%03g%%\n',pct);
   end
end


end