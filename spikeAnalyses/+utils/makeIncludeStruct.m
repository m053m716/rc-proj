function includeStruct = makeIncludeStruct(Include,Exclude)
%% MAKEINCLUDESTRUCT    Make "include" struct for GETRATE method of BLOCK
%
%  includeStruct = utils.MAKEINCLUDESTRUCT(Include,Exclude);
%
%  --------
%   INPUTS
%  --------
%   Include    :     Cell array (or empty matrix) of events to include. Can
%                       be basically any variable name from BEHAVIORDATA of
%                       a given BLOCK object.
%
%                    Default: {'Reach','Grasp','PelletPresent'}
%
%   Exclude    :     Cell array (or empty matrix) of events to include. Can
%                       be basically any variable name from BEHAVIORDATA of
%                       a given BLOCK object.
%
%                    Default: []
%
% By: Max Murphy  v1.0  2019-10-17  Original version (R2017a)

%% Parse input
if nargin < 1
   Include = {'Reach','Grasp','PelletPresent'};
end

if nargin < 2
   Exclude = [];
end

%% Check the inputs (since sometimes I accidentally write 'Successful')
[incSucc,incUnsucc,excSucc,excUnsucc] = utils.initFalseArray(1);
idx = ismember(Include,'Successful');
if sum(idx)>0
   Include(idx) = [];
   incSucc = true;
end

idx = ismember(Include,'Unsuccessful');
if sum(idx) > 0
   Include(idx) = [];
   incUnsucc = true;
end
   
idx = ismember(Exclude,'Successful');
if sum(idx)>0
   Exclude(idx) = [];
   excSucc = true;
end

idx = ismember(Exclude,'Unsuccessful');
if sum(idx) > 0
   Exclude(idx) = [];
   excUnsucc = true;
end

if incSucc && excSucc
   error('Successes to both be included & excluded? Check includeStruct.');
end

if incUnsucc && excUnsucc
   error('Unsuccessful trials to be both included & excluded? Check includeStruct.');
end

if incSucc && ~incUnsucc
   Include = [Include, 'Outcome'];
elseif incUnsucc && ~incSucc
   Exclude = [Exclude, 'Outcome'];
end

% If both true for Include, do nothing
if excSucc && excUnsucc
   error('Exclude all trials? Check includeStruct.');
end

%% Assign output
includeStruct = struct;
if (~isempty(Include)) && (~isempty(Exclude))
   idx = contains(Include,Exclude);
   if any(idx)
      error('''%s'' is in both Include and Exclude keys. Exclude all trials?',Include{find(idx,1)});
   end
end
includeStruct.Include = Include;
includeStruct.Exclude = Exclude;

end