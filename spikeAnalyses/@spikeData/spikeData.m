classdef spikeData < matlab.mixin.Copyable
   %SPIKEDATA  Handle to data for individual spike rate data
   
   % Public, viewable properties set on construction
   properties (SetAccess = immutable, GetAccess = public, Hidden = false)
      Children
   end
   
   % Public, hidden properties set on construction
   properties (SetAccess = immutable, GetAccess = public, Hidden = true)
   end
   
   % Viewable properties that can only be set by class methods
   properties (SetAccess = private, GetAccess = public, Hidden = false)
      TrialFilter  % Struct indicating current filtering 
   end
   
   % Hidden properties that can be publically accessed/set
   properties (SetAccess = public, GetAccess = public, Hidden = true)
      g            % gramm class object
   end
   
   % CONSTRUCTOR and data-handling
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
         for i = 1:2:numel(varargin)
            p = utils.setParamField(p,varargin{i},varargin{i+1});
         end
         obj.setTrialFilter(p);
      end
   end
   
   % "GET" methods
   methods (Access = public)
      function [rate,t,meta] = getRate(obj)
         % GETRATE  Returns rate using the current TrialFilter prop value
         if numel(obj) > 1
            error('getRate should only be called on scalar spikeData objects.');
         end
         % Use TrialFilter property to filter output
         f = obj.TrialFilter;
         
         % Refine based on what recordings are used
         groupObjArray = getSubGroup(obj.Children,f.group);
         ratObjArray = getSubsetByName(groupObjArray.Children,f.rat);
         blockObjArray = getSubsetByDayRange(ratObjArray.Children,f.poday);
         tic;
         [rate,t,meta] = getTrialData(blockObjArray,...
            f.include,f.align,f.area,f.icms,true);
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
   end
   
   % "PRIVATE" methods
   methods (Access = private, Hidden = true)
   end
   
   % "STATIC" methods (DEFAULTS)
   methods (Access = public, Static = true, Hidden = false)
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
         
         defParams = utils.getParamField(p,paramName);
      end
   end
   
end

