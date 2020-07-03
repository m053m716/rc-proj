function Te = get_electrode_table(T)
%GET_ELECTRODE_TABLE Returns "electrode table" based on "master" table
%
%  Te = utils.get_electrode_table(T);
%
% Inputs
%  T  - "Master" table
%
% Output
%  Te - Electrode table with stereotaxic info for each channel of interest
%
% See also: make.exportSkullPlotMovie, ratskull_plot

[~,iU,~] = unique(T.ChannelID);
Te = T(iU,...
   {'ChannelID','AnimalID','Group','ML','ICMS','Area','ProbeID','X','Y'});
Te.Properties.Description = 'Electrode stereotaxic info table';

end