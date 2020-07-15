function D = multi_jPCA(S,min_n_trials,varargin)
%MULTI_JPCA Apply jPCA to short segments of `Data` focused on tagged events
%
%  D = analyze.jPCA.multi_jPCA(S);
%  D = analyze.jPCA.multi_jPCA(S,min_n_trials,params);
%  D = analyze.jPCA.multi_jPCA(S,params,'Name',value,...);
%  D = analyze.jPCA.multi_jPCA(S,'Name',value,...);
%
% Inputs
%  S   - A data table that has the cross-"condition"-mean subtracted for 
%        each "condition" (alignment/trial/recording) combination.
%
%  min_n_trials - Minimum # required trials
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
switch nargin
   case 1
      min_n_trials = 5;
      params = defaults.jPCA('jpca_params');
      params = modifyMultiParams(params);
   case 2
      if isstruct(min_n_trials)
         params = min_n_trials;
         min_n_trials = params.min_n_trials_def;
      else
         params = defaults.jPCA('jpca_params');
      end
      % Note: setting `batchExportFigs` to true overrides this behavior
      params = modifyMultiParams(params);
   otherwise
      if isstruct(varargin{1})
         params = varargin{1};
         varargin(1) = [];
      elseif isstruct(min_n_trials)
         params = min_n_trial;
         min_n_trials = params.min_n_trials_def;
      else
         params = defaults.jPCA('jpca_params');
         % Note: setting `batchExportFigs` to true overrides this behavior
         params = modifyMultiParams(params);
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
Areas = "All";
nArea = numel(Areas);

% Get restricted table based on minimum # trials
S = utils.filterByNTrials(S,min_n_trials);

% % Parse days and animals from input Table % %
[uDays,nDay,uAlignment,nAlignment,nAnimal] = parseFromInputTable(S);

% Get names of "plan event," which is used in each alignment case to rotate
% the Mskew projections so that they demonstrate maximum variance at the
% time of the alignment event.
planEvent = cell(size(uAlignment));
for i = 1:nAlignment
   planEvent{i} = ['t' char(uAlignment(i))];
end

% Initialize output table
D = analyze.jPCA.gross_output_table(nAlignment*nDay*nArea*nAnimal);

% % Iterate on each alignment, for each day % %
iRow = 0;
for iDay = 1:nDay
   sThis = S(S.PostOpDay == uDays(iDay),:);
   uAnimal = unique(sThis.AnimalID);
   for iAnimal = 1:numel(uAnimal)
      sThisAnimal = sThis(sThis.AnimalID == uAnimal(iAnimal),:);
      for iArea = 1:nArea
         for iAlign = 1:nAlignment
            p = params;
            p.planStateEvent = planEvent{iAlign};
            
            [~,iTrial] = unique(sThisAnimal.Trial_ID);
            nTrial = sum(sThisAnimal.Outcome(iTrial) == "Successful");
            if (nTrial < min_n_trials)
               continue;
            end

            [data,~,~,CID] = analyze.jPCA.convert_table(...
               sThisAnimal,string(uAlignment(iAlign)),Areas(iArea), ...
                  'PostOpDay',uDays(iDay),'Outcome','Successful',...
                  't_lims',params.t_lims, ...
                  'dt',params.dt, ...
                  'sg_ord',params.ord, ...
                  'sg_wlen',params.wlen ...
               );
            p.numPCs = p.numPCByArea.(Areas(iArea));
            if (size(data(1).A,2) < p.numPCs) || isempty(data)
               continue;
            else
               iRow = iRow + 1;
               D.Data{iRow} = data;
            end
            D.Alignment(iRow) = string(uAlignment(iAlign));
            D.Area(iRow) = Areas(iArea);
            D.AnimalID(iRow) = string(D.Data{iRow}(1).AnimalID);
            D.Group(iRow) = string(D.Data{iRow}(1).Group);
            D.PostOpDay(iRow) = D.Data{iRow}(1).PostOpDay;
            [D.Projection{iRow},D.Summary{iRow},D.PhaseData{iRow}] = ...
               analyze.jPCA.jPCA(D.Data{iRow},p);
            D.CID{iRow} = CID;
         end
      end
   end
end
% Remove extras
D(cellfun(@isempty,D.Projection),:) = [];
D.Properties.UserData = struct('type','MultiJPCA');

   % Update default `jpca_params` struct for batch compatibility
   function params = modifyMultiParams(params)
      %MODIFYMULTIPARAMS Helper function to modify `jPCA_params` for `multi_jPCA`
      %
      %  params = modifyMultiParams(params);
      %
      % Inputs
      %  params - `params` struct from `defaults.jPCA('jpca_params');`
      %
      % Output
      %  params - Struct with modified fields
      
      params.suppressPCstem = true;
      params.suppressRosettes = true;
      params.suppressHistograms = true;
      params.suppressText = false;
      params.markEachMetaEvent = false;
      params.warningState = 'off'; % Turn off warnings
      params.threshPC = nan;
      
      % % Collect other `default` parameters % %
      [params.t_lims,params.dt,params.ord,params.wlen] = ...
         defaults.jPCA(...
            't_lims_short','dt_short',...
            'sg_ord_short','sg_wlen_short');
   end

   % Get unique days and animals from input table
   function [ud,nDay,uAlign,nAlignment,nAnimal] = parseFromInputTable(S)
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
      
      nAnimal = numel(unique(S.AnimalID));
   end

end