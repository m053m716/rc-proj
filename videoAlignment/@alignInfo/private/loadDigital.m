function stream_struct = loadDigital(filename)
%% LOADDIGITAL    Load digital stream file for beam or pellet breaks
%
%  stream_struct = LOADDIGITAL(filename);
%
%  --------
%   INPUTS
%  --------
%  filename       :     Full file (path + name) to digital stream Matlab
%                       file.
%
%  --------
%   OUTPUT
%  --------
%  stream_struct  :     Struct with fields for 'data', 'fs', and 't'.
%
% By: Max Murphy  v1.0   08/27/2018  Original version (R2017b)

%% SIMPLE CODE
% Load data file
stream_struct = load(filename,'data','fs');
                           
% Get time vector         
stream_struct.t = linspace(0,...
            (numel(stream_struct.data)-1)/stream_struct.fs,...
             numel(stream_struct.data));
          
% Remove DC bias
stream_struct.data = stream_struct.data - min(stream_struct.data);


% Normalize between 0 and 1
stream_struct.data = stream_struct.data ./ max(stream_struct.data);

end