function Gr = remove_excluded(G,z_pc_index)
%REMOVE_EXCLUDED Remove outlier data or categories otherwise not in model
%
%  Gr = analyze.stat.remove_excluded(G);
%  Gr = analyze.stat.remove_excluded(G,z_pc_index);
%
% Inputs
%  G          - Table as returned by analyze.stat.get_fitted_table
%  z_pc_index - (Optional) PC index to use for "Z" response variable
%
% Output
%  Gr         - Table in same format as `G` but with exclusions removed
%
% See also: analyze.stat.get_fitted_table, defaults.stat

% Return configured parameters %
[max_env_bw,max_sse,peak_lims,outcome,align,days_rm,zIdx,mdl] = defaults.stat(...
   'max_env_bw','max_sse','peak_offset_lims',...
   'included_outcome','included_alignment','removed_days',...
   'default_z_pc_index','modelspec');
if nargin < 2
   z_pc_index = zIdx;
end

G.Properties.UserData.Excluded = struct; % Initialize exclusion struct

% Only keep desired rows %
iOutcome = ismember(string(G.Outcome),outcome);
G.Properties.UserData.Excluded.Outcome = sum(~iOutcome);

iAlignment = ismember(string(G.Alignment),align);
G.Properties.UserData.Excluded.Alignment = sum(~iAlignment);

iDay = ~ismember(G.PostOpDay,days_rm);
G.Properties.UserData.Excluded.ByDay = sum(~iDay);
iCategorical = iOutcome & iAlignment & iDay;
G.Properties.UserData.Excluded.Categorical = sum(~iCategorical);
Gr = G(iCategorical,:); % Categorical exclusions

iLowTau = (Gr.PeakOffset > peak_lims(1));
iHighTau = (Gr.PeakOffset < peak_lims(2));
Gr.Properties.UserData.Excluded.LowTau = sum(~iLowTau);
Gr.Properties.UserData.Excluded.HighTau = sum(~iHighTau);

iHighEnvelopeBW = (Gr.EnvelopeBW < max_env_bw);
iHighError = (Gr.PeakOffset < max_sse);
Gr.Properties.UserData.Excluded.HighEnvelopeBW = sum(~iHighEnvelopeBW);
Gr.Properties.UserData.Excluded.HighError = sum(~iHighError);

% Convert categories so only the relevant ones remain %
Gr.Outcome = string(Gr.Outcome);
Gr.Outcome = categorical(Gr.Outcome);
Gr.Alignment = string(Gr.Alignment);
Gr.Alignment = categorical(Gr.Alignment);

% Compute PostOpWeek %
Gr.PostOpPhase = ceil(Gr.PostOpDay/10);
Gr.PostOpPhase = ordinal(Gr.PostOpPhase);
Gr.PostOpDay = ordinal(Gr.PostOpDay);

% % % Remove exclusions % % %
iData = iHighEnvelopeBW & iHighError & iLowTau & iHighTau;
Gr.Properties.UserData.Excluded.FitParameter = sum(~iData);
Gr = Gr(iData,:);

% Compute PCs %
Z = [...
   Gr.PeakOffset,         ...
   Gr.EnvelopeBW,         ...
   Gr.PeakFreq,           ...
   Gr.LinearTrendCoeff,   ...
   Gr.LinearTrendOffset  ...
     ];
[~,score] = pca(Z);
Gr.Z = score(:,z_pc_index);

% Update UserData to reflect current state of table %
Gr.Properties.UserData.exclusions_removed = true;
Gr.Properties.UserData.modelspec = mdl;

end