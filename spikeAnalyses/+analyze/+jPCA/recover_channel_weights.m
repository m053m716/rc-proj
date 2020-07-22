function out = recover_channel_weights(D,varargin)
%RECOVER_CHANNEL_WEIGHTS Recover weightings for individual channels jPCs
%
%  out = analyze.jPCA.recover_channel_weights(D);
%  out = analyze.jPCA.recover_channel_weights(D,varargin);
%
% Examples:
%  out = analyze.jPCA.recover_channel_weights(D,'wrap',true);
%     -> "Wraps" output in cell array for `splitapply` workflow
%
%  out = analyze.jPCA.recover_channel_weights(D'groupings',groups);
%     -> `groups` is a vector of length nChannels, with `k` unique indices
%         that correspond to matching columns of `P.data` and group them
%         together according to some scheme (see 'CID' parameter below)
%
%  out = analyze.jPCA.recover_channel_weights(D,pars);
%     -> Give `pars` directly as parameters struct (see `pars` in code)
%
% Inputs
%  D        - Table recovered from analyze.jPCA.multi_jPCA
%  varargin - 'name',value optional input argument pairs
%              'wrap': 
%                 Set true to "wrap" output as cell (default is false)
%              'groupings': 
%                 Default is NaN; can provide as vector with k 
%                 unique indexing elements and length nChannels. 
%                 If `P` is table with 'CID' variable, then groupings is 
%                 the name of a 'CID' variable used with `findgroups` (or
%                 if 'CID' is provided directly via 'Name',value pairs.
%
% Output
%  out - Scalar cell. Cell contains:
%        Updated projection struct array (`P`) with new fields: 
%        'W' 
%        -> 'W' is a tensor of dimension [nSample x nPC x nGroupings]
%           * If `pars.groupings` is kept as nan, then
%              nGroupings == nChannels
%           * Otherwise, groupings can be used for example to combine array
%              elements by area or some other relevant channel grouping.
%        -> For a given grouping (g), this means that row (i) of column (j)
%           are equivalent to the contribution (linear scaling) of grouping
%           `g` to jPC component `j` at timestep `i` during some trial
%           (indexed by the corresponding struct element of the output `P`)
%        'W_Key'
%        -> 'W_Key' is a table where each row corresponds to the groupings
%                    dimension (third dimension) of 'W' and it indicates
%                    how groups were aggregated.
%        'W_Groups'
%        -> 'W_Groups' gives the index groupings (same as pars.groupings)
%        'CID'
%        -> 'CID' gives "channel" info (specifically, X and Y centers for
%              spatial plots for each group)
%
% See also: analyze.jPCA, analyze.jPCA.jPCA, analyze.jPCA.multi_jPCA,
%           analyze.jPCA.convert_table, jPCA.mlx

% % pars struct % %
pars = struct;
pars.wrap = false;
pars.groupings = nan;
pars.matType  = 'skew';
pars.projType = 'skew';
pars.rankType = 'eig';
pars.subtract_mean = true;
pars.subtract_xc_mean = true;
% % end pars struct % %

% % Parse variable inputs % %
fn = fieldnames(pars);

if ~istable(D)
   if isstruct(D)
      if ~isfield(D,'CID')
         error(['JPCA:' mfilename ':BadInputClass'],...
            ['\n\t->\t<strong>[RECOVER_CHANNEL_WEIGHTS]:</strong> ' ...
             '`D` as a struct must contain fields: `CID`, `W_Key`, `W_Groups`)']);
      end
   elseif iscell(D)
      if isstruct(D{1})
         if ~isfield(D{1},'CID')
            error(['JPCA:' mfilename ':BadInputClass'],...
            ['\n\t->\t<strong>[RECOVER_CHANNEL_WEIGHTS]:</strong> ' ...
             '`D` as a struct must contain fields: `CID`, `W_Key`, `W_Groups`)']);
         end
      else
         error(['JPCA:' mfilename ':BadInputClass'],...
            ['\n\t->\t<strong>[RECOVER_CHANNEL_WEIGHTS]:</strong> ' ...
             '`D` can be a cell array of structs)']);
      end
   else
      error(['JPCA:' mfilename ':BadInputClass'],...
            ['\n\t->\t<strong>[RECOVER_CHANNEL_WEIGHTS]:</strong> ' ...
             '`D` should be table (result of `multi_jPCA`)']);
   end
else
   if ~utils.check_table_type(D,'MultiJPCA')
      error(['JPCA:' mfilename ':BadTable'],...
         ['\n\t->\t<strong>[RECOVER_CHANNEL_WEIGHTS]:</strong> ' ...
          'Bad table type, should be result of `multi_jPCA`']);
   end
end

if numel(varargin) >= 1
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

if (size(D,1)>1) && (~isstruct(D))
   out = cell(size(D,1),1);
   pars.wrap = false;
   if iscell(D)
      for ii = 1:size(D,1)
         out{ii} = analyze.jPCA.recover_channel_weights(D{ii},pars);
      end
   else
      for ii = 1:size(D,1)
         out{ii} = analyze.jPCA.recover_channel_weights(D(ii,:),pars);
      end
   end
   return;
end

matField = sprintf('M%s',lower(pars.matType));
if istable(D)
   CID = D.CID{1};
   S = D.Summary{1};
   P = D.Projection{1};
   m = P(1).misc.(matField);
   C = S.PCA.vectors_all; 
   if strcmpi(pars.rankType,'eig')
      [~,dEig] = eig(m);
      [~,sortIndices] = sort(abs(diag(dEig)),'descend');
   else
      sortIndices = S.SS.(pars.projType).explained.sort.vec.(pars.rankType);
   end
else
   CID = D(1).CID;
   C = D(1).misc.PCs;
   m = D(1).misc.(matField);
   if strcmpi(pars.rankType,'eig')
      [~,dEig] = eig(m);
      [~,sortIndices] = sort(abs(diag(dEig)),'descend');
   else
      sortIndices = D(1).misc.(pars.projType).explained.sort.vec.(pars.rankType);
   end
   P = D;
end

if ismember(matField,{'Mskew','Mbest_res_skew','Mskew_res_skew'})
   M = analyze.jPCA.convert_Mskew_to_jPCs(m); % sort by eig:
else
   M = m;
end

M = M(:,sortIndices);

if ischar(pars.groupings) || isstring(pars.groupings) || iscell(pars.groupings)   
   if ischar(pars.groupings)
      [pars.groupings,groupKey] = findgroups(CID(:,{pars.groupings}));
   else
      [pars.groupings,groupKey] = findgroups(CID(:,pars.groupings));
   end
end

% % Compute weights etc. below % %
% nTrial:   # "conditions" per jPCA nomenclature
% n:        # samples per trial
% nPC:      # principal components (and therefore, # jPCs); must be EVEN
n = size(P(1).state,1); 
nTrial = numel(P); 
nPC = size(M,1);

% Principal components map scores onto rates as: 
%     rates = scores * C' + repmat(mean(rates,1),n,1);
%
% We would like to recover the mapping from rates to scores, then map rates
% one channel at a time using the recovered transformation matrices, so we
% can see the related channel-specific activations when we look at a
% particular jPC plane.
Ci = inv(C'); 

% Create data matrix using original observed rates
X = vertcat(P.data);
if pars.subtract_mean
   % Get cross-trial mean as well as cross-condition mean.
   mu = repmat(nanmean(cat(3,P.data),3),nTrial,1);
   X = X - mu; % Subtract cross-trial mean
end
if pars.subtract_xc_mean
   X = X - nanmean(X,1); % Remove cross-condition mean from rates.
end
% % Depending on `groupings` either parse individual channel           % %
% % contributions (if `groupings` is NaN) or else use `groupings` in   % %
% % defining the output size as well as the matrix multiplies.         % %

if isnan(pars.groupings(1)) % Then parse from data
   nChannels = size(X,2);

   % Our "activations" are therefore a tensor that is different for each
   % channel.
   W = nan(size(X,1),nPC,nChannels);

   % Use projection matrix and PC coefficients to recover activations %
   for iCh = 1:nChannels
      W(:,:,iCh) = X(:,iCh)*Ci(iCh,1:nPC)*M;
   end

   % Distribute back as individual trials
   W_c = mat2cell(W,ones(1,nTrial).*n,nPC,nChannels);
   groupKey = table((1:nChannels)','VariableNames',{'Channel'});
   pars.groupings = (1:nChannels)';
else % Otherwise just define off size of groupings and grouping indices
   uG = unique(pars.groupings);
   nGroups = numel(uG);
   
   % Our "activations" are therefore a tensor that is different for each
   % grouping.
   W = nan(size(X,1),nPC,nGroups);
   
   % Use projection matrix and PC coefficients to recover activations %
   for iG = 1:nGroups
      idx = pars.groupings==uG(iG);
      W(:,:,iG) = X(:,idx)*Ci(idx,1:nPC)*M;
   end
   
   % Distribute back as individual trials
   W_c = mat2cell(W,ones(1,nTrial).*n,nPC,nGroups);
   X = splitapply(@mean,CID.X,pars.groupings);
   Y = splitapply(@mean,CID.Y,pars.groupings);
   Alignment = repmat(CID.Alignment(1),nGroups,1);
   AnimalID = repmat(CID.AnimalID(1),nGroups,1);
   
   CID = [table(Alignment,AnimalID,X,Y), groupKey];
   CID.Properties.Description = 'Channel information/metadata';
   CID.Properties.VariableUnits = [strings(1,2),"mm","mm",...
      strings(1,size(groupKey,2))];
   CID.Properties.UserData = struct('type','ChannelInfo');
end
W_mu = nanmean(W,1);
W_mu_c = mat2cell(W_mu,1,nPC,nGroups);
W_Key_c = repmat({groupKey},nTrial,1);
W_Groups_c = repmat({pars.groupings},nTrial,1);
CID_c = repmat({CID},nTrial,1);

if strcmpi(pars.matType,'skew')
   [P.W] = deal(W_c{:});
   [P.W_Key] = deal(W_Key_c{:});
   [P.W_Groups] = deal(W_Groups_c{:});
   [P.W_mu] = deal(W_mu_c{:});
   [P.CID] = deal(CID_c{:});
else
   outField = sprintf('W_%s',lower(pars.matType));
   [P.(outField)] = deal(W_c{:});
end


% Wrap it as a cell so we can use with `splitapply` workflow
if pars.wrap
   out = {P};
else
   out = P;
end

end