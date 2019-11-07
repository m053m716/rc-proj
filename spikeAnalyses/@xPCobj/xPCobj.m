classdef xPCobj < handle
   % XPCOBJ  Class to store data for "cross"-PCA analyses
   %
   
   properties (Access = public)
      ChannelInfo
      X
      t
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
      Block
   end
   
   properties (GetAccess = public, SetAccess = private)
      align
      includeStruct
      area
      group
   end
   
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
   
   % Class constructor and data-handling
   methods (Access = public)
      % Class constructor
      function xPC = xPCobj(g,align,includeStruct)                 
         if nargin < 3
            if which('defaults.group')
               includeStruct = defaults.group('include');
            else
               includeStruct = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);
            end
         end
         
         if nargin < 2
            if which('defaults.group')
               align = defaults.group('align');
            else
               align = 'Grasp';
            end
         end

         xPC.align = align;
         xPC.includeStruct = includeStruct;         
         [X,channelInfo,t] = xPCobj.getAllRate(g,align,includeStruct);
         xPC.initDataStruct(X,t,channelInfo);
         xPC.doTrialPCA;
         xPC.setLatentIndex;
         xPC.doPCAreconstruction; % Does 'Full'
         pcStruct = xPC.getTopPCs;
         xPC.doPCAreconstruction(pcStruct); % Does 'Top'
         
         
      end
      
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
      function doTrialPCA(xPC)
         [xPC.coeff,xPC.score,xPC.latent,xPC.tsquared,xPC.explained,xPC.mu] = ...
            pca(xPC.X,'Economy',false);
      end
   end
   
   % Methods for getting properties, computations, or setting properties
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
      
      % Get the index of PC corresponding to a threshold proportion of
      % variance explained
      function setLatentIndex(xPC,thresh)
         if nargin < 2
            if which('defaults.xPCA')
               thresh = defaults.xPCA('latent_threshold');
            else
               thresh = 0.95;
            end
         end
         
         xPC.latent_dims = cumsum(xPC.latent)./sum(xPC.latent);
         xPC.li = sum(xPC.latent_dims <= thresh);
         xPC.latent_threshold = thresh;
      end
   end
   
   % ** Useful ** methods for graphic visualization
   methods (Access = public)
      % Bar graph with the top PCs colored and rest black
      function fig = barVarCapt(xPC)
         fig = figure('Name','PCA Summary (all Intact channels)',...
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
         title('PCA Summary (All Channels)','FontName','Arial','Color','k','FontSize',18);
         xlim([0 min(numel(xPC.latent_dims),20)]);
         
         subplot(2,1,2);
         plot(xPC.t,xPC.score(:,coloredBars),'LineWidth',1.5);
         legText = [];
         for i = 1:numel(coloredBars)
            legText = [legText; {sprintf('PC-%g',i)}];
         end
         legend(legText);
         
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
   
   % Private methods called by other methods (e.g. initialization, etc)
   methods (Access = private)      
      % Object initializer
      function initDataStruct(xPC,X,t,channelInfo)

         xPC.orig.X = X; % Save copy of original data
         xPC.orig.t = t;
         xPC.ChannelInfo = channelInfo;
         
         if which('defaults.xPCA')
            tLim = [defaults.xPCA('t_start'), defaults.xPCA('t_stop')];
         else
            tLim = [-1000 750];
         end
         t_idx = (t >= tLim(1)) & (t <= tLim(2));
         xPC.X = X(t_idx,:);
         xPC.t = t(t_idx);
         
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
      % Get rates
      function [X,channelInfo,t] = getAllRate(g,align,includeStruct)
         [rate,t] = getSetIncludeStruct(g,align,includeStruct); %#ok<*PROPLC>
         X = [];
         for i = 1:numel(rate)
            for j = 1:numel(rate{i})
               X = [X, rate{i}{j}]; %#ok<*AGROW>
            end
         end
         channelInfo = getChannelInfo(g);
      end
   end
   
end
   
