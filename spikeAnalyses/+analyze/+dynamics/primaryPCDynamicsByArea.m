function D = primaryPCDynamicsByArea(D,varargin)
%PRIMARYPCDYNAMICSBYAREA Test main PC "plane" by top PC of both area states
%
%  D = analyze.dynamics.primaryPCDynamicsByArea(D);
%  D = analyze.dynamics.primaryPCDynamicsByArea(D,'Name',value,...);
%
% Inputs
%  D - Data table from `analyze.jPCA.multi_jPCA`
%
% Output
%  D - Updated data table
%
% See also: analyze.dynamics, analyze.jPCA, analyze.pc, analyze.pc.apply

pars = struct;
pars.opts = defaults.experiment('pca_opts');
fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if size(D,1) > 1
   for iD = 1:size(D,1)
      D(iD,:) = analyze.dynamics.primaryPCDynamicsByArea(D(iD,:),pars);
   end
   return;
end
% Get rates
data = D.Data{1};
nSamples = numel(data(1).times);
nTrials = numel(data);

% Get trial-averaged mean for each channel
X = cat(3,data.A);
mu_xt = nanmean(X,3);
% Subtract trial-averaged mean for each channel, and then subtract any
% within-trial DC-bias for each channel
Y = X - mu_xt;
mu_t = squeeze(nanmean(Y,1))';

% Subtract both the cross-trial mean and the within-trial mean from data
% prior to PCA processing. PCA intrinsically removes the remaining
% channel-mean.
Z = vertcat(data.A) - repmat(mu_xt,nTrials,1) - repelem(mu_t,nSamples,1);

P = D.Projection{1};
CID = D.CID{1};

[G,TID] = findgroups(CID(:,["Alignment","Area","AnimalID"]));
[P.PC_G] = deal(G);
[P.PC_TID] = deal(TID);

PC_T = struct;
PC_T.coeff = cell(1,2);
PC_T.coeff_inv = cell(1,2);
PC_T.score = cell(1,2);
PC_T.explained = cell(1,2);
PC_T.channel_mean = cell(1,2);
PC_T.proj_mu = cell(1,2);
for iG = 1:2
   idx = (G==iG)';
   % Iterate on each area
   [PC_T.coeff(iG),PC_T.score(iG),PC_T.explained(iG),PC_T.channel_mean(iG)] = ...
      analyze.pc.apply(Z,sum(idx),pars.opts,idx);
   ci = inv(PC_T.coeff{iG}');
   PC_T.coeff_inv{iG} = ci(:,1:3);
   PC_T.coeff{iG} = PC_T.coeff{iG}(:,1:3);
   PC_T.score{iG} = PC_T.score{iG}(:,1:3);
   PC_T.proj_mu{iG} = mu_xt(:,idx) * PC_T.coeff_inv{iG};
end
PC_T.proj_mu = [PC_T.proj_mu{1}(:,1),PC_T.proj_mu{2}(:,1),...
                PC_T.proj_mu{1}(:,2),PC_T.proj_mu{2}(:,2),...
                PC_T.proj_mu{1}(:,3),PC_T.proj_mu{2}(:,3)];

PC_T.score = horzcat(PC_T.score{:});
PC_T.explained = [PC_T.explained{1}(1:3); PC_T.explained{2}(1:3)];
PC_T.cross_trial_mean = mu_xt;
PC_T.within_trial_mean = mu_t;
PC_T.G = G;
PC_T.TID = TID;

[P.PC_T] = deal(PC_T);

% Compute dynamic system model using the outputs of the two areas
T1 = repmat([true(nSamples-1,1);false],nTrials,1);
T2 = repmat([false;true(nSamples-1,1)],nTrials,1);
dX = (PC_T.score(T2,:) - PC_T.score(T1,:)) ./ nanmean(diff(data(1).times)*1e-3);
X  = (PC_T.score(T2,:)+PC_T.score(T1,:))./2;
Marea_pcs = (dX' / X')';
dX_Proj = X * Marea_pcs; % Recover projection

SS = analyze.jPCA.recover_explained_variance(dX,X,Marea_pcs,nanmean(PC_T.explained));

% Reshape the arrays and assign them to variables
dX_PC = mat2cell(dX,ones(1,nTrials).*(nSamples-1),6);
X_PC = mat2cell(X,ones(1,nTrials).*(nSamples-1),6);
dX_PC_Proj = mat2cell(dX_Proj,ones(1,nTrials).*(nSamples-1),6);
[P.dX_PC] = deal(dX_PC{:});
[P.X_PC] = deal(X_PC{:});
[P.dX_PC_Proj] = deal(dX_PC_Proj{:});

% Assign output back out
D.Projection{1} = P;
D.Summary{1}.SS.area_pcs = SS;

end