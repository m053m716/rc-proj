function Gr = remove_excluded(G)
%REMOVE_EXCLUDED Remove outlier data or categories otherwise not in model
%
%  Gr = analyze.stat.remove_excluded(G);
%
% Inputs
%  G          - Table as returned by analyze.stat.get_fitted_table
%
% Output
%  Gr         - Table in same format as `G` but with exclusions removed
%
% See also: analyze.stat.get_fitted_table, defaults.stat

% Return configured parameters %
[max_env_bw,max_sse,peak_lims,outcome,align,days_rm,mdl] = defaults.stat(...
   'max_env_bw','max_sse','peak_offset_lims',...
   'included_outcome','included_alignment','removed_days',...
   'modelspec');
[min_dur,max_dur] = defaults.complete_analyses(...
   'min_duration','max_duration');

G.Properties.UserData.Exclusions = struct; % Initialize exclusion struct

% Only keep desired rows %
iOutcome = ismember(string(G.Outcome),outcome);
G.Properties.UserData.Exclusions.Outcome = sum(~iOutcome);

iAlignment = ismember(string(G.Alignment),align);
G.Properties.UserData.Exclusions.Alignment = sum(~iAlignment);

iDay = ~ismember(G.PostOpDay,days_rm);
G.Properties.UserData.Exclusions.ByDay = sum(~iDay);
iCategorical = iOutcome & iAlignment & iDay;
G.Properties.UserData.Exclusions.Categorical = sum(~iCategorical);
Gr = G(iCategorical,:); % Categorical exclusions

% Exclude based on durations
iDuration = Gr.Duration>=min_dur & Gr.Duration<=max_dur;
Gr.Properties.UserData.Exclusions.Duration = sum(~iDuration);
Gr = Gr(iDuration,:);

iLowTau = (Gr.PeakOffset > peak_lims(1));
iHighTau = (Gr.PeakOffset < peak_lims(2));
Gr.Properties.UserData.Exclusions.LowTau = sum(~iLowTau);
Gr.Properties.UserData.Exclusions.HighTau = sum(~iHighTau);

iHighEnvelopeBW = (Gr.EnvelopeBW < max_env_bw);
iHighError = (Gr.PeakOffset < max_sse);
Gr.Properties.UserData.Exclusions.HighEnvelopeBW = sum(~iHighEnvelopeBW);
Gr.Properties.UserData.Exclusions.HighError = sum(~iHighError);

% Convert categories so only the relevant ones remain %
Gr.Outcome = string(Gr.Outcome);
Gr.Outcome = categorical(Gr.Outcome);
Gr.Alignment = string(Gr.Alignment);
Gr.Alignment = categorical(Gr.Alignment);

% Compute PostOpWeek %
Gr.PostOpPhase = ceil((Gr.PostOpDay-2)/7);
Gr.PostOpPhase = ordinal(Gr.PostOpPhase);
% Gr.PostOpDay = ordinal(Gr.PostOpDay);

% % % Remove exclusions % % %
iData = iHighEnvelopeBW & iHighError & iLowTau & iHighTau;
Gr.Properties.UserData.Exclusions.FitParameter = sum(~iData);
Gr = Gr(iData,:);

% % Compute PCs %
% Z = [...
%    Gr.PeakOffset,         ...
%    Gr.EnvelopeBW,         ...
%    Gr.PeakFreq,           ...
%    Gr.LinearTrendCoeff,   ...
%    Gr.LinearTrendOffset  ...
%      ];
% [~,score] = pca(Z);
% Gr.Z = score(:,z_pc_index);

Gr.Properties.UserData.Z.Offset = min(Gr.PeakOffset)-1e-3;
o = Gr.PeakOffset-Gr.Properties.UserData.Z.Offset;
Gr.Properties.UserData.Z.Scale = max(o)+1e-3;
Gr.Z = (o)./ Gr.Properties.UserData.Z.Scale;

% Update UserData to reflect current state of table %
Gr.Properties.UserData.exclusions_removed = true;
Gr.Properties.UserData.modelspec = mdl;

end