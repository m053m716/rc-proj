function D = multi_jPCA(S,varargin)
%MULTI_JPCA Apply jPCA to short segments of `Data` focused on tagged events
%
%  D = analyze.jPCA.multi_jPCA(S);
%  D = analyze.jPCA.multi_jPCA(S,params);
%  D = analyze.jPCA.multi_jPCA(S,params,'Name',value,...);
%  D = analyze.jPCA.multi_jPCA(S,'Name',value,...);
%
% Inputs
%  S   - A data table that has the cross-"condition"-mean subtracted for 
%        each "condition" (alignment/trial/recording) combination.
%
%  params - An optional struct containing the following fields:
%   .analyzeTimes  
%     -> Default is empty; if it's empty all times are used.
%   .numPCs        
%     -> Default is 6. The number of PCs to use during pre-processing
%   .normalize     
%     -> Default is 'true'.  Normalize each neuron (column) by FR range?
%   .softenNorm    
%     -> Default is 10. How much do we "under-normalize" for low FR neurons
%        -> 0 means standard normalization
%        -> 10 maps an FR range of 10 spikes/sec -> 0.5
%   .suppressRosettes    
%        -> Set true to prevent rosette plots
%   .suppressHistograms    
%        -> Set true to prevent phase histogram plots
%   .suppressText          
%        -> Set true to suppress command window output text
%
%  varargin - Alternatively, can use `<'Name',value> input argument pair
%              syntax to parameters without introducing the entire
%              parameter struct, using default values for the rest (or if
%              `params` is provided as first "varargin" argument, it will
%              still be parsed correctly).
%
% Output
%   D - Table formatted output that includes data taken from `Projection` 
%       and `Summary` structs returned by standard `analyze.jPCA.jPCA` call
%
%       This "multi_jPCA" function "chunks" longer time-segments and
%       returns table rows with projections and transformation info
%       regarding the same trials in short epochs but aligned to the
%       following events:
%                 
%                 * 'Reach'
%                 * 'Grasp'
%                 * 'Support'
%                 * 'Complete'
%
% See Also: analyze.jPCA.jPCA, analyze.jPCA.convert_table, 
%           analyze.marg.subtract_rat_means, analyze.marg.get_subset,
%           analyze.slice

% % % Parse Input Arguments  % % % % % % %
if nargin < 2
   params = defaults.jPCA('jpca_params');
   % Note: setting `batchExportFigs` to true overrides this behavior
   params.suppressPCstem = true;
   params.suppressRosettes = true;
   params.suppressHistograms = true;
   params.suppressText = false;
   params.markEachMetaEvent = false;
else
   if isstruct(varargin{1})
      params = varargin{1};
      varargin(1) = [];
   else
      params = defaults.jPCA('jpca_params');
      % Note: setting `batchExportFigs` to true overrides this behavior
      params.suppressPCstem = true;
      params.suppressRosettes = true;
      params.suppressHistograms = true;
      params.suppressText = false;
      params.markEachMetaEvent = false;
   end
   fn = fieldnames(params);
   for iV = 1:2:numel(varargin)
      iField = ismember(lower(fn),lower(varargin{iV}));
      if sum(iField)==1
         params.(fn{iField}) = varargin{iV+1};
      else
         warning(['JPCA:' mfilename ':BadParameter'],...
            ['\n\t->\t<strong>[JPCA]:</strong> ' ...
             'Unrecognized parameter name: "<strong>%s</strong>"\n'],...
             varargin{iV});
      end
   end
end
% % % % % % % End Argument Parsing % % % %

% % Collect other `default` parameters % %
[t_lims,dt,ord,wlen,min_n_trials] = defaults.jPCA(...
   't_lims_short','dt_short',...
   'sg_ord_short','sg_wlen_short',...
   'min_n_trials_def');

% % Parse and do some filtering on input Table % %
if ~contains(S.Properties.UserData.Processing,'Keep-Min-')
   % If we haven't screened based on minimum number of total trials, do so
   S = utils.filterByNTrials(S,min_n_trials); % Default is 'All' outcomes
end
[uDays,nDay,uAlignment,nAlignment] = parseFromInputTable(S);

% Get names of "plan event," which is used in each alignment case to rotate
% the Mskew projections so that they demonstrate maximum variance at the
% time of the alignment event.
planEvent = cell(size(uAlignment));
for i = 1:nAlignment
   planEvent{i} = ['t' char(uAlignment(i))];
end

% Initialize output table
D = analyze.jPCA.gross_output_table(nAlignment*nDay);

% % Iterate on each alignment, for each day % %
iRow = 0;
for iDay = 1:nDay
   for iAlign = 1:nAlignment
      if iAlign == 1
         p = params;
      elseif iAlign == 2
         % Prior to incrementing `iRow`:
         p.numPCs = D.Summary{iRow}.params.numPCs;
         p.threshPC = nan;
      end
      p.planStateEvent = planEvent{iAlign};
      iRow = iRow + 1;
      D.Data{iRow} = analyze.jPCA.convert_table(...
         S,char(uAlignment(iAlign)), ...
            'PostOpDay',uDays(iDay), ...
            't_lims',t_lims, ...
            'dt',dt, ...
            'sg_ord',ord, ...
            'sg_wlen',wlen ...
         );
      D.Alignment(iRow) = string(uAlignment(iAlign));
      if isempty(D.Data{iRow})
         continue;
      end
      D.AnimalID(iRow) = string(D.Data{iRow}(1).AnimalID);
      D.Group(iRow) = string(D.Data{iRow}(1).Group);
      D.PostOpDay(iRow) = D.Data{iRow}(1).PostOpDay;
      [D.Projection{iRow},D.Summary{iRow},D.PhaseData{iRow}] = ...
         analyze.jPCA.jPCA(D.Data{iRow},params);
   end
end

   function [ud,nDay,uAlign,nAlignment] = parseFromInputTable(S)
      %PARSEFROMINPUTTABLE Parse unique days & alignments (depends input)
      %
      %  [ud,nDays,uAlign,nAlignment] = parseFromInputTable(S);
      %
      %  Inputs
      %     S - Same as main input table to function
      %
      %  Output
      %     ud - Unique days
      %     nDays - Total # days
      %     uAlign - Unique alignments
      %     nAlignment - Total # alignments
      
      ud = unique(S.PostOpDay);
      nDay = numel(ud);
      
      uAlign = unique(S.Alignment);
      nAlignment = numel(uAlign);
   end

end