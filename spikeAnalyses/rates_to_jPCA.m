% RATES_TO_JPCA Short script summarizing steps to go from rate Table to jPCA table used with population dynamics analyses
clearvars -except T

% Makes sure the rates database is actually loaded
if exist('T','var')==0
   T = getfield(load(defaults.files('rate_table_default_matfile')),'T');
end
   
% Step 1 for jPCA export: should be fast
M = analyze.marg.get_subset(T); 


% % (Optional) Marginalize dataset: should be fast
% M = analyze.marg.subtract_rat_means(M,... % This is done anyways in jPCA later
%    {'AnimalID','Area','Channel','Alignment','Outcome'}); 
M = utils.filterByNTrials(M,5,'Successful'); % This should take us from roughly 470,000 rows to 110,000 rows


% Step 3 for jPCA export: takes a few minutes
% D = analyze.jPCA.multi_jPCA(M,5); % Use default parameters (short timescale, etc.)
D = analyze.jPCA.multi_jPCA(M,5,'t_lims',[-650 350],'dt',2.5,'ord',3,'wlen',9);
D = sortrows(D,'AnimalID','ascend');
D.Projection = analyze.jPCA.recover_residuals(D.Projection);
D.Projection = analyze.jPCA.recover_channel_weights(D.Projection,'groupings','Area','subtract_xc_mean',false,'subtract_mean',false,'matType','skew');
D.Projection = analyze.jPCA.recover_channel_weights(D.Projection,'groupings','Area','subtract_xc_mean',false,'subtract_mean',false,'matType','best');
D.Projection = analyze.jPCA.recover_channel_weights(D.Projection,'groupings','Area','subtract_xc_mean',false,'subtract_mean',false,'matType','best_res_best');
D.Projection = analyze.jPCA.recover_channel_weights(D.Projection,'groupings','Area','subtract_xc_mean',false,'subtract_mean',false,'matType','best_res_skew');
D.Projection = analyze.jPCA.recover_channel_weights(D.Projection,'groupings','Area','subtract_xc_mean',false,'subtract_mean',false,'matType','skew_res_skew');
D = analyze.dynamics.primaryPCDynamicsByArea(D);
D = analyze.dynamics.primary_regression_space(D);
save(defaults.files('multi_jpca_long_timescale_matfile'),'D','-v7.3'); % Was not used in stats.mlx, this is the long timescale version