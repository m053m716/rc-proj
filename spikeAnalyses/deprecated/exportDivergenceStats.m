function out = exportDivergenceStats(J,Td,S,Cs,max_T0,do_transforms)
%% EXPORTDIVERGENCESTATS   Export statistics for divergence of jPCA trajs
%
%  out = EXPORTDIVERGENCESTATS(J,Td,S,Cs);
%
%  --------
%   INPUTS
%  --------
%     J     :     Table returned by GETJPCA method on GROUP class object.
%
%     Td    :     Divergence times, a cell array with same number of rows
%                    as J, where each cell contains times of occurrence
%                    relative to the grasp for cosine similarity between
%                    successful and unsuccessful trials.
%
%     S     :     Cell array of cosine similarity scores, that corresponds
%                    to elements of Td.
%
%     Cs    :     Cell array of cosine similarity scores, for all time
%                    points of the trajectory relative to grasp.
%
%  max_T0   :     (Optional) Max time (ms) for first minimum to occur
%
%  do_transforms  :  (Optional) Specifies whether or not to apply
%                       transforms to data (def: true)
%
%  --------
%   OUTPUT
%  --------
%    out    :     Table similar to J, but with appended data for divergence
%                    points of interest.
%
% By: Max Murphy  v1.0  2019-06-19  Original version (R2017a)

%%
if nargin < 6
   do_transforms = true;
end

if nargin < 5
   max_T0 = 400;
end

%% Remove days with no successful attempts
iRemove = cellfun(@isempty,Td);
J(iRemove,:) = []; 
Td(iRemove) = []; 
S(iRemove) = [];
Cs(iRemove) = [];

%%
out = J(:,1:7);
S_mu = cellfun(@mean,S);
Cs_med = cellfun(@median,Cs);
T_0 = cellfun(@min,Td);
S_min = nan(size(S_mu));
T_min = nan(size(T_0));
RotScore = nan(size(T_min));
N_min = cellfun(@numel,S);

for ii = 1:numel(Td)
   [S_min(ii),ind] = min(S{ii});
   T_min(ii) = Td{ii}(ind);
   RotScore(ii) = cos(J.Data(ii).Summary.circStats{1}.circMn-pi/2);
end

out = [out, table(RotScore,S_mu,Cs_med,S_min,T_0,T_min,N_min)];
out(out.T_0 >= max_T0,:) = [];
out(out.T_min >= max_T0,:) = [];

if nargout < 1
   lpf_fc = defaults.block('lpf_fc');
   output_score = defaults.group('output_score');
   jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
   
   
   muT = mean(jpca_start_stop_times);
   rT = range(jpca_start_stop_times);
   
   if do_transforms
      out.Score = sinh(out.Score./max(out.Score));    % score transform
      out.PostOpDay = tanh((out.PostOpDay - 14)/7); % time transform
      out.T_min = (out.T_min + muT)/rT;  % stat transform on T_min
      out.T_0 = (out.T_0 + muT)/rT; % stat transform on T_0
      
      writetable(out,sprintf('DivergenceStats_%s_%gms_to_%gms_%s_%gHzFc_transformed.xls',...
         J.Align{1},jpca_start_stop_times(1),jpca_start_stop_times(2),...
         output_score,lpf_fc));
   else

      writetable(out,sprintf('DivergenceStats_%s_%gms_to_%gms_%s_%gHzFc.xls',...
         J.Align{1},jpca_start_stop_times(1),jpca_start_stop_times(2),...
         output_score,lpf_fc));
   end
end

end