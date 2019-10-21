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

%% Assign output
includeStruct = struct;
includeStruct.Include = Include;
includeStruct.Exclude = Exclude;

end