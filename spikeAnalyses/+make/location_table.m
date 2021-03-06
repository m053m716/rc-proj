function Locations = location_table(T,E)
%LOCATION_TABLE  Makes "Locations" table based on aggregate Rate table
%
%  Locations = make.location_table(T);
%
%  Locations = make.location_table(T,E);
%
%  -- Inputs --
%  T     :     Table from `T = getRateTable(gData,{'e1,'e2',...});`
%              -> Where e1,... are the events of interest
%
%              -> `'T'` can also be given as a char array that indicates
%                    the full filename of a written table to read in and
%                    use to parse row names from.
%
%  E     :     (Optional) Table of
%                 {'Rat','CFA_AP','CFA_ML','RFA_AP','RFA_ML'}
%                 Which is used to give the coordinates of both electrodes
%                 (centers; units: mm)
%              -> Can be supplied without giving `T` input by calling:
%                 Locations = make.location_table([],E);
%
%  -- Output --
%  Locations : Table with X, Y coordinate data for Tableau background image
%              co-registration, which corresponds to the anteroposterior
%              axis (X) and mediolateral (Y) coordinate of the image to be
%              co-registered onto a background of the rat's skull from a
%              dorsal view.

% Ensure other repos are present
utils.addHelperRepos();

% Read in data tables %
if nargin < 2
   E = readtable(defaults.block('elec_info_xlsx'));
end

if nargin < 1
   T = defaults.files('default_rowmeta_matfile');
elseif isempty(T)
   T = defaults.files('default_rowmeta_matfile');
end

if ischar(T)
   in = load(T,'RowMeta');
   T = in.RowMeta; clear in;
end

if ~ismember('RowID',T.Properties.VariableNames)
   T.RowID = T.Properties.RowNames;
end

[AnimalID,Rat] = defaults.experiment('rat_cats','rat_id');
ID = table(AnimalID,Rat);
[Locations,iSorted] = outerjoin(T,ID,...
   'Keys',{'AnimalID'},...
   'Type','Left',...
   'MergeKeys',true);
[~,iRestore] = sort(iSorted,'ascend');
Locations = Locations(iRestore,:);
sounds__.play('pop',0.8,-25);

% % Get other info related to electrode positions % %
[grid_x,grid_y,grid_ord,area_cats] = defaults.block(...
   'elec_grid_x','elec_grid_y','elec_grid_ord','area_cats');
grid_x = grid_x(:);
grid_y = grid_y(:);
grid_ord = grid_ord(:);

% % % Export the corresponding coordinate of each row % % %
E.Rat = categorical(E.Rat);
XDIM = {'RFA_AP','CFA_AP'};
YDIM = {'RFA_ML','CFA_ML'};
AnimalID = [];
Area = [];
Xc = [];
Yc = [];
n = size(E,1);
for i = 1:numel(area_cats)
   AnimalID = [AnimalID; E.Rat]; %#ok<*AGROW>
   Area = [Area; repmat(area_cats(i),n,1)];
   Xc = [Xc; ones(n,1).*E.(XDIM{i})];
   if strcmp(YDIM{i},'CFA_ML')
      % Need to multiply by -1 to reflect that it's in other hemisphere
      Yc = [Yc; -ones(n,1).*E.(YDIM{i})];
   else
      Yc = [Yc; ones(n,1).*E.(YDIM{i})];
   end
end
Key = table(AnimalID,Area,Xc,Yc);
sounds__.play('pop',1.0,-20);

% Assigns "area centers" to `Locations` table
[Locations,iSorted] = outerjoin(Locations,Key,...
   'Keys',{'AnimalID','Area'},...
   'RightVariables',{'Xc','Yc'},...
   'Type','Left',...
   'MergeKeys',true);
[~,iRestore] = sort(iSorted,'ascend');
Locations = Locations(iRestore,:);

X = Locations.Xc;
Y = Locations.Yc;
for i = 1:numel(grid_ord)
   idx = Locations.Channel == i;
   X(idx) = X(idx) + grid_x(grid_ord == i);
   Y(idx) = Y(idx) + grid_y(grid_ord == i);
end
Locations.X = X;
Locations.Y = Y;
Locations.Properties.RowNames = Locations.RowID;
Locations.Properties.DimensionNames{1} = 'Series_ID';
sounds__.play('pop',1.2,-15);

   function T = fixName(T,var,tabName)
      %FIXNAME  Helper function to fix variable names messed up by joins
      %
      %  T = fixName(T,var);
      %
      %  T : Table
      %  var : Name of variable to fix (original); e.g. 'AnimalID' if it
      %  gets converted to 'AnimalID_Locations' for a table named
      %  "Locations"
      %  tabName : Name of table variable from outerjoin procedure
      %     (In above example, 'Locations')
      
      if iscell(var)
         for iVar = 1:numel(var)
            T = fixName(T,var{iVar},tabName);
         end
         return;
      end
      
      badName = [var '_' tabName];
      badVarIdx = ismember(T.Properties.VariableNames,badName);
      T.Properties.VariableNames{badVarIdx} = var;
      
   end

end