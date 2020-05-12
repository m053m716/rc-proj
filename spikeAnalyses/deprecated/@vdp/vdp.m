classdef vdp < handle
   %UNTITLED12 Summary of this class goes here
   %   Detailed explanation goes here
   
   properties (Access = public)
      mu
      mmse
   end
   
   properties (Access = public, Hidden = true)
      X
      t
   end
   
   methods
      function obj = vdp(X,t)
         if isscalar(X)
            obj = repmat(obj,X,1);
            return;
         end
         
         if nargin < 2
            t = 1:size(X,1);
         end
         
         if size(X,2) > 1
            obj = vdp(size(X,2));
            for ii = 1:size(X,2)
               obj(ii) = vdp(X(:,ii),t);
            end
            return;
         end
         
         obj.X = X;
         obj.t = t;
         
         
      end
   end
   
end

