function [xPC,xPC_i] = xPCA(obj,align,includeStruct,area)
%% XPCA  "Cross" PCA
%  
%  obj must be a GROUP class object array, where obj(1) Name is 'Ischemia'
%  and obj(2) Name is 'Intact' (and the child rat objects should correspond
%  to those groups).

%% CHECK INPUTS
if nargin < 2
   align = defaults.block('alignment');
end

if nargin < 3
   includeStruct = utils.makeIncludeStruct({'Grasp','Reach','Outcome'});
end

if nargin < 4
   area = 'Full';
end

if numel(obj) < 2
   error('See group.XPCA description: need array of GROUP objects.')
end

%% HANDLE ARRAY INPUTS
if iscell(align) && (numel(align) > 1)
   for ii = 1:numel(align)
      xPCA(obj,align{ii},includeStruct,area);
   end
   return;
end

if iscell(includeStruct) && (numel(includeStruct) > 1)
   for ii = 1:numel(includeStruct)
      xPCA(obj,align,includeStruct{ii},area);
   end
   return;
end

if iscell(area) && (numel(area) > 1)
   for ii = 1:numel(area)
      xPCA(obj,align,includeStruct,area{ii});
   end
   return;
end

%% GET CROSS-DAY MEANS FOR INTACT GROUP
dbug = defaults.xPCA('debug');
[g,g_idx] = obj.Intact;
if isempty(g)
   error('Missing Intact GROUP object from array.');
end
xPC = initDataStruct(g,align,includeStruct,dbug);

%% GET PRINCIPAL COMPONENTS OF CROSS-DAY (CONDITION) MEANS
xPC = utils.doTrialPCA(xPC);

if dbug
   xPC = debugCrossDayMeanPCs(xPC);
else
   xPC = getLatentIndex(xPC);
end

%% REMOVE "BADLY FIT" CHANNELS
xPC = appendReconData(xPC);       % Reconstruct the data and get error
xPC = trimPoorlyFitChannels(xPC); % Remove channels w/ high error & re-fit
obj(g_idx).xPC = xPC; % Finally, assign the xPC struct to the INTACT group
if dbug
   xPC = debugCrossDayMeanPCs(xPC);
else
   xPC = getLatentIndex(xPC);
end

%% APPLY ANALYSIS TO ISCHEMIA GROUP
% Use the estimated principal components from INTACT group
[g,g_idx] = obj.Ischemia;
if isempty(g)
   error('Missing Ischemia GROUP object from array.');
end
xPC_i = initDataStruct(g,align,includeStruct,dbug);
xPC_i = copyPCparams(xPC_i,xPC);

%% ASSIGN OUTPUT
obj(g_idx).xPC = xPC_i;

%% HELPER FUNCTIONS
   % Append reconstruction data to show percentage of variance captured by
   % the number of dims decided to be used by GETLATENTINDEX
   function xPC = appendReconData(xPC)
      xPC = utils.doPCAreconstruction(xPC); % Using all PC
      xPC = utils.doPCAreconstruction(xPC,xPC.li); % Using only first li PC
   end

   % Long names = to keep them straight
   function xPC_origWithCopiedParams = copyPCparams(xPC_orig,xPC_toCopyFrom)
      % So I don't type a lot the whole time
      out = xPC_orig;
      in = xPC_toCopyFrom;
      
      out.mu_coeff = zeros(1,size(in.X,2));
      out.coeff = zeros(size(out.X,2),size(out.X,2));
      out.score = zeros(size(out.X));
      
      out.mu = zeros(1,size(out.X,2));
      out.Mdl_coeff = cell(size(in.X,2),1);
      out.Mdl_score = cell(size(out.X,2),1);
      
      for i = 1:size(in.X,2)
         out.Mdl_coeff{i} = fitrlinear(out.X,in.score(:,i),'FitBias',true);
         out.coeff(:,i) = out.Mdl_coeff{i}.Beta;
         out.mu_coeff(i) = out.Mdl_coeff{i}.Bias;
      end
      
      for i = 1:size(out.X,1)
         out.Mdl_score{i} = fitrlinear(out.coeff,out.X(i,:),'FitBias',true);
         out.score(i,:) = out.Mdl_score{i}.Beta;
         out.mu(i) = out.Mdl_score{i}.Bias;
      end
      
      out.li = in.li;
%       out.xbar = out.X * out.coeff
%       out.xbar_red = 
      out = appendReconData(out);
      

      xPC_origWithCopiedParams = out;
   end

   function xPC = getLatentIndex(xPC,thresh)
      if nargin < 2
         thresh = defaults.xPCA('latent_threshold');
      end
      
      xPC.latent_dims = cumsum(xPC.latent)./sum(xPC.latent);
      xPC.li = sum(xPC.latent_dims <= thresh);
      xPC.latent_threshold = thresh;
   end

   function xPC = initDataStruct(g,align,includeStruct,debug_plot)
      if nargin < 4
         debug_plot = false;
      end
      [rate,t] = getSetIncludeStruct(g.Children,align,includeStruct);
      X = [];
      for i = 1:numel(g.Children)
         X = [X, rate{i}]; %#ok<*AGROW>

      end
      tLim = [defaults.xPCA('t_start'), defaults.xPCA('t_stop')];
      t_idx = (t >= tLim(1)) & (t <= tLim(2));
      xPC = struct;
      xPC.X = X(t_idx,:);
      xPC.orig = xPC.X; % Save copy of original data
      xPC.t = t(t_idx);
      xPC.a = categorical({'CFA','RFA'});
      xPC.a_idx = contains({g.ChannelInfo.area},'RFA');
      xPC.mask = true(size(xPC.a_idx));
      if debug_plot
         debugCrossDayMeans(xPC);
      end
   end

   function xPC = trimPoorlyFitChannels(xPC,thresh)
      if nargin < 2
         thresh = defaults.xPCA('varcapt_threshold');
      end
      
      xPC.mask = xPC.varcapt_red > thresh;
      xPC.orig = xPC.X;
      xPC.X = xPC.X(:,xPC.mask);
      xPC.n_channels_removed = numel(xPC.mask) - sum(xPC.mask);
      xPC.varcapt_threshold = thresh;
      xPC = utils.doTrialPCA(xPC);
      xPC = getLatentIndex(xPC);
      xPC = appendReconData(xPC);
   end

%% DEBUG FUNCTIONS
   function debugCrossDayMeans(xPC)
      fprintf(1,'X is %g rows by %g columns.\n',size(xPC.X,1),size(xPC.X,2));
      dbFig1 = figure('Name','All Channels Debug Plot',...
         'Units','Normalized',...
         'Position',[0.25 0.25 0.4 0.4],...
         'Color','w'); 
      pLine = plot(xPC.t,xPC.X,'Color','r');
      set(pLine(xPC.a_idx(xPC.mask)),'Color','b');
      xlabel('Time (ms)','FontName','Arial','Color','k');
      ylabel('Rate (Normalized)');
      title('All Intact Channels (b - RFA; r - CFA)','FontName','Arial','Color','k');
      xlim([min(xPC.t),max(xPC.t)]);
      keyboard;
      if isvalid(dbFig1)
         close(dbFig1);
      end
   end

   function xPC = debugCrossDayMeanPCs(xPC)
      dbFig2 = figure('Name','PCA Summary (all Intact channels)',...
         'Units','Normalized',...
         'Position',[0.25 0.25 0.4 0.4],...
         'Color','w');  
      subplot(2,1,1); 
      xPC = getLatentIndex(xPC);
      li = xPC.li;
      latent_dims = xPC.latent_dims;
      
      bar(1:li,latent_dims(1:li)*100,'FaceColor','y');
      hold on;
      bar((li+1):numel(latent_dims),latent_dims((li+1):end)*100,'FaceColor','k');
      xlabel('Dim #','FontName','Arial','Color','k');
      ylabel('% Var Explained','FontName','Arial','Color','k');
      title('PCA Summary (All Channels)','FontName','Arial','Color','k','FontSize',18);
      subplot(2,1,2);
      plot(xPC.t,xPC.score(:,latent_dims <= 0.95),'LineWidth',1.5);
      legText = [];
      for i = 1:sum(latent_dims <= 0.95)
         legText = [legText; {sprintf('PC-%g',i)}];
      end
      legend(legText);

      dbFig3 = figure('Name','Coefficient Weightings by Area (all Intact channels)',...
         'Units','Normalized',...
         'Position',[0.45 0.45 0.4 0.4],...
         'Color','w'); 
      
      a = xPC.a(xPC.a_idx+1);
      a = a(xPC.mask);
      [~,smallAx,~] = gplotmatrix(xPC.coeff(:,1:4),xPC.coeff(:,1:4),a,...
         'rb','..',[10 5],'on',...
         'hist',{'PC-1','PC-2','PC-3','PC-4'},{'PC-1','PC-2','PC-3','PC-4'});

      for i = 1:size(smallAx,2)
         set(smallAx(size(smallAx,1),i),'XTick',[-0.2 0 0.2]);
         set(smallAx(size(smallAx,1),i),'XTickLabel',[-0.2 0 0.2]);
      end

      for i = 1:size(smallAx,1)
         set(smallAx(i,1),'YTick',[-0.2 0 0.2]);
         set(smallAx(i,1),'YTickLabel',[-0.2 0 0.2]);
      end

      for i = 1:numel(smallAx)
         set(smallAx(i),'XLim',[-0.4 0.4]);
         set(smallAx(i),'YLim',[-0.4 0.4]);
      end

      keyboard;

      if isvalid(dbFig2)
         close(dbFig2);
      end
      if isvalid(dbFig3)
         close(dbFig3);
      end
   end

end