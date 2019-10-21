function xPCA(obj,align,includeStruct,area)
%% XPCA  "Cross" PCA

%% DEFAULTS
if nargin < 2
   align = defaults.block('alignment');
end

if nargin < 3
   includeStruct = utils.makeIncludeStruct({'Grasp','Reach','Outcome'});
end

if nargin < 4
   area = 'Full';
end

%% HANDLE OBJECT ARRAY
if numel(obj) > 1
   for ii = 1:numel(obj)
      obj(ii).xPCA;
   end
   return;
end

%% GET TIME LIMITS
tLim = [defaults.xPCA('t_start'), defaults.xPCA('t_stop')];

%%
pcStruct = utils.doTrialPCA(X);


end