classdef pcFit < handle
   %PCFIT   This creates a handle object that fits spike rate to top PCs.
   %
   %        For a given BLOCK class object, PC dims are specified using the
   %        XPCOBJ class, which stands for "cross-days" PCA and in general
   %        aggregates all channels into one array and finds the top
   %        behaviorally-aligned dimensions (for some alignment and
   %        inclusion/exclusion criteria) principal components of the
   %        average spike rate during that behavior.
   
   properties (GetAccess = public, SetAccess = private)
      A  % Struct, matrices of **recovered coefficients** (main OUTPUT)
      
      B  % Matrix of PC means, from XPCOBJ, for channels from this BLOCK
      X  % Average condition-aligned spike rate for this BLOCK (recording)
      Y  % Struct, PCs (from XPCOBJ) obtained from ALL channels (all rats)
      t     % Times associated with each row of X
      mse   % Struct with mean-square error for "full" and "top"
      dim   % Struct with scalars for each associated dimension
   end
   
   properties (Access = private)
      chIdx % Channel indices for X into BLOCKOBJ channels
   end
   
   properties (Access = public, Hidden = true)
      xPC         % Associated XPCOBJ handle class object
      blockObj    % Associated BLOCK handle class object
      optim_opts  % Options for the fmincon optimizer
      Ao          % Initial guess for A
   end
   
   % Main public methods including the class constructor and FIT method,
   % which is the primary function of this class.
   methods (Access = public)
      % PCFIT handle class object constructor
      function obj = pcFit(xPC,blockObj)
         % Add parsing to allow easy creation of a PCFIT array
         if isnumeric(xPC) && isscalar(xPC)
            obj = repmat(obj,xPC,1);
            return;
         % Add parsing for if input is gData or ratObj
         elseif isa(blockObj,'group')
            obj = pcFit(xPC,vertcat(blockObj.Children));
            return;
         elseif isa(blockObj,'rat')
            obj = pcFit(xPC,vertcat(blockObj.Children));
            return;
         end
         
         % Add handling for if blockObj is an array
         if numel(blockObj) > 1
            obj = pcFit(numel(blockObj));
            for ii = 1:numel(blockObj)
               obj(ii) = pcFit(xPC,blockObj(ii));
            end
            return;
         end
         
         % Initialize properties of this PCFIT object
         if obj.initProps(xPC,blockObj)
            fprintf(1,'No PC-FIT for %s\n',blockObj.Name);
            return;
         end
         
         % Fit the top nChannels PCs
         obj.fit('full');
         
         % Fit the top 3-6 PCs (depends on % explained threshold)
         obj.fit('top');
      end
      
      % FIT Does the bulk of the work for this class. Fits the top PC dims
      % estimated from the cross-day behaviorally aligned spike rates from
      % each channel on all animals in the study. Basically the idea is to
      % look for "trends" from the aggregate dataset that are fit by a
      % linear combination of the channels in this recording, and then see
      % how the ability to fit that particular ubiquitous feature changes
      % over the course of all the recordings.
      function fit(obj,type)
         if nargin < 2
            type = 'full';
         else
            type = lower(type);
            if ~ismember(type,{'full','top'})
               error('type must be: ''full'' or ''top''');
            end
         end
         % Set variables to be passed for optimization function
         Zi = obj.X - obj.B; % Zi = Xi - Bi
         Y = obj.Y.(type);
         Ao = obj.Ao.(type)'; % Fit the transpose
         
         w = var(Zi,[],1);
%          w = ones(1,size(Zi,2));
         co = sum((Zi - Y*(Ao)).^2,1); % Initial (and subsequent) cost
         
%          % Linear constraints on magnitude of A
%          Acon = ones(2,size(Ao,1)*size(Ao,2));
%          Acon(2,:) = Acon(2,:) * -1;
%          % Used for : Acon,[size(Zi,2);-1],... % Acon*x <= [1,-1]
         
         % Define function for passing extra parameters
         Aprev = randn(size(Ao)); % for estimating gradient
         f = @(A)pcFit.func_to_min(A,Zi,Y,w,co,Aprev);
         
         % Define nonlinear-constraint function
         nc = @(A)pcFit.nonlinear_constraint_func(A,Ao);
         
         % Run unconstrained optimization
         fprintf(1,'Running %s PC-FIT for %s...',type,obj.blockObj.Name);
         obj.A.(type) = fmincon(f,Ao,...
            [],[],... % No A*x <= b constraint
            [],[],... % No Aeq*x = beq constraint
            [],[],... % No lb,ub constraints
            nc,...
            obj.optim_opts)';
         fprintf(1,'complete\n');
         
         % Retrieve mse for this type
         if isempty(obj.mse)
            obj.mse = struct;
         end
         
         obj.mse.(type) = mean((Zi - Y*(obj.A.(type)')).^2,1);
         obj.blockObj.setProp('pcFit',obj);
      end
   end
   
   % Methods for plotting/viewing data
   methods (Access = public)
      function fig = viewChannelFit(obj)
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; viewChannelFit(obj(ii))];  %#ok<*AGROW>
            end
            return;
         end
         
         fig = figure(...
            'Name',sprintf('%s - Channelwise PC-Fit',obj.blockObj.Name),...
            'Units','Normalized',...
            'Color','w',...
            'Position',[0.2 0.2 0.3 0.5]);
         
         if isempty(obj.mse)
            return;
         end
         
         subplot(2,1,1);
         set(gca,'NextPlot','add');
         for ii = 1:numel(obj.mse.full)
            y = (1 - obj.mse.full(ii)) * 100;
            if y > defaults.pcFit('threshold_explained')
               bar(ii,y,1,'FaceColor','b','EdgeColor','none');
            else
               bar(ii,y,1,'FaceColor','r','EdgeColor','none');
            end
         end
         xlabel('Channel');
         ylabel('% Explained');
         title('Full PCs');
         
         subplot(2,1,2);
         set(gca,'NextPlot','add');
         for ii = 1:numel(obj.mse.top)
            y = (1 - obj.mse.top(ii)) * 100;
            if y > defaults.pcFit('threshold_explained')
               bar(ii,y,1,'FaceColor','b','EdgeColor','none');
            else
               bar(ii,y,1,'FaceColor','r','EdgeColor','none');
            end
         end
         xlabel('Channel');
         ylabel('% Explained');
         title(sprintf('Top %g PCs',obj.xPC.li));
      end
      
      function fig = viewFitCoeffs(obj)
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; viewFitCoeffs(obj(ii))];  %#ok<*AGROW>
            end
            return;
         end
         
         fig = figure(...
            'Name',sprintf('%s - PC-Fit Coeffs',obj.blockObj.Name),...
            'Units','Normalized',...
            'Color','w',...
            'Position',[0.2 0.2 0.3 0.5]);
         
         if isempty(obj.mse)
            return;
         end
         
         area = obj.xPC.getChannelAreas;
         area = area(obj.chIdx);
         
         e = (1 - obj.mse.top) * 100;
         rm_idx = e < defaults.pcFit('threshold_explained');
         
         area(rm_idx) = [];
         if isempty(area)
            fprintf(1,'No channels meet threshold criteria for %s\n',obj.blockObj.Name);
            return;
         end
         
         str = cell(obj.xPC.li,1);
         for i = 1:obj.xPC.li
            str{i} = sprintf('PC-%g',i); 
         end
         if area(1) == 'CFA'
            areaCol = 'rb';
            areaSz = [10 5];
         else
            areaCol = 'br';
            areaSz = [5 10];
         end
         gplotmatrix(obj.A.top(~rm_idx,:),...
            obj.A.top(~rm_idx,:),area,...
            areaCol,'..',areaSz,'on',...
            'hist',str,str);
      end
   end
   
   % Get/Set methods
   methods (Access = public)
      function [A,mse,poday] = getChannelCoeffs(obj)
         if isempty(obj.mse)
            A = [];
            mse = [];
            poday = [];
            return;
         end
         ci = obj.blockObj.Parent.ChannelInfo;
         A = nan(numel(ci),obj.xPC.li);
         idx = obj.blockObj.getChannelInfoChannel(ci);
         A(idx,:) = obj.A.top;
         mse = nan(numel(ci),1);
         mse(idx) = obj.mse.top;
         poday = obj.blockObj.PostOpDay;
      end
   end
   
   % Private methods for data handling/initialization
   methods (Access = private)
      % Returns TRUE if something bad happened
      function flag = initProps(obj,xPC,blockObj)
         flag = true;
         % Associate XPC object handle with this object
         obj.xPC = xPC;
         
          % Associate individual BLOCK handle
         obj.blockObj = blockObj;
         [rate,t] = obj.blockObj.getMeanRate(xPC.align,xPC.includeStruct); %#ok<*PROPLC>
         if isempty(rate)
            return;
         end
         t_start = defaults.xPCA('t_start');
         t_stop = defaults.xPCA('t_stop');
         t_idx = (t >= t_start) & (t <= t_stop);
         
         % Initialize previously-observed empirical properties
         obj.t = t(t_idx);
         obj.X = rate(t_idx,:);  
         obj.dim = struct;
         obj.dim.Ch = size(rate,2);
         obj.dim.T = size(rate,1);
         obj.dim.PC = obj.xPC.li;
         
         % The constant term is specific to CHANNELS used
         obj.chIdx = obj.blockObj.getChannelInfoChannel(obj.xPC.ChannelInfo,true);
         obj.B = obj.xPC.mu(obj.chIdx); 
         
         % The "SCORE" to fit is the SAME for all PCFIT objects, which
         % presumably are given the same XPCOBJ (which aggregates the
         % cross-day average rates for a given alignment from all channels
         % in the GROUP array).
         obj.Y = struct;
         obj.Y.full = obj.xPC.score(:,1:obj.dim.Ch);
         obj.Y.top = obj.xPC.score(:,1:obj.xPC.li);
         
         % Initialize properties to be estimated
         obj.A = struct;
         obj.A.full = nan(obj.dim.Ch,obj.dim.Ch);
         obj.A.top = nan(obj.dim.Ch,obj.dim.PC);
         
         obj.Ao = struct;
         obj.Ao.full = obj.xPC.coeff(obj.chIdx,1:obj.dim.Ch);
         obj.Ao.top = obj.xPC.coeff(obj.chIdx,1:obj.dim.PC);
         
         % Initialize optimizer for linear fit procedure
         if which('defaults.pcFit')
            obj.optim_opts = defaults.pcFit('optim_opts');
         else
            fprintf(1,'Could not find +defaults/pcFit.m\n');
            fprintf(1,'-->\tUsing fmincon default optimizer options.\n');
            obj.optim_opts = optimoptions('fmincon');
         end
         flag = false;
         
      end
   end
   
   % Static function to use in optimization procedure for finding best fit.
   methods (Static = true)
      % Minimize c to solve for coefficients in A, with known X, B, and Y
      function [c,g] = func_to_min(Ai,Zi,Y,w,co,Aprev)
         %% --- To fit ---
         % (Xi-Bi)*(Ai^-1) = Y 
         % --> 
         % Zi*(Ai^-1) = Y
         % -->
         % Zi = Y * Ai 
         %% -- Fixed Parameters --
         % Xi: nTimesteps x nChannels (observed average rates)
         % Bi: 1 x nChannels (from XPCOBJ handle, incorporated into Xi)
         % --> Zi : nTimesteps x nChannels (de-meaned channel averages)
         % Y: nTimesteps x nDims (top PCs TO FIT; same for each Xi;
         %                          estimated from X, the full channel
         %                          matrix with each Xi a subset)
         %% -- Matrix to Recover --
         % Ai: nDims x nChannels (initialized using Matlab RANDN)
         %
         % Where nDims is either nTopPCs (if "top") or nChannels (if
         % "full")
         %
         % To be clear, Ai is is the transpose of the
         % PC coefficient estimates returned from Matlab PCA function.
         %% Estimate COST based on distance
         Zrecon = Y * Ai;
         sse = sum((Zi - Zrecon).^2);
         c = sum(sse .* w);
         
         dA = Ai - Aprev;
         g = (c - co) ./ dA;
         
         Aprev = Ai;
         co = c;
         
      end
      
      function [c,ceq] = nonlinear_constraint_func(A,Ao)
         c = [];
         ceq = sum(A.^2,2) - sum(Ao.^2,2);
      end
      
   end
   
end

