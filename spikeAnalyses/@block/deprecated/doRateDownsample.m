function doRateDownsample(obj)
%DORATEDOWNSAMPLE  Does rate down-sampling (if needed)
%
%  doRateDownsample(obj); (deprecated)
%
%  --> Note: this creates the files for 'NormSpikeRate' and
%            requires that the `doSpikeBinning` and
%            `doBinSmoothing` methods have already been done (they
%            are done in that order)

n_ds_bin_edges = defaults.block('n_ds_bin_edges');
r_ds = defaults.block('r_ds');

pre_trial_norm = defaults.block('pre_trial_norm');
% Note: spike_rate_smoother files will all still be at 1-ms
% "sample rate" although the smooth window may be "20-" or "30-"
% ms. Those files also have square-root-transform already applied.
spike_rate_smoother = defaults.block('spike_rate_smoother');
norm_spike_rate_tag = defaults.block('norm_spike_rate_tag');
fStr_in = defaults.block('fname_orig_rate');
fStr_out = defaults.block('fname_ds_rate');
o = defaults.block('all_outcomes');
e = defaults.block('all_events');
for iO = 1:numel(o)
   for iE = 1:numel(e)
      % Skip if there is no file to decimate
      str = sprintf(fStr_in,obj.Name,spike_rate_smoother,e{iE},o{iO});
      fName_In = fullfile(obj.getPathTo('rate'),str);
      if exist(fName_In,'file')==0
         continue;
      end
      
      % Skip if it's already been extracted
      str = sprintf(fStr_out,obj.Name,norm_spike_rate_tag,e{iE},o{iO},r_ds);
      fName_Out = fullfile(obj.getPathTo('rate'),str);
      if exist(fName_Out,'file')~=0
         continue;
      else
         fprintf(1,'Extracting %s...\n',fName_Out);
      end
      in = load(fName_In,'data','t');
      if isfield(in,'t')
         if ~isempty(in.t)
            out.t = linspace(in.t(1),in.t(end),n_ds_bin_edges);
         else
            out.t = linspace(obj.T(1),obj.T(end),n_ds_bin_edges);
         end
      else
         out.t = linspace(obj.T(1),obj.T(end),n_ds_bin_edges);
      end
      
      if (max(abs(out.t)) < 10)
         out.t = out.t * 1e3;
      end
      
      data = obj.doSmoothNorm(in.data,pre_trial_norm);
      out.data = zeros(size(data,1),n_ds_bin_edges,size(data,3));
      for ii = 1:size(data,1)
         for ik = 1:size(data,3)
            out.data(ii,:,ik) = decimate(data(ii,:,ik),r_ds);
         end
      end
      save(fName_Out,'-struct','out');
      
   end
end


end