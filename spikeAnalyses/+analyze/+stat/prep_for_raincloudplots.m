function [data,Ge] = prep_for_raincloudplots(G,vars)
%PREP_FOR_RAINCLOUDPLOTS Prepare dataset for RainCloudPlot
%
%  [data,Ge] = analyze.stat.prep_for_raincloudplots(G);
%  [data,Ge] = analyze.stat.prep_for_raincloudplots(G,vars);
%
% Inputs
%  G    - Data table of fit gauspuls functions
%
% Output
%  data - Data struct with cell arrays for `gfx__.rain.cloud(data);`
%  Ge   - Restricted data table
%
% See also: gfx__.rain.cloud

if nargin < 2
   vars = {'PeakOffset','EnvelopeBW','Duration'};
end
vars = union(vars,{'PostOpDay'});

addHelperRepos();
Ge = analyze.stat.remove_excluded(G,3);
fcn = @(a,d)[cell(3,d-1) a, cell(3,30-d-1)];
[groups,tid] = findgroups(Ge(:,{'GroupID','Area','PostOpDay'}));
tmp = splitapply(@(x,y,z,d){fcn({x;y;z},double(d(1)))},Ge(:,vars),groups);

[gg,a] = findgroups(tid(:,{'GroupID','Area'}));
tmp = splitapply(@(in,d)analyze.stat.combine_cells(in,double(d)),...
   tmp,tid.PostOpDay,gg);
tmp = horzcat(tmp{:});

nVar = numel(vars)-1;
vec = 1:nVar:size(tmp,2);
data = struct;
for iVar = 1:nVar
   data.(vars{iVar}) = tmp(:,vec + (iVar-1));
end
data.ID = strcat(string(a.GroupID),string(a.Area))';

end