classdef xPCobj < handle
   % XPCOBJ  Class to store data for "cross"-PCA analyses
   %

   %% PROPERTIES
   % Public properties that are set on object construction and not changed.
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      X  % Data corresponding to vectors
      t  % Times (ms)
      V  % Principal component vectors
   end
   
   % Public properties that are set on object construction and not changed.
   % Not displayed by default
   properties (GetAccess = public, SetAccess = immutable, Hidden = true)      
      Area
      Group
      align
      includeStruct
      StartDay
      StopDay
      ICMS
      NTrial
      Score
   end
   
   % FLAGS
   properties (GetAccess = public, SetAccess = private, Hidden  = true)
      InitSuccessful
   end
   
   % Public properties that can be accessed and set externally
   properties (Access = public)
      ChannelInfo
      Block
   end
   
   % Public properties that must be modified using class methods
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      area
      group
      coeff
      score
      latent
      tsquared
      explained
      mu 
      xbar
      mse
      mse_norm
      varcapt
      
      pxx
      ff
   end
   
   % Public properties that can be accessed and set externally, but don't
   % populate the list of class properties
   properties (Access = public, Hidden = true)
      orig
      a
      a_idx
      g
      g_idx
      mask
      latent_dims
      li
      latent_threshold
      n_channels_removed
      varcapt_threshold
   end
   
   % Parent and Child properties should be set by appropriate methods of
   % this class but can be accessed by other classes.
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Parent
      Children
   end
   
   %% METHODS
   % Class constructor and data-handling
   methods (Access = public)
      % Class constructor
      function xPC = xPCobj(g,align,includeStruct,area,startDay,stopDay,icms)
         if nargin < 7
            icms = {'PF','DF','O','NR','PF-DF'};
         end
         
         if nargin < 6
            stopDay = defaults.experiment('poday_min');
         end
         
         if nargin < 5
            startDay = defaults.experiment('poday_max');
         end
         
         if nargin < 4
            area = {'RFA','CFA'};
         elseif ~ismember(upper(area),{'RFA','CFA'})
            area = {'RFA','CFA'};
         end
         
         if nargin < 3
            includeStruct = defaults.group('include');

         end
         
         if nargin < 2
            align = defaults.group('align');

            
            if (~isa(g,'group')) || (~isa(g,'rat'))
               if isscalar(g) && isnumeric(g)
                  xPC = repmat(xPC,g,1);
                  return;
               end
            end
         end
         
         % Defaults
         xPC.InitSuccessful = utils.initFalseArray;
         
         xPC.Area = area;
         if isa(g,'group')
            xPC.Group = {g.Name}.';
         elseif isa(g,'rat')
            if numel(g) > 1
               for iG = 1:numel(g)
                  xPC.Group = unique([xPC.Group; {g(iG).Parent.Name}]);
               end
            else
               xPC.Group = {g.Parent.Name};
            end
         end
         
         xPC.align = align;
         xPC.StartDay = startDay;
         xPC.StopDay = stopDay;
         xPC.includeStruct = includeStruct;   
         xPC.ICMS = icms;
         [X,channelInfo,t,nTrial,Score] = xPCobj.getAllRate(g,align,includeStruct,area,startDay,stopDay,icms);
         xPC.Score = Score;
         xPC.NTrial = nTrial;
         if isempty(X)
            return;
         end
         [xPC.X,xPC.t] = xPC.initDataStruct(X,t,channelInfo);
         xPC.V = xPC.doTrialPCA;
         if isempty(xPC.V)
            return;
         end
         xPC.setLatentIndex;
         xPC.doPCAreconstruction; % Does 'Full'
         pcStruct = xPC.getTopPCs;
         xPC.doPCAreconstruction(pcStruct); % Does 'Top'
         xPC.InitSuccessful = true;
         
      end
      
      function f = fs(xPC)
         f = 1/(nanmean(diff(xPC.t)) * 1e-3);
      end
   end
   
   % "DO" methods (for computing things
   methods (Access = public)
      % Reconstruct data using score and coefficient estimates
      function doPCAreconstruction(xPC,score,coeff,mu,name)
         if (nargin == 2) && isstruct(score)
            name = score.name;
            coeff = score.coeff;
            mu = score.mu;
            score = score.score;
         else
            if nargin < 5
               name = 'Full';
            end
            if nargin < 4
               mu = xPC.mu;
            end
            if nargin < 3
               coeff = xPC.coeff;
            end
            if nargin < 2
               score = xPC.score;
            end
         end
         

         xPC.xbar.(name) = score*(coeff') + mu;
         xPC.mse.(name) = mean((xPC.X - xPC.xbar.(name)).^2,1);
         xPC.mse_norm.(name) = xPC.mse.(name)./var(xPC.X,[],1);
         xPC.varcapt.(name) = 1 - xPC.mse_norm.(name);
         
      end
      
      % Do PCA
      function v = doTrialPCA(xPC)
         warning('off','stats:pca:ColRankDefX');
         [xPC.coeff,xPC.score,xPC.latent,xPC.tsquared,xPC.explained,xPC.mu] = ...
            pca(xPC.X,'Economy',false);
         warning('on','stats:pca:ColRankDefX');
         v = xPC.score;
      end
      
      % Do bootstrapped-PCA
      function [v,iPC] = doPCAbootstrap(xPC,nReps,nRemove)
         if nargin < 3
            nRemove = defaults.xPCA('n_remove');
         end
         if nargin < 2
            nReps = defaults.xPCA('n_reps');
         end
         
         if numel(xPC) > 1
            [v,iPC] = utils.initCellArray(numel(xPC),1);
            for i = 1:numel(xPC)
               [v{i},iPC{i}] = doPCAbootstrap(xPC(i),nReps,nRemove);
            end
            return;
         end
         
         if nReps == 0
            v = utils.initNaNArray(size(xPC.V,1),xPC.li,1);
            iPC = utils.initNaNArray(1,size(xPC.X,2),1);
            v(:,:,1) = xPC.V(:,1:xPC.li);
            iPC(1,:,1) = 1:size(xPC.X,2);
            return;
         end
         
         
         warning('off','stats:pca:ColRankDefX');
         nTotal = size(xPC.X,2);
         k = nTotal - nRemove;
         if k  < defaults.xPCA('min_n_to_run')
            [v,iPC] = utils.initEmpty;
            return;
         else
            v = utils.initNaNArray(size(xPC.X,1),xPC.li,nReps);
            iPC = utils.initNaNArray(1,k,nReps);

         end
         
         % Do PCA on random subsets
         for iRep = 1:nReps
            iPC(1,:,iRep) = randi(nTotal,[1,k,1]);
            x = xPC.X(:,iPC(1,:,iRep));
            [~,v(:,:,iRep)] = pca(x,'Economy',false,'NumComponents',xPC.li);
         end

         warning('on','stats:pca:ColRankDefX');
      end
      
      % Compute frequency content of top PCs
      function [pxx,ff] = doPCfreqEstimate(xPC,f)
         if nargin < 2
            if which('defaults.xPCA')
               f = defaults.xPCA('f');
            else
               warning('No defaults.xPCA file found. Using hard-coded frequency values.');
               f = linspace(0,4,2^14);
            end
         end
         
         if numel(xPC) > 1
            pxx = cell(numel(xPC),1);
            ff = cell(numel(xPC),1);
            for i = 1:numel(xPC)
               [pxx{i},ff{i}] = doPCfreqEstimate(xPC(i),f);
            end
            return;
         end
         
         [pxx,ff] = utils.initEmpty;
         if ~xPC.InitSuccessful
            return;
         end
         
         fs = 1/(mode(diff(xPC.t))*1e-3);
         [pxx,ff] = periodogram(xPC.V,hamming(size(xPC.X,1)),f,fs);
         if ~isa(xPC.pxx,'struct')
            xPC.pxx = struct;
            xPC.ff = struct;
         end
         
         xPC.pxx.pca = pxx;
         xPC.ff.pca = ff;
         xPC.pxx.PCmax = nan(1,size(pxx,2));
         xPC.ff.PCmax = nan(1,size(pxx,2));
         for i = 1:size(pxx,2)
            [pk,pkloc] = max(pxx(:,i));
            xPC.pxx.PCmax(i) = pk;
            xPC.ff.PCmax(i) = ff(pkloc);
         end
      end
      
      % Compute frequency content of rates
      function [pxx,ff] = doRatefreqEstimate(xPC,f)  
         if nargin < 2
            if which('defaults.xPCA')
               f = defaults.xPCA('f');
            else
               warning('No defaults.xPCA file found. Using hard-coded frequency values.');
               f = linspace(0,4,2^14);
            end
         end
         
         if numel(xPC) > 1
            pxx = cell(numel(xPC),1);
            ff = cell(numel(xPC),1);
            for i = 1:numel(xPC)
               [pxx{i},ff{i}] = doRatefreqEstimate(xPC(i),f);
            end
            return;
         end
         
         [pxx,ff] = utils.initEmpty;
         if ~xPC.InitSuccessful
            return;
         end
         
         fs = 1/(mode(diff(xPC.t))*1e-3);
         [pxx,ff] = periodogram(xPC.X,...
            hamming(size(xPC.X,1)),...
            f,...
            fs);
         
         if ~isa(xPC.pxx,'struct')
            xPC.pxx = struct;
            xPC.ff = struct;
         end
         
         xPC.pxx.rate = pxx;
         xPC.ff.rate = ff;
         
         xPC.pxx.ratemax = nan(1,size(pxx,2));
         xPC.ff.ratemax = nan(1,size(pxx,2));
         for i = 1:size(pxx,2)
            [pk,pkloc] = max(pxx(:,i));
            xPC.pxx.ratemax(i) = pk;
            xPC.ff.ratemax(i) = ff(pkloc);
         end
      end
   end
   
   % "GET" and "SET" methods
   methods (Access = public)
      % Return matched areas for all (masked) channels
      function A = getChannelAreas(xPC,useMask)
         if nargin < 2
            useMask = true;
         end
         if which('defaults.xPCA')
            xPC.a = defaults.xPCA('areas');
         else
            xPC.a = categorical({'CFA','RFA'});
         end
         xPC.a_idx = contains({xPC.ChannelInfo.area},'RFA')+1;
         A = xPC.a(xPC.a_idx);
         if useMask
            A = A(xPC.mask);
         end
      end
      
      % Return matched group for all (masked) channels
      function G = getChannelGroups(xPC,useMask)
         if nargin < 2
            useMask = true;
         end
         
         if which('defaults.xPCA')
            xPC.g = defaults.xPCA('groups');
         else
            xPC.g = categorical({'Intact','Ischemia'});
         end

         xPC.g_idx = contains({xPC.ChannelInfo.Group}, 'Ischemia')+1; 
         G = xPC.g(xPC.g_idx);
         if useMask
            G = G(xPC.mask);
         end
      end
      
      % Return coherence data for child objects
      function [cxy,ff,iPC_m,iPC_b] = getChildCoherenceData(xPC,nReps,nRemove)
         if nargin < 3
            nRemove = defaults.xPCA('n_remove');
         end
         
         if nargin < 2
            nReps = defaults.xPCA('n_reps');
         end
         
         % Handle array input
         if numel(xPC) > 1
            [cxy,ff,iPC_m,iPC_b] = utils.initCellArray(size(xPC));            
            for i = 1:numel(xPC)
               [cxy{i},ff{i},iPC_m{i},iPC_b{i}] = getChildCoherenceData(xPC(i),nReps,nRemove);
            end
            return;
         end
         % Initialize output args
         iPC_b = utils.initCellArray(numel(xPC.Children),1);
         if xPC.InitSuccessful
            [cxy,ff,iPC_m] = utils.initNaNArray(numel(xPC.Children),xPC.li,max(nReps,1));
         else
            [cxy,ff,iPC_m] = utils.initEmpty;
            return;
         end
         
         [flag,i] = hasChildxPCobj(xPC);
         if ~flag
            return;
         end
         [cxy(i,:,:),ff(i,:,:),iPC_m(i,:,:),iPC_b(i)] = getParentPCcohere(xPC.Children(i),xPC.li,nReps,nRemove);
      end
      
      % Returns matched coefficients based on channel info
      function pcStruct = getMatchedCoeffs(xPC,chanInfo)
         
         name = {xPC.ChannelInfo.Name}.';
         probe = vertcat(xPC.ChannelInfo.probe);
         channel = vertcat(xPC.ChannelInfo.channel);
         
         if isfield(chanInfo,'Name')
            chname = {chanInfo.Name}.';
         else
            chname = {chanInfo.file}.';
            chname = cellfun(@(x){x(1:5)},chname,'UniformOutput',true);
            chname = reshape(chname,numel(chname),1);
         end
         chprobe = vertcat(chanInfo.probe);
         chchannel = vertcat(chanInfo.channel);
         
         pcStruct = struct('name','Block',...
            'score',zeros(numel(xPC.t), numel(chname)),...
            'coeff',xPC.coeff(:,1:xPC.li),...
            't',[],...
            'mu',zeros(1,numel(chname)));
         
         allIdx = nan(1,numel(chname));
         for i = 1:numel(chname)
            allIdx(i) = find(ismember(name,chname{i}) & ...
               (probe == chprobe(i)) & ...
               (channel == chchannel(i)),1,'first');
         end
         
         for i = 1:numel(chname)
            colIdx = allIdx(i);
            pcStruct.mu(i) = xPC.mu(colIdx);
            pcStruct.score(:,i) = xPC.score(:,colIdx);
            pcStruct.coeff(:,i) = xPC.coeff(allIdx,colIdx);
         end
         pcStruct.t = xPC.t;
      end
      
      % Returns the indexing with reference to ChannelInfo of this xPCobj
      % to match some external ChannelInfo (in), such that
      % xPCobj(idx(mask)) = in;
      function [idx,mask] = getMatchedIndex(xPC,in)
         if isa(in,'block') || isa(in,'rat') || isa(in,'group') || isa(in,'xPCobj')
            in = in.ChannelInfo;
         end
         
         if isfield(in,'Name')
            f = 'Name';
         else
            f = 'file';
         end
         
         Name = {xPC.ChannelInfo.Name}.';
         probe = [xPC.ChannelInfo.probe].';
         ch = [xPC.ChannelInfo.channel].';
         
         idx = nan(numel(xPC.ChannelInfo),1);
         mask = false(size(idx));
         
         for i = 1:numel(in)
            iIdx = find(contains(Name,in(i).(f)) & ...
               probe == in(i).probe & ...
               ch == in(i).channel,1,'first');
            if ~isempty(iIdx)
               mask(iIdx) = true;
               idx(iIdx) = i;
            end
         end
      end
      
      % Return coherence to (matched) parent PCs. 
      % iPC_m : Matched parent PC index
      % iPC_b : Child index for rate channel during bootstrapping
      function [cxy,ff,iPC_m,iPC_b] = getParentPCcohere(xPC,nPC,nReps,nRemove)
         if nargin < 4
            nRemove = defaults.xPCA('n_remove');
         end
         
         if nargin < 3
            nReps = defaults.xPCA('n_reps');
         end
         
         if nargin < 2
            nPC = xPC(1).Parent.li;
         end
         
         if numel(xPC) > 1
            [cxy,ff,iPC_m] = utils.initNaNArray(numel(xPC),nPC,max(nReps,1));
            iPC_b = utils.initCellArray(numel(xPC),1);
            for i = 1:numel(xPC)
               [cxy(i,:,:),ff(i,:,:),iPC_m(i,:,:),iPC_b{i}] = getParentPCcohere(xPC(i),nPC,nReps,nRemove);
            end
            return;
         end
         
         if nReps == 0
            nRemove = 0;
         end
         
         [cxy,ff,iPC_m] = utils.initNaNArray(1,nPC,max(nReps,1));
         iPC_b = utils.initNaNArray(1,size(xPC.X,2)-nRemove,max(nReps,1));
         if ~xPC.hasParentxPCobj
            return;
         end
         
         fs = xPC.fs;
         f = xPC.Parent.ff.PCmax(1:nPC); % 1 for each frequency
%          X = xPC.V;
         [X,iPC_b] = xPC.doPCAbootstrap(nReps,nRemove);
         Y = xPC.Parent.V(:,1:nPC);
         [cxy,ff,iPC_m] = xPCobj.cohXY(X,Y,fs,f,nPC);
      end
      
      % Retrieve subset of coefficients (for reconstruction, etc.)
      function pcStruct = getTopPCs(xPC)
         pcStruct = struct('name','Top',...
            'score',[],...
            'coeff',[],...
            'mu',[]);
         pcStruct.score = xPC.score(:,1:xPC.li);
         pcStruct.coeff = xPC.coeff(:,1:xPC.li);
         pcStruct.mu = xPC.mu;
         
      end
      
      % Sets or adds Children to this xPCobj. If setMode argument is not
      % specified, defaults to overwriting current Children array.
      % Otherwise, setMode can be set to 'Add' to concatenate current array
      % with new Children.
      function setChildObj(xPC,c,setMode)
         if nargin < 3
            setMode = 'Overwrite';
         end
         
         switch lower(setMode)
            case 'overwrite'
               xPC.Children = c;
            case 'add'
               xPC.Children = vertcat(xPC.Children,c);
            otherwise
               error('No setMode option for ''%s''',lower(setMode));
         end
               
      end
      
      % Get the index of PC corresponding to a threshold proportion of
      % variance explained
      function setLatentIndex(xPC,thresh) %#ok<*INUSD>
         if nargin < 2
            if which('defaults.xPCA')
               thresh = defaults.xPCA('latent_threshold');
            else
               thresh = 0.95;
            end
         end
         
         xPC.latent_dims = cumsum(xPC.latent)./sum(xPC.latent);
%          xPC.li = sum(xPC.latent_dims <= thresh);
%          xPC.latent_threshold = thresh;
         xPC.li = min(4,numel(xPC.latent_dims));
         xPC.latent_threshold = xPC.latent_dims(xPC.li);
      end
      
      % Sets the Parent object of this xPCobj (must be another xPCobj)
      function setParent(xPC,p)
         if nargin < 2
            error('Must specify Parent input argument (p)');
         end
         
         % Handle arrays
         if numel(xPC) > 1
            for i = 1:numel(xPC)
               setParent(xPC(i),p);
            end
            return;
         end
         
         if ~isa(p,'xPCobj')
            error('Input for Parent is class %s. It must be class xPCobj.',...
               class(p));
         end
         xPC.Parent = p;
      end
   end
   
   % "GRAPHICS" methods
   methods (Access = public)
      % Bar graph with the top PCs colored and rest black
      function fig = barVarCapt(xPC)
         fig = figure('Name','PCA Summary',...
            'Units','Normalized',...
            'Position',[0.25 0.25 0.4 0.4],...
            'Color','w');
         subplot(2,1,1);
         coloredBars = 1:xPC.li;
         bar(coloredBars,xPC.latent_dims(coloredBars)*100,'FaceColor','y');
         hold on;
         shadedBars = (xPC.li+1):numel(xPC.latent_dims);
         bar(shadedBars,xPC.latent_dims(shadedBars)*100,'FaceColor','k');
         xlabel('Dim #','FontName','Arial','Color','k');
         ylabel('% Var Explained','FontName','Arial','Color','k');
         xlim([0 min(numel(xPC.latent_dims),20)]);
         
         subplot(2,1,2);
         plot(xPC.t,xPC.score(:,coloredBars),'LineWidth',1.5);
         legText = [];
         for i = 1:numel(coloredBars)
            legText = [legText; {sprintf('PC-%g',i)}];
         end
         legend(legText);
         ylim([-3 3]);
         xlim([-1000 750]);
         
         N = round(nanmean(xPC.NTrial));
         if iscell(xPC.Area)
            str = sprintf('All Channels: PO-%g to PO-%g (N_{avg} = %g)',...
               xPC.StartDay,xPC.StopDay,N);
         else
            str = sprintf('%s: PO-%g to PO-%g (N_{avg} = %g)',...
               xPC.Area,xPC.StartDay,xPC.StopDay,N);
         end
         txt = suptitle(str);
         set(txt,...
            'FontName','Arial',...
            'FontSize',18,...
            'Color','k');
         
      end
      
      % Checks the captured variance (BARVARCAPT) and top PCs
      % (PLOTPCVECTORS) and returns an array of figures to both.
      function fig = checkCrossDayMeanPCs(xPC)
         
         fig1 = xPC.barVarCapt;
         fig2 = xPC.scatterPCpairs;
         
         fig = [fig1; fig2];
      end
      
      % Plot of the top PCs in pairwise scatter plots
      function fig = scatterPCpairs(xPC)
         fig = figure(...
            'Name','Coefficient Weightings by Area*Group',...
            'Units','Normalized',...
            'Position',[0.45 0.45 0.4 0.4],...
            'Color','w');
         
         plotGroupedScatter(xPC,1:sum(xPC.mask));
         
         fig = [fig; figure(...
            'Name','Coefficient Weightings by Area: Group(Ischemia)',...
            'Units','Normalized',...
            'Position',[0.45 0.45 0.4 0.4],...
            'Color','w')];
         
         plotGroupedScatter(xPC,find(xPC.group=='Ischemia'));
         
         fig = [fig; figure(...
            'Name','Coefficient Weightings by Area: Group(Intact)',...
            'Units','Normalized',...
            'Position',[0.45 0.45 0.4 0.4],...
            'Color','w')];
         
         plotGroupedScatter(xPC,find(xPC.group=='Intact'));
      end
      
   end
   
   % "HAS" methods (check if a certain property is set or initialized)
   methods (Access = private)
      % Return TRUE if object has been initialized with data
      function flag = hasData(xPC)
         % Handle array inputs
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            for i = 1:numel(xPC)
               flag(i) = xPC(i).hasData;
            end
            return;
         end
         % Check truncated data matrix X
         flag = ~isempty(xPC.X);
      end
      
      % Return TRUE if object has Children xPC objects associated with it
      function [flag,idx] = hasChildxPCobj(xPC)
         % Handle array inputs
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            idx = utils.initCellArray(numel(xPC),1);
            for i = 1:numel(xPC)
               [flag(i),idx{i}] = xPC(i).hasChildxPCobj;
            end
            return;
         end
         
         % Check Children for xPCobj class objects, specifically
         if ~isempty(xPC.Children)
            idx = find(hasSuccessfulInit(xPC.Children));
         else
            idx = [];
         end
         flag = ~isempty(idx);
      end
      
      % Return TRUE if object has had 'freqType' frequency estimation
      % performed. Default second argument is 'PC'; can be 'PC' or 'Rate'.
      function flag = hasFreqData(xPC,freqType)
         % Parse input
         if nargin < 2
            freqType = 'PC';
         end
         
         % Handle array inputs
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            for i = 1:numel(xPC)
               flag(i) = xPC(i).hasFreqData(freqType);
            end
            return;
         end
         
         switch lower(freqType)
            case {'pc','pca'}
               if ~isempty(xPC.pxx)
                  flag = ~isempty(xPC.pxx.pca);
               else
                  flag = false;
               end
            case {'rate','spikerate','ifr','spikes','firingrate','fr'}
               if ~isempty(xPC.pxx)
                  flag = ~isempty(xPC.pxx.rate);
               else
                  flag = false;
               end
            otherwise
               error('No (lowercase) match for freqType = ''%s''\n',freqType);
         end
      end
      
      % Return TRUE if object has Parent xPCobj
      function flag = hasParentxPCobj(xPC)
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            for i = 1:numel(xPC)
               flag(i) = xPC(i).hasParentxPCobj;
            end
         end
         if ~isempty(xPC.Parent)
            flag = isa(xPC.Parent,'xPCobj');
         else
            flag = false;
         end
      end
      
      % Return TRUE if object has been initialized with principal comps
      function flag = hasPCs(xPC)
         % Handle array inputs
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            for i = 1:numel(xPC)
               flag(i) = xPC(i).hasPCs;
            end
            return;
         end
         % Check principal component vectors array
         flag = ~isempty(xPC.V);
      end
      
      % Return TRUE if object was successfully initialized in general
      function flag = hasSuccessfulInit(xPC)
         if numel(xPC) > 1
            flag = utils.initFalseArray(numel(xPC),1);
            for i = 1:numel(xPC)
               flag(i) = hasSuccessfulInit(xPC(i));
            end
            return;
         end
         flag = xPC.InitSuccessful;
      end
   end
   
   % Private methods called by other methods (e.g. initialization, etc)
   methods (Access = private)          
      % Object initializer
      function [x,t] = initDataStruct(xPC,X,T,channelInfo)

         xPC.orig.X = X; % Save copy of original data
         xPC.orig.t = T;
         xPC.ChannelInfo = channelInfo;
         
         if which('defaults.xPCA')
            tLim = [defaults.xPCA('t_start'), defaults.xPCA('t_stop')];
         else
            tLim = [-1000 750];
         end
         t_idx = (T >= tLim(1)) & (T <= tLim(2));
         x = X(t_idx,:);
         t = T(t_idx);
         
         xPC.mask = true(size(X,2),1);
         
         xPC.area = xPC.getChannelAreas;
         xPC.group = xPC.getChannelGroups;

      end
      
      % Helper for plotting grouped scatters
      function ax = plotGroupedScatter(xPC,idx)
         A = xPC.getChannelAreas.';
         G = xPC.getChannelGroups.';
         A = A(idx);
         G = G(idx);
         str = [];
         for i = 1:xPC.li
            str = [str, {sprintf('PC-%g',i)}];
         end
%          [~,ax,~] = gplotmatrix(xPC.coeff(idx,1:xPC.li),...
%             xPC.coeff(idx,1:xPC.li),A.*G,...
%             'rrbb','.o.o',[],'on',...
%             'hist',str,str);

         [~,ax,~] = gplotmatrix(xPC.coeff(idx,1:xPC.li),...
            xPC.coeff(idx,1:xPC.li),A.*G,...
            [],[],[],'on',...
            'hist',str,str);
         
         
         for i = 1:size(ax,2)
            set(ax(size(ax,1),i),'XTick',[-0.2 0 0.2]);
            set(ax(size(ax,1),i),'XTickLabel',[-0.2 0 0.2]);
         end
         
         for i = 1:size(ax,1)
            set(ax(i,1),'YTick',[-0.2 0 0.2]);
            set(ax(i,1),'YTickLabel',[-0.2 0 0.2]);
         end
         
         for i = 1:numel(ax)
            set(ax(i),'XLim',[-0.4 0.4]);
            set(ax(i),'YLim',[-0.4 0.4]);
         end
      end
      
   end
   
   % Static method for retrieving appropriate rates used in constructor
   methods (Static = true)
      % Method to return coherence for each matched column vector between
      % two arrays, for specific input frequencies
      % X should be a tensor, where each set of resampled PCs should be
      % concatenated along dim3. 
      function [cxy,ff,iY] = cohXY(X,Y,fs,f,nPC,iY_in)         
         if nargin < 5
            error('All 5 input arguments are required.');
         end
         
         if nPC > 1
            [cxy,ff,iY] = utils.initNaNArray(1,nPC,size(X,3));
            iY_vec = 1:nPC;
            for i = 1:nPC
%                [cxy(1,i,:),ff(1,i,:),iY(1,i,:)] = ...
%                    xPCobj.cohXY(X(:,i,:),Y,fs,f,1); % choose "best" PC
               [cxy(1,i,:),ff(1,i,:),iY(1,i,:)] = ...
                  xPCobj.cohXY(X(:,i,:),Y,fs,f,1,i); % match PCs 1:1
            end
            return;
         end
         [cxy,ff,iY] = utils.initNaNArray(1,1,size(X,3));
         
         if nargin > 5
            Y = Y(:,iY_in);
         end
         
         for i = 1:size(X,3)
            [cxytmp,ftmp] = mscohere(squeeze(X(:,1,i)),Y,[],[],f,fs);
            if nargin < 6
               [cxytmp,fi] = max(cxytmp,[],2); % Reduces to size(Y,2) x 1 x size(X,3)
               ftmp = ftmp(fi);
               [cxy(1,1,i),iY(1,1,i)] = max(cxytmp,[],1); % Reduces to size 1 x 1 x size(X,3)
            else
               iY(1,1,i) = iY_in;
               cxy(1,1,i) = cxytmp(iY_in);
            end
            ff(1,1,i) = ftmp(iY(1,1,i));
         end
         

         
      end
      
      % Method to debug errors
      function dbprint(varargin)
         fprintf(1,'\nDebugging %s variables:\n',nargin);
         for i = 1:nargin
            fprintf(1,'\t\t-->%s: [%g x %g]\n',...
               inputname(i),...
               size(varargin{i},1),...
               size(varargin{i},2));
         end
         fprintf(1,'\n\t\t\t---\t\t\t\n');
      end
      
      % Get rates - can exclude by AREA as well
      function [X,channelInfo,t,nTrial,Score] = getAllRate(g,align,includeStruct,area,startDay,stopDay,icms)
         if nargin < 7
            icms = {'PF','DF','O','NR','PF-DF'};
         end
         
         if nargin < 6
            stopDay = 100;
         end
         
         if nargin < 5
            startDay = 1;
         end
         
         if nargin < 4
            area = {'RFA','CFA'}; % Gets both by default
         end
         
         if nargin < 3
            includeStruct = defaults.group('include');
         end
         
         if nargin < 2
            align = defaults.group('align');
         end
         
         if numel(g) > 1
            [X,channelInfo,nTrial,Score] = utils.initEmpty;            
            tFlag = true;
            for i = 1:numel(g)
               [tmpRate,tmpChannelInfo,ttmp,tmpNTrial,tmpScore] = xPCobj.getAllRate(g(i),align,includeStruct,area,startDay,stopDay,icms);
               X = [X, tmpRate];
               channelInfo = [channelInfo; tmpChannelInfo];
               Score = [Score; tmpScore];
               nTrial = [nTrial, tmpNTrial];
               if ~isempty(ttmp) && tFlag
                  t = ttmp;
                  tFlag = false;
               end
            end
            if tFlag
               t = [];
            end
            return;
         end
         if isa(g,'group')
            [rate,t,n] = getMeanRateByDay(g.Children,align,includeStruct,startDay,stopDay); %#ok<*PROPLC>
         else
            [rate,t,n] = getMeanRateByDay(g,align,includeStruct,startDay,stopDay);
            if numel(g) == 1
               rate = {rate};
            end
         end
         X = [];
         keepIdx = true(size(g.Children));
         nTrial = [];
         for i = 1:numel(rate)
            if ~isempty(rate{i})
               X = [X, rate{i}]; %#ok<*AGROW>
               nTrial = [nTrial, ones(1,size(rate{i},2))*n(i)];
            else
               keepIdx(i) = false;
            end
         end
         
         if isempty(X)
            channelInfo = [];
            Score = [];
            return;
         end
         
         if isa(g,'group')
            gc = copy(g);
            gc.Children = gc.Children(keepIdx);
            channelInfo = getChannelInfo(gc,false);
            Score = getBlockNumProp(gc,'TrueScore',true);
         else
            channelInfo = getChannelInfo(g,false);
            Group = g.Parent.Name;
            channelInfo = utils.addStructField(channelInfo,Group);
            channelInfo = orderfields(channelInfo,[7,1:6]);
            Score = getBlockNumProp(g,'TrueScore',true);
         end
         
         idx = contains({channelInfo.area}.',area) & ...
            ismember({channelInfo.icms}.',icms);
         channelInfo = channelInfo(idx);
         Score = Score(idx);
         
            
         X = X(:,idx);
      end
   end
   
end
   
