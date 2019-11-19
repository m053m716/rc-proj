classdef spikeData < matlab.mixin.Copyable
   %SPIKEDATA  Handle to data for individual spike rate data
   
   % Public, viewable properties set on construction
   properties (SetAccess = immutable, GetAccess = public, Hidden = false)
      Children
   end
   
   % Public, hidden properties set on construction
   properties (SetAccess = immutable, GetAccess = public, Hidden = true)
      t
   end
   
   % Viewable properties that can only be set by class methods
   properties (SetAccess = private, GetAccess = public, Hidden = false)
      TrialFilter  % Struct indicating current filtering 
   end
   
   % Hidden properties that can be publically accessed/set
   properties (SetAccess = public, GetAccess = public, Hidden = true)
      g            % gramm class object
   end
   
   % CONSTRUCTOR 
   methods (Access = public)
      function obj = spikeData(groupObj,varargin)
         % Handle input types
         switch class(groupObj)
            case 'group'
               % Expected type, continue
               obj.Children = groupObj;
               % Assign this as "Parent" for the groupObj
               setParent(groupObj,obj);
            case 'rat'
               % Handle rat input?
               error('Not setup for rat input yet.');
            case 'block'
               % Handle block input?
               error('Not setup for block input yet.');
            otherwise 
               if isscalar(groupObj) && isnumeric(groupObj)
                  n = groupObj;
                  obj = repmat(obj,n,1);
                  return;
               else
                  error('Unrecognized input type: %s',class(groupObj));
               end
         end

         % Set initial TrialFilter property
         p = spikeData.def('TrialFilter');
         if numel(varargin) == 0
            fprintf(1,'Initializing spikeData with default TrialFilter.\n');
         else
            fprintf(1,'Initializing spikeData...\n');
            for i = 1:2:numel(varargin)
               % Can set this to false to suppress verbosity
               spikeData.readOutPairs(varargin{i},varargin{i+1},true);
               p = utils.setParamField(p,varargin{i},varargin{i+1});
            end
         end
         obj.setTrialFilter(p);
         [~,obj.t,~] = obj.getRate; % Initialize 't'
      end
   end
   
   % "GET" methods
   methods (Access = public)
      % Returns [nTotalIncludedTrialChannelCombos x nTimesteps] : 'rate'
      % Returns [1 x nTimesteps] : 't'
      % Returns metadata about each
      function [rate,t,meta] = getRate(obj)
         % GETRATE  Returns rate using the current TrialFilter prop value
         if numel(obj) > 1
            error('getRate should only be called on scalar spikeData objects.');
         end
         % Use TrialFilter property to filter output
         f = obj.TrialFilter;
         
         % Refine based on what recordings are used
         groupObjArray = getSubGroup(obj.Children,f.group);
         ratObjArray = getSubsetByName(vertcat(groupObjArray.Children),f.rat);
         blockObjArray = getSubsetByDayRange(vertcat(ratObjArray.Children),f.poday);
         tic;
         if isempty(obj.t)
            [rate,meta] = utils.initEmpty; % Just get 't'
            [~,t,~] = getTrialData(blockObjArray,...
                        f.include,f.align,f.area,f.icms,true);
         else
            [r,t,m] = getTrialData(blockObjArray,...
                           f.include,f.align,f.area,f.icms,true);
            [rate,meta] = spikeData.formatRateCellArray(r,m,t);
         end
         toc;
      end
   end
   
   % "SET" methods
   methods (Access = public)
      function setTrialFilter(obj,varargin)
         % SETTRIALFILTER  Sets filter for what spike rates are returned
         %
         %  obj.setTrialFilter('Name',value,...);
         %
         %  Options ('Name' | example value): 
         %  -> Filtering
         %  --> 'group'     | {'Ischemia','Intact'}; or 'Intact';
         %  --> 'include'   | utils.makeIncludeStruct({include},{exclude});
         %  --> 'align'     | 'Grasp';
         %  --> 'rat'       | {'RC-02'; 'RC-21'};
         %  --> 'poday'     | 3:28; or scalar
         %  --> 'area'      | 'CFA' or {'CFA,'RFA'}
         %  --> 'icms'      | 'DF' or {'DF','O','NR','PF','DF-PF'};
         %
         %  -> Annotation
         %  --> 'group_tag'   | 'Both Groups';
         %  --> 'include_tag' | 'Successful Retrievals';
         %  --> 'align_tag'   | 'Grasp Onset';
         %  --> 'rat_tag'     | 'All Rats';
         %  --> 'poday_tag'   | 'All Days';
         %  --> 'area_tag'    | 'CFA and RFA';
         %  --> 'icms_tag'    | 'All ICMS';
         
         % Parse inputs
         if nargin == 2
            p = varargin{1};
         else
            p = spikeData.def('TrialFilter');
            for i = 1:2:numel(varargin)
               p = utils.setParamField(p,varargin{i},varargin{i+1});
            end
         end
         
         % Handle object array input
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).setTrialFilter(obj,p);
            end
            return;
         end
         
         obj.TrialFilter = p;
      end
   end
   
   % "GRAPHICS" methods
   methods (Access = public)
      function plot(obj,t,rate,meta,doExport)
         if nargin < 5
            doExport = false;
         elseif doExport
            close all force; % Ensure figures are closed
         end

         obj.g = gramm('x',t,'y',rate,...
            'color',meta.ML,...
            'lightness',meta.Score,...
            ...'group',meta.ChID,...
            'subset',(meta.Outcome == 1) & (meta.Name == 'RC-05'));

%          poday = flipud(unique(meta.PostOpDay));
         name = flipud(unique(meta.Name));
         
%          obj.g.facet_grid(meta.Area,meta.Name);
%          obj.g.fig(meta.PostOpDay);
         obj.g.facet_wrap(meta.ChID);
%          obj.g.fig(meta.PostOpDay);
         
         obj.g.set_names('z','Post-Op Day',...
            'x','Time (ms)','y','Spike Rate','color','Medial vs Lateral',...
            ...'lightness','Medial vs Lateral',...
            'column','ChID',...
            'fig','Post-Op Day');
         
         obj.g.stat_summary('type','ci','geom','area');
         
         obj.g.set_text_options('font','Arial','base_size',14);
%          obj.g.set_color_options('map','brewer_paired');
         
         obj.g.draw();
         if doExport
            p = spikeData.def('RateFig');
            if exist(p.path,'dir')==0
               mkdir(p.path);
            end
            
            r = get(gcf,'Parent');
            f = get(r,'Children');
            for i = 1:numel(poday)
               set(f(i),'Units','Normalized','Position',p.pos);
%                fname = sprintf(p.fname,poday(i));
               fname = sprintf(p.fname,char(name(i)));
               expAI(f(i),fullfile(p.path,fname));
               savefig(f(i),fullfile(p.path,[fname '.fig']));
               saveas(f(i),fullfile(p.path,[fname '.png']));
               delete(f(i));
            end
         end
      end
   end
   
   % "PRIVATE" methods
   methods (Access = private, Hidden = true)
   end
   
   % "STATIC" methods (DEFAULTS)
   methods (Access = public, Static = true, Hidden = false)      
      % Helper method to format rate cell array and associated metadata
      function [rate,meta] = formatRateCellArray(r,m,t)
         % FORMATRATECELLARRAY   Format rate and metadata arrays
         %
         %  [rate,meta] = FORMATRATECELLARRAY(r,m,t);
         %
         %  inputs - 
         %     r : Cell array of rates [nTrial x nTimestep x nChannel] of
         %           length (nBlock)
         %     m : Cell array of same dimension as r, with struct for each
         %            corresponding block containing metadata
         %     t : Time vector for rate timesteps
         
         N = sum(cellfun(@(x)size(x,1)*size(x,3),r));
         M = numel(t);
         RAT_ID_INC = 32;
         
         fprintf(1,'Rearranging %g trajectories...%03g%%\n',N,0);
         rate = nan(N,M);
         
         [Name,Group,ML,ICMS,Area] = utils.initCellArray(N,1);
         [tGrasp,tSeg1,tSeg2,tSupport,PelletPresent,Outcome,PostOpDay,Score,ChID] = ...
            utils.initNaNArray(N,1);
         
         iStart = 1;
         curRat = 'RC';
         iRat = -1;
         for i = 1:numel(m)
            nTrial = size(r{i},1);
            
            s1 = m{i}.behaviorData.Grasp - m{i}.behaviorData.Reach;
            s2 = m{i}.behaviorData.Complete - m{i}.behaviorData.Grasp;
            poday = ones(nTrial,1) * m{i}.poday;
            sc = ones(nTrial,1) * m{i}.score;
            
            if ~strcmpi(curRat,m{i}.channelInfo(1).Name)
               curRat = m{i}.channelInfo(1).Name;
               iRat = iRat + 1;
            end
            
            for ch = 1:size(r{i},3)
               iStop = (iStart + nTrial - 1);
               idx = iStart:iStop;
               
               rate(idx,:) = r{i}(:,:,ch);
               tGrasp(idx,1) = m{i}.behaviorData.Grasp;
               tSeg1(idx,1) = s1;
               tSeg2(idx,1) = s2;
               tSupport(idx,1) = m{i}.behaviorData.Support;
               PelletPresent(idx,1) = m{i}.behaviorData.PelletPresent;  
               Outcome(idx,1) = m{i}.behaviorData.Outcome;
               PostOpDay(idx,1) = poday;
               Score(idx,1) = sc;
               ChID(idx,1) = ones(nTrial,1) * ((iRat*RAT_ID_INC) + ...
                  m{i}.channelInfo(ch).channel + 16*(m{i}.channelInfo(ch).probe-1));
               Name(idx,1) = repmat({m{i}.channelInfo(ch).Name},nTrial,1);
               Group(idx,1) = repmat({m{i}.channelInfo(ch).Group},nTrial,1);
               ML(idx,1) = repmat({m{i}.channelInfo(ch).ml},nTrial,1);
               ICMS(idx,1) = repmat({m{i}.channelInfo(ch).icms},nTrial,1);
               Area(idx,1) = repmat({m{i}.channelInfo(ch).area},nTrial,1);
               iStart = iStop + 1;
            end
            fprintf(1,'\b\b\b\b\b%03g%%\n',round((i/numel(m))*100));
         end
         Name = categorical(Name);
         Group = categorical(Group);
         ML = categorical(ML);
         ICMS = categorical(ICMS);
         Area = categorical(Area);
         
         meta = table(Name,Group,ML,ICMS,Area,tGrasp,...
            tSeg1,tSeg2,tSupport,PelletPresent,Outcome,PostOpDay,Score,ChID);
      end
      
      % Helper method to read out input argument pairs to Command Window
      function readOutPairs(paramName,paramVal,verbose)
         % READOUTPAIRS  Read out pairs of 'name', value inputs to
         %  constructor. Set verbose false to skip.
         if ~verbose
            return;
         end
         
         if ischar(paramVal)
            fprintf(1,'-->\tTrialFilter.%s: %s\n',paramName,paramVal);
         elseif isnumeric(paramVal)
            fprintf(1,'-->\tTrialFilter.%s: [',paramName);
            fprintf(1,'%g, ',paramVal);
            fprintf(1,'\b\b]\n');
         elseif isstruct(paramVal)
            
            if iscell(paramVal.Include)
               fprintf(1,'-->\tTrialFilter.%s.Include: {',paramName);
               fprintf(1,'%s, ',paramVal.Include{:});
               fprintf(1,'\b\b}\n');
            elseif isempty(paramVal.Include)
               fprintf(1,'-->\tTrialFilter.%s.Include: []\n',paramName);
            else
               fprintf(1,'-->\tTrialFilter.%s.Include: ''%s''\n',...
                  paramName,paramVal.Include);
            end
            if iscell(paramVal.Exclude)
               fprintf(1,'-->\tTrialFilter.%s.Exclude: {',paramName);
               fprintf(1,'%s, ',paramVal.Exclude{:});
               fprintf(1,'\b\b}\n');
            elseif isempty(paramVal.Exclude)
               fprintf(1,'-->\tTrialFilter.%s.Exclude: []\n',paramName);
            else
               fprintf(1,'-->\tTrialFilter.%s.Exclude: ''%s''\n',...
                  paramName,paramVal.Exclude);
            end
         elseif iscell(paramVal)
            fprintf(1,'-->\tTrialFilter.%s.Include: {',paramName);
            fprintf(1,'%s, ',paramVal{:});
            fprintf(1,'\b\b}\n');
         end
      end
      
      % Helper method to list out default parameters
      function defParams = def(paramName)
         p = struct;
         p.TrialFilter = struct;
         p.TrialFilter.group = {'Ischemia','Intact'};
         p.TrialFilter.group_tag = 'Both Groups';
         p.TrialFilter.include = utils.makeIncludeStruct;
         p.TrialFilter.include_tag = 'All Retrievals Attempts';
         p.TrialFilter.align = 'Grasp';
         p.TrialFilter.align_tag = 'Grasp Onset';
         p.TrialFilter.rat = {'RC-02','RC-04','RC-05','RC-08','RC-14','RC-18','RC-21','RC-26','RC-30','RC-43'};
         p.TrialFilter.rat_tag = 'All Rats';
         p.TrialFilter.poday = 3:28;
         p.TrialFilter.poday_tag = 'All Days';
         p.TrialFilter.area = {'CFA','RFA'};
         p.TrialFilter.area_tag = 'CFA and RFA';
         p.TrialFilter.icms = {'DF','PF','DF-PF','PF-DF','O','NR'};
         p.TrialFilter.icms_tag = 'All ICMS';
         
         p.RateFig.path = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\Rate\Gramm\';
         p.RateFig.fname = 'Gramm_%s_SpikeRate';
         p.RateFig.pos = [0.14 0.17 0.66 0.63];
         
         defParams = utils.getParamField(p,paramName);
      end
   end
   
end

