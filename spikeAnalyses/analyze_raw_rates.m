clearvars -except R
if exist('R','var')==0
   R = getfield(load(defaults.files('raw_rates_table_file'),'R'),'R');
end

% Get relative sample times for each rate bin
t = R.Properties.UserData.t;

% We should get the average rate 