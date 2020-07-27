function flag = updateSpikeRateData(obj,align,outcome,varargin)
%UPDATESPIKERATEDATA  Updates Block spike rate data
%
%  flag = updateSpikeRateData(obj);
%  flag = updateSpikeRateData(obj,align);
%  flag = updateSpikeRateData(obj,align,outcome);
%  flag = updateSpikeRateData(obj,align,outcome,'name',value,...);
%
% Inputs
%  obj      - `block` object
%  align    - `'Grasp'` or `'Reach'`
%  outcome  - `'Successful'` or `'Unsuccessful'` or `'All'`
%  varargin - (Optional) <'name',value> pairs
%              * 'fname_norm_rate' : File expression for rate file
%              * 'spike_bin_w'     : (def: 60) scalar integer (ms/bin)
%
% Output
%  flag     - True if executed successfully
%
% Associates rate file data in "_SpikeRate%03dms_%s_%s.mat" files in
% _SpikeAnalyses sub-folder with the block object in its Rate data struct.
%
% See also: block

flag = false;
if nargin < 2
   align = defaults.block('alignment');
end
if nargin < 3
   outcome = defaults.block('outcome');
end

pars = defaults.block('fname_norm_rate','spike_bin_w');
fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iv+1};
   end
end

if numel(obj) > 1
   flag = false(size(obj));
   for ii = 1:numel(obj)
      flag(ii) = updateSpikeRateData(obj(ii),align,outcome);
   end
   return;
end

str = sprintf(pars.fname_norm_rate,obj.Name,pars.spike_bin_w,align,outcome);
ioPath = obj.getPathTo('rate');
fname = fullfile(ioPath,str);
if (exist(fname,'file')==0) && (~obj.HasData)
   fprintf(1,'No such file: %s\n',str);
   obj.Data.(align).(outcome).rate = [];
   return;
elseif exist(fname,'file')==0
   fprintf(1,'No such file: %s\n',str);
   obj.Data.(align).(outcome).rate = [];
   return;
else
   fprintf('Updating %s-%s rate data for %s...\n',outcome,align,obj.Name);
   in = load(fname,'data','t');
   if nargin == 3
      obj.Data.(align).(outcome).rate = in.data;
      if isfield(in,'t')
         obj.Data.(align).(outcome).t = in.t;
      else
         obj.Data.(align).(outcome).t = defaults.experiment('t_ms');
      end
   else % For old versions
      obj.Data.rate = in.data;
      if isfield(in,'t')
         obj.Data.t = in.t;
      else
         obj.Data.t = linspace(min(obj.T),max(obj.T),size(in.data,2));
      end
   end
   obj.HasData = true;
   flag = true;
end

end