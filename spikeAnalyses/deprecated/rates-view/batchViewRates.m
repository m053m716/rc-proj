function fig = batchViewRates(data,info,pars,varargin)
%% BATCHVIEWRATES    View average rate for a bunch of channels.
%
%  fig = BATCHVIEWRATES(data,info,pars)
%  fig = BATCHVIEWRATES(data,info,pars,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%    data      :     Tensor matrix nTrial x nTimebins x nChannels of
%                       normalized spike rates from SAVEALIGNMENT.
%
%    info      :     Header struct, should have same number of elements as
%                       nChannels from SAVEALIGNMENT.
%
%    pars      :     Parameters struct from SAVEALIGNMENT.
%
%  --------
%   OUTPUT
%  --------
%    fig       :     Cell array of handles to figures output by function.
%
% By: Max Murphy  v1.0  12/28/2018  Original version (R2017a)

%% DEFAULTS
FIG_POS = [0.22,0.13,0.38,0.62];
TITLE_STR = '%s %s %s: Ch-%03g';
YLIM = [-6 6];
YLABEL = 'Normalized IFR';
XLABEL = 'Time (sec)';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

fig = cell(numel(info),1);
for ii = 1:numel(info)
   nameStr = sprintf(TITLE_STR,...
                     pars.name,...
                     pars.group,...
                     info(ii).area,...
                     info(ii).channel);
                  
   fig{ii} = figure('Name',nameStr,...
      'Units','Normalized',...
      'Position',FIG_POS,...
      'Color','w');
   
   plot(pars.t,mean(data(:,:,ii),1));
   
   xlim([min(pars.t) max(pars.t)]);
   ylim(YLIM);
   
   ylabel(YLABEL,'FontName','Arial','Color','k','FontSize',14);
   xlabel(XLABEL,'FontName','Arial','Color','k','FontSize',14);
   title(nameStr,'FontName','Arial','Color','k','FontSize',16);
end

end