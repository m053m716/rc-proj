function [V,s] = exportNVstats(stats,outcome)
%% EXPORTNVSTATS  Export stats for (premotor) neural variability
%
%  V = EXPORTNVSTATS(stats);
%
%  --------
%   INPUTS
%  --------
%    stats     :     Table returned by GETCHANNELWISERATESTATS on GROUP
%                       class object (for successful grasps only).
%
%  --------
%   OUTPUT
%  --------
%     V        :     Copy of exported table, which is formatted for JMP.
%
% By: Max Murphy  v1.0  2019-06-23  Original version (R2017a)

%% DEFAULTS
R = 10; % decimation factor
T_START = -400;
T_STOP = 400;

%%
if nargin < 2
   outcome = 'Successful';
end

%%
s = screenStats(stats);
V = s(:,[1:6,10,11,12:19]);

x = s.NV;
t_dec = linspace(-2000,1000,round(size(x,2)/R));
t_dec2 = linspace(-2000,1000,round(size(x,2)/(4*R)));
dec_idx = (t_dec>=T_START) & (t_dec<=T_STOP);
dec2_idx = (t_dec2>=T_START) & (t_dec2<=T_STOP);
for ii = 1:size(x,1)
   tmp = decimate(x(ii,:),R);
   tmp2 = decimate(x(ii,:),4*R);
   y(ii,:) = tmp(dec_idx); %#ok<*AGROW>
   z(ii,:) = tmp2(dec2_idx);
end

[coeff,score] = pca(y);
pc = score(:,1:3);

figure('Name','Neural Variability PCA',...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.35 0.1 0.3 0.8]); 

subplot(2,1,1); 
plot(t_dec(dec_idx),coeff(:,1:3),'LineWidth',2); 
legend({'PC-1';'PC-2';'PC-3'}); 
xlabel('Time (ms)','FontName','Arial','Color','k','FontSize',14); 
ylabel('PC Coefficient','FontName','Arial','Color','k','FontSize',14); 
title('Neural Variability Principle Components','FontName','Arial','Color','k','FontSize',16); 

subplot(2,1,2); 
scatter3(score(:,1),score(:,2),score(:,3)); 
xlabel('PC-1','FontName','Arial','Color','k','FontSize',14); 
ylabel('PC-2','FontName','Arial','Color','k','FontSize',14);  
zlabel('PC-3','FontName','Arial','Color','k','FontSize',14);  

V = [V, table(pc,z)];
s = [s, table(pc)];

output_score = defaults.group('output_score');
jpca_align = defaults.jPCA('jpca_align');
writetable(V,fullfile(pwd,sprintf(...
   'NVStats_%s_%s_Full_%s_%gms_to_%gms.xls',...
   jpca_align,outcome,output_score,T_START,T_STOP)));

end