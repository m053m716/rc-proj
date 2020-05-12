function [out,zMu] = zeroCenterPoints(in,zero_index,varargin)
%% ZEROCENTERPOINTS  Ensures that element "zero_index" starts at 0

for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if isstruct(in)
   FIELDS_TO_GET_NORM = {...
      'projAllTimes';
      'projAllTimes';
      'tradPCAprojAllTimes';
      'tradPCAprojAllTimes'};
   FIELDS_TO_DO_NORM = {...
      'proj';
      'projAllTimes';
      'tradPCAproj';
      'tradPCAprojAllTimes'};
   
   if numel(FIELDS_TO_GET_NORM) ~= numel(FIELDS_TO_DO_NORM)
      error('FIELDS_TO_GET_NORM (%d) must have same number of elements as FIELDS_TO_DO_NORM (%d).',...
         numel(FIELDS_TO_GET_NORM),numel(FIELDS_TO_DO_NORM));
   end
   
   zMu = cell(numel(FIELDS_TO_DO_NORM),1);
   for iF = 1:numel(FIELDS_TO_DO_NORM)
      if isfield(in,FIELDS_TO_DO_NORM{iF})
         [in,zMu{iF}] = doNorm(in,...
            FIELDS_TO_DO_NORM{iF},...
            FIELDS_TO_GET_NORM{iF},...
            zero_index);
      else
         fprintf(1,'Missing field to norm: %s\n',FIELDS_TO_DO_NORM{iF});
      end
   end
   out = in;
else
   zMu = in(zero_indx,:);
   out = in - repmat(zMu,size(in,1),1);
end

   function [s,mu] = doNorm(s,field2norm,field4norm,zi)
      if isfield(s,field4norm)
         x = cat(3,s.(field2norm));
         y = cat(3,s.(field4norm));
         mu = mean(y,3);
         mu = mu(zi,:);
         x = x - repmat(mu,1,1,size(x,3));
         for iX = 1:size(x,3)
            s(iX).(field2norm) = x(:,:,iX);
         end
      else
         fprintf(1,'Missing field to get norm: %s\n',field4norm);
      end
   end

end