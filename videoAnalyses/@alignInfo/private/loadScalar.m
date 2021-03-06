function scalar = loadScalar(F,varNum,warnFlag,defVal)
%% LOADSCALAR    Load a Scalar variable without needing specific name
%
%  scalar = LOADSCALAR(F);
%  scalar = LOADVECTOR(F,varNum);
%  scalar = LOADVECTOR(F,varNum,warnFlag);
%
%  --------
%   INPUTS
%  --------
%     F           :     File struct (from 'dir') for a given file.
%
%   defVal        :     (Optional) Default scalar value if file is not
%                                   found. If not specified, default is
%                                   NaN.
%
%   varNum        :     (Optional) Index of variable to load. Use this if
%                                   you know the behavior of the file to be
%                                   loaded, for example if you know the 2nd
%                                   indexed variable name will always be
%                                   the desired variable to load. Not
%                                   recommended.
%
%  warnFlag       :     (Optional) flag to suppress warnings. If not
%                                 specified, defaults to true and warns
%                                 user if there are multiple variables in a
%                                 given file to be loaded. Can be specified
%                                 as false if you know the behavior of
%                                 loading a particular file with multiple
%                                 variables, but not recommended.
%
%  --------
%   OUTPUT
%  --------
%   scalar        :     Scalar singleton output.
%
% By: Max Murphy  v1.0   09/03/2018  Original version (R2017b)

%% PARSE INPUT
% Default to warning user about multiple variables
if nargin < 4
   warnFlag = true;
end

% Default to using index 1
if nargin < 3
   varNum = 1;
end

% Default value if file not found is NaN
if nargin < 2
   defVal = nan;
end

%% CHECK FOR FILE EXISTENCE
fname = fullfile(F.folder,F.name);
if exist(fname,'file') == 0
   fprintf(1,'->\t%s not found.\n',F.name);
   scalar = defVal;
   return;
end

%% LOAD FILE AND GET VARIABLE NAME(S)
tmp = load(fname);
in = fieldnames(tmp);

%% (OPTIONAL) WARN USER IF MULTIPLE VARIABLES IN FILE
if warnFlag
   % If there is more than one vector, warn user that they might not be
   % loading the one they hoped...
   k = numel(in);
   if k > 1
      warning('%d variables in %s. Loading %s...',k,F.name,in{varNum});
   end
end

%% PICK 1 VARIABLE TO RETURN
scalar = tmp.(in{varNum});
% Check if it is not a scalar
if numel(scalar) > 1
   error('More than 1 element in %s. Check file contents of %s.',...
      in{varNum},F.name);
end

end