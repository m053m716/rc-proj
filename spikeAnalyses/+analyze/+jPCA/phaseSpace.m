function params = phaseSpace(Projection,Summary,varargin)
%PHASESPACE  For making publication quality rosette plots
%
% >> analyze.jPCA.phaseSpace(Projection,Summary)
% >> params = analyze.jPCA.phaseSpace(Projection,Summary,params)
% >> params = analyze.jPCA.phaseSpace(Projection,Summary,'Name',val,...)
% >> params = analyze.jPCA.phaseSpace(__,params,'Name',val,...)
%
% Inputs
%  Projection - Struct array of projections and metadata
%                 -> Returned by `analyze.jPCA.jPCA`
%  Summary    - Summary struct returned 
%                 -> Returned by `analyze.jPCA.jPCA`
%  params     - Parameters struct with the following fields:
%       .times 
%        -> These override the default times. 
%        -> If empty, the defaults are used.
%           * This is nice for movies as the scaling won't change as a 
%              function of the times you plot.
%       .plane2plot   
%        -> list of the jPC planes you want plotted.  
%        -> Default is [1].  [1,2] would also be reasonable.
%       .arrowSize        
%        -> The default is 5
%       .arrowGain        
%        -> FOR MOVIES: sets velocity dependence of arrow size 
%        -> (0 to not grow when faster).
%       .plotPlanEllipse  
%        -> Controls whether the ellipse is plotted.  The default is 'true'
%       .useAxes          
%        -> whether axes should be plotted.  Default is 'true'
%       .lineWidth        
%        -> width of the trajectories.  Default is 0.85.
%       .arrowMinVel      
%        -> minimum velocity for plotting an arrow.
%       .rankType         
%        -> default is 'eig', but you can override with 'varCapt'
%       .conds2plot       
%        -> which conditions to plot 
%        --> (scalings will still be based on conds in 'Projection')
%       .substRawPCs      
%        -> If true, use PC projections rather than jPC projections
%       .crossCondMean    
%        -> if true, plot the cross condition mean in cyan.
%       .Axes
%        -> If non-empty, sets the axes to plot on
%
% Output
%  params - Same as input `params` struct, but updated to reflect
%           parameters that were estimated from the data during
%           `analyze.jPCA.phaseSpace`
%
%  See Also:   analyze.jPCA.jPCA, analyze.jPCA.multi_jPCA

% Check input arguments
if nargin < 3
   params = defaults.jPCA('movie_params');
else
   if isstruct(varargin{1})
      params = varargin{1};
      varargin(1) = [];
   else
      params = defaults.jPCA('movie_params');
   end
end

% Parse 'Name',value pairs
fn = fieldnames(params);
for iV = 1:2:numel(varargin)
   iField = ismember(lower(fn),lower(varargin{iV}));
   if sum(iField)==1
      params.(fn{iField}) = varargin{iV+1};
   end
end

numTrials = numel(Projection);
if ~strcmp(params.trials2plot,'all')
   trials2plot = params.trials2plot;
   numTrials = numel(trials2plot);
else
   trials2plot = 1:numTrials;
end

% If asked, substitue the raw PC projections.
if params.substRawPCs 
   % total number of planes provided (may only plot a subset):
   numPlanes = length(Summary.varCaptEachPlane); 
   for c = 1:numTrials
      Projection(c).proj = Projection(c).state;
   end
   Summary.varCaptEachPlane = sum(reshape(Summary.varCaptEachPC,2,numPlanes));
end

if strcmp(params.rankType, 'varCapt')  && params.substRawPCs == 0  % we WONT reorder if they were PCs
   [~, sortIndices] = sort(Summary.varCaptEachPlane,'descend');
   planes2plot_Orig = params.plane2plot;  % keep this so we can label the plane appropriately
   planeRankings = sortIndices(planes2plot_Orig);  % get the asked for planes, but by var accounted for rather than eigenvalue
else
   planeRankings = params.plane2plot;
end

if numTrials < 5
   fprintf(1,'Only %g trials for this dataset. skipping.\n',numTrials);
   return;
end

lineColor = cell(numTrials,1);
arrowFaceColor = cell(numTrials,1);
planMarkerColor = cell(numTrials,1);
colorStruct = cell(1,numel(params.plane2plot));

if isempty(params.haxP)
   params.haxP = cell(1,numel(params.plane2plot));
end
if isempty(params.vaxP)
   params.vaxP = cell(1,numel(params.plane2plot));
end
axisParams = defaults.jPCA('axes_params');

for pindex = 1:numel(planeRankings)
   colorStruct{pindex} = struct('color',lineColor);
   % get some useful indices
   plane = planeRankings(pindex);  % which plane to plot
   d2 = 2*plane;  % indices into the dimensions
   d1 = d2-1;
   fcn = @(Proj)recover_traj_segment(Proj,d1,d2,params.times,params.useRot);
   
   % set the limits of the figure
   planData = arrayfun(@(Proj)recover_traj_state(Proj,d1,d2,1,params.useRot),...
      Projection(trials2plot)');
   planData = cell2mat(planData);
   
   % need this for ellipse plotting
   ellipseRadii = std(planData,[],1);  % we may plot an ellipse for the plan activity
   mu = nanmean(planData,1);
   R = nancov(planData);
   theta_rot = atan2(sqrt(sum(R(:,2).^2)),sqrt(sum(R(:,1).^2)));
   
   % these will be altered further below based on how far the data extends left and down
   farthestLeft = mu(1)-ellipseRadii(1)*5;  % used figure out how far the axes need to be offset
   farthestDown = mu(2)-ellipseRadii(2)*5;  % used figure out how far the axes need to be offset
   
   
   % deal with the color scheme
   
   % ** colors graded based on PLAN STATE
   % These do NOT depend on which times you choose to plot (only on which time is first in Projection.proj).
   

   if numel(unique([Projection.Condition])) > 2
      [u,~,iC] = unique([Projection.Condition]);
      htmp = redbluecmap(numel(u), 'interpolation', 'sigmoid');
      htmpIdx = fliplr(round(linspace(1,size(htmp,1),numel(u))));
      htmp = htmp(htmpIdx,:);
   else
      iC = rem([Projection.Condition],2)+1;
      htmp = [1 0 0;   % 1: Unsuccessful -- Blue
              0 0 1];  % 2: Successful   -- Red

   end

   for c = 1:numTrials  % cycle through conditions, and assign that condition's color
      lineColor{c} = htmp(iC(c),:);
      arrowFaceColor{c} = htmp(iC(c),:);
      planMarkerColor{c} = htmp(iC(c),:);
   end

   % override colors if asked
   if isfield(params,'colors')
      lineColor = params.colors;
      arrowFaceColor = params.colors;
      planMarkerColor = params.colors;
   end
   
   colorStruct{pindex} = struct(...
      'color',lineColor,...
      'arrowFaceColor',arrowFaceColor,...
      'planMarkerColor',planMarkerColor ...
      );
   
   % Generate some custom axes things
   if isempty(params.haxP{pindex}) || isempty(params.vaxP{pindex})
      if isempty(params.Figure) 
         if isempty(params.Axes)
            [params.Figure,params.Axes] = ...
               analyze.jPCA.blankFigure(...
                  params.axLim,...
                  'Units','Pixels',...
                  'Position',params.pixelSize);
         else
            params.Figure = get(params.Axes,'Parent');
         end
      end
      axisParams.curAxes = params.Axes;
      extraSeparation = ...
         params.axisSeparation*(min(farthestDown,farthestLeft));
      
      % general axis parameters
      axisParams.tickLocations = ...
         [-params.axLim(1), 0, params.axLim(2)];
      axisParams.longTicks = 0;
      axisParams.fontSize = 10.5;
      
      % horizontal axis
      axisParams.axisOffset = farthestDown + extraSeparation;
      axisParams.axisLabel = 'jPC_1';
      axisParams.axisOrientation = 'h';
      
      params.haxP{pindex} = analyze.jPCA.AxisMMC(...
         params.axLim(1),params.axLim(2),axisParams,...
         'color',[1 1 1],'borderColor',[1 1 1]);
      
      % vertical axis
      axisParams.axisOffset = farthestLeft + extraSeparation;
      axisParams.tickLocations = ...
         [-params.axLim(3), 0, params.axLim(4)];
      axisParams.axisLabel = 'jPC_2';
      axisParams.axisOrientation = 'v';
      axisParams.axisLabelOffset = 1.9*params.haxP{pindex}.axisLabelOffset;
      params.vaxP{pindex} = analyze.jPCA.AxisMMC(params.axLim(3),...
         params.axLim(4),axisParams,...
         'color',[1 1 1],'borderColor',[1 1 1]);
   else
      axisParams.curAxes = params.Axes;
      allTraj = findobj(params.Axes,'Tag','Trajectory');
      allMarker = findobj(params.Axes,'Tag','Marker');
      delete(allTraj);
      delete(allMarker);
   end
   
   % first deal with the ellipse for the plan variance (we want this under the rest of the data)
   if params.plotPlanEllipse
      analyze.jPCA.circle(ellipseRadii,theta_rot,mu);
   end
   
   % % % % THIS PLOTS THE INDIVIDUAL TRAJECTORIES % % % % %
   
   % Return formatted X,Y and color data for making individual trial
   % trajectories in one command:
   [X,Y,C] = arrayfun(@(P)fcn(P),Projection);
   X = cell2mat(X);
   Y = cell2mat(Y);
   C = cell2mat(C);
   
   if params.plotIndividualTrajs
      patch(params.Axes,X,Y,C,...
         'FaceColor','interp',...
         'FaceAlpha',params.tailAlpha*0.8,...
         'EdgeColor','interp',...
         'EdgeAlpha',params.tailAlpha,...
         'LineStyle','-',...
         'LineWidth',params.lineWidth,...
         'Tag','Trajectory');
   end
   
   % % % % % % % END INDIVIDUAL TRAJECTORIES % % % % % % %
   xC = [0;0.25;0;0   ;0;-0.25;0;0    ;0];
   yC = [0;   0;0;0.25;0;    0;0;-0.25;0];
   cC = [-40;0;40;0;-40;0;40;0;-40];
   patch(params.Axes,xC,yC,cC,...
      'EdgeColor','interp',...
      'LineWidth',1.5,...
      'FaceColor','interp',...
      'Tag','Marker');  % plot a central cross

   % if asked we will also plot the cross condition mean
   if params.plotMeanTrajs && (size(Summary.crossCondMean,1) > 1)
      cond = [Projection.Outcome];
      for iC = 1:2
         iCond = cond==iC;
         if sum(iCond)==0
            continue;
         end
         nPt = floor(size(X,1)/2);
         P1 = mean(X(1:nPt,iCond),2);
         P2 = mean(Y(1:nPt,iCond),2);

         if (numel(P1) < 2) || (numel(P2) < 2)
            str = repmat('->\t%6.7g\n',1,numel(overrideTimes));
            fprintf(1,['Could not find matches for:\n' str],overrideTimes);
            continue;
         end

         % make slightly thicker than for rest of data
         line(params.Axes,P1, P2,...
            'Color', params.meanColor(iC,:), ...
            'LineWidth', 2*params.lineWidth,...
            'LineStyle',':',...
            'Tag','Trajectory');  

         % for arrow, figure out last two points, and (if asked) supress 
         % the arrow if velocity is below a threshold.
         penultimatePoint = [P1(end-1), P2(end-1)];
         lastPoint = [P1(end), P2(end)];
         vel = norm(lastPoint - penultimatePoint);

         % if asked (e.g. for movies) arrow size may grow with vel
         aSize = params.arrowSize + params.arrowGain * vel;  
         analyze.jPCA.arrowMMC(penultimatePoint, lastPoint, [], ...
            'Size',aSize, ...
            'XLim',params.axLim(1:2),...
            'YLim',params.axLim(3:4),...
            'FaceColor',params.meanColor(iC,:),...
            'EdgeColor',params.meanColor(iC,:),...
            'Axes',params.Axes,...
            'FaceAlpha',1);
      end
   end
   if params.substRawPCs
      titleText = sprintf('raw PCA plane %d', plane);
   elseif strcmp(params.rankType, 'varCapt')
      letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      titleText = sprintf(...
         'jPCA plane %s (by Variance)\n %s - %s - Day-%02d (%s) ', ...
         letters(planes2plot_Orig(pindex)),params.Animal,params.Alignment,...
         params.Day,params.Area);
   else
      titleText = sprintf(...
         'jPCA plane %d (by Eigenvalue)\n %s - %s - Day-%02d (%s) ', ...
         plane,params.Animal,params.Alignment,params.Day,params.Area);
   end   
   if isempty(params.titleText_plane)
      params.titleText_plane = ...
         text(params.Axes,0,0.99*params.axLim(4),titleText, ...
         'HorizontalAlignment','center',...
         'Color','w',...
         'FontSize',16,...
         'FontWeight','bold',...
         'FontName',params.fontName);
   end
end  % done looping through planes
params.colorStruct = colorStruct;

%    function alpha = compute_tail_alpha(cl,c)
%       %COMPUTE_TAIL_ALPHA Return tail-alpha based on condition/index
%       %
%       % alpha = compute_tail_alpha(cl,c);
%       % 
%       % Inputs
%       %  cl   - Condition labels (numeric) for each plotted trajectory
%       %  c    - Condition label for this trajectory
%       %
%       % Output
%       %  alpha- Computed alpha value
%       
%       alpha = max(min((-tansig(sum(cl==cl(c))/numel(cl))+1)/2,0.8),0.2);
%    end

   function [X,Y,C] = recover_traj_segment(Proj,xDim,yDim,keepTimes,use_rot)
      %RECOVER_TRAJ_SEGMENT Return trajectory segment from struct array
      %
      % [X,Y,C] = recover_traj_segment(Proj,xDim,yDim,keepTimes);
      %
      % Inputs
      %  Proj      - Element of struct array that is main input to 
      %                 `phaseSpace` with fields `.proj` and `.times`
      %  xDim      - Index of "X" trajectory dimension
      %  yDim      - Index of "Y" trajectory dimension
      %  keepTimes - Times (ms) to keep
      %
      % Output
      %  X         - Cell containing column vector of X-coordinates to plot
      %  Y         - Cell containing column vector of Y-coordinates to plot
      %  C         - Cell containing time vector for shading from colormap
      
      o = 0.04;
      
      iKeep = ismember(Proj.times,keepTimes);
      if use_rot
         x = Proj.proj_rot(iKeep,xDim);
         y = Proj.proj_rot(iKeep,yDim);
      else
         x = Proj.proj(iKeep,xDim);
         y = Proj.proj(iKeep,yDim);
      end
      cdata = (1:sum(iKeep));
      cdata = (cdata .* (Proj.Outcome-1.5) .* 2).';
      vX = (x(end)-x(end-1))/2;
      X = {[x+o; x(end)+vX; flipud(x-o)]};
      vY = (y(end)-y(end-1))/2;
      Y = {[y; y(end)+vY; flipud(y)]};
      C = {[cdata; cdata(end)*1.1; flipud(cdata)]};
   end

   function state = recover_traj_state(Proj,xDim,yDim,iKeep,use_rot)
      %RECOVER_TRAJ_STATE Return trajectory state from struct array
      %
      % state = recover_traj_state(Proj,xDim,yDim,iKeep);
      %
      % Inputs
      %  Proj      - Element of struct array that is main input to 
      %                 `phaseSpace` with fields `.proj` and `.times`
      %  xDim      - Index of "X" trajectory dimension
      %  yDim      - Index of "Y" trajectory dimension
      %  iKeep     - Specific index (row) to keep
      %
      % Output
      %  X         - Cell containing column vector of X-coordinates to plot
      %  Y         - Cell containing column vector of Y-coordinates to plot
      %  C         - Cell containing time vector for shading from colormap
      
      if use_rot
         state = {Proj.proj_rot(iKeep,[xDim,yDim])};
      else
         state = {Proj.proj(iKeep,[xDim,yDim])};
      end
   end

end  % end of the main function




