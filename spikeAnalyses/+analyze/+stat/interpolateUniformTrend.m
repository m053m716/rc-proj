function Y = interpolateUniformTrend(r)
%INTERPOLATEUNIFORMTREND Interpolates trends between per-day averages
%
%  Y = analyze.stat.interpolateUniformTrend(r);
%
% Inputs
%  r - Table with binned spike counts after exclusions
%  
% Output
%  Y - Interpolated table
%
% See also: analyze.stat, unit_learning_stats

T_PRE_GRASP = 0.6;
T_GRASP = 0.3;
allDays = 1:35;

r(r.Properties.UserData.Excluded,:) = [];
G = findgroups(r(:,'ChannelID'));
[Xpre,Xreach,Xgrasp,Xretract] = splitapply(@(a,b,c,d,e)trendsByDay(allDays,a,b,c,d,e),r.PostOpDay,...
   sqrt(r.N_Pre_Grasp./T_PRE_GRASP),sqrt(r.N_Reach./r.Reach_Epoch_Duration),...
   sqrt(r.N_Grasp./T_GRASP),sqrt(r.N_Retract./r.Retract_Epoch_Duration),G);
[~,iU] = unique(G);
Y = r(iU,{'Group','AnimalID','Alignment','ICMS','Area','ChannelID'});

iRemove = cellfun(@isempty,Xpre);
Y(iRemove,:) = [];
Xpre(iRemove) = [];
Xreach(iRemove) = [];
Xgrasp(iRemove) = [];
Xretract(iRemove) = [];

% tmp = cell2mat(Xpre);
% for ii = 1:size(tmp,2)
%    if ~any(isnan(tmp(:,ii)))
%       iStartAll = ii;
%       break;
%    end
% end
% 
% for ii = size(tmp,2):-1:1
%    if ~any(isnan(tmp(:,ii)))
%       iStopAll = ii;
%       break;
%    end
% end
% 
% vec = iStartAll:iStopAll;
% Y.Pre = tmp(:,vec);
% tmp = cell2mat(Xreach);
% Y.Reach = tmp(:,vec);
% tmp = cell2mat(Xgrasp);
% Y.Grasp = tmp(:,vec);
% tmp = cell2mat(Xretract);
% Y.Retract = tmp(:,vec);

Y.Pre = cell2mat(Xpre);
Y.Reach = cell2mat(Xreach);
Y.Grasp = cell2mat(Xgrasp);
Y.Retract = cell2mat(Xretract);

% Remove outlier channels
Y(max(Y.Pre,[],2)>15,:) = [];

% Smooth across days
Y.Pre = max(sgolayfilt(Y.Pre,3,15,ones(1,15),2),0);
Y.Reach = max(sgolayfilt(Y.Reach,3,15,ones(1,15),2),0);
Y.Grasp = max(sgolayfilt(Y.Grasp,3,15,ones(1,15),2),0);
Y.Retract = max(sgolayfilt(Y.Retract,3,15,ones(1,15),2),0);

idx = (allDays >= 7) & (allDays <= 24);
Y.Pre = Y.Pre(:,idx);
Y.Reach = Y.Reach(:,idx);
Y.Grasp = Y.Grasp(:,idx);
Y.Retract = Y.Retract(:,idx);
Y.Properties.UserData = struct('PostOpDay',allDays(idx));

   function [Xpre,Xreach,Xgrasp,Xretract] = trendsByDay(allDays,poDay,xpre,xreach,xgrasp,xretract)
      
      d = numel(allDays);
      
      Xpre = nan(1,d);
      Xreach = nan(1,d);
      Xgrasp = nan(1,d);
      Xretract = nan(1,d);
      
      for iDay = 1:d
         Xpre(iDay) = nanmean(xpre(poDay==allDays(iDay)));
         Xreach(iDay) = nanmean(xreach(poDay==allDays(iDay)));
         Xgrasp(iDay) = nanmean(xgrasp(poDay==allDays(iDay)));
         Xretract(iDay) = nanmean(xretract(poDay==allDays(iDay)));
      end
      iStart = find(~isnan(Xpre),1,'first');
      iStop = find(~isnan(Xpre),1,'last');
      iQ = iStart:iStop;
      xq = allDays(iQ);
      if (min(xq) >= 10) || (max(xq) <= 21)
         Xpre = {[]};
         Xreach = {[]};
         Xgrasp = {[]};
         Xretract = {[]};
         return;
      end
      
      
      
%       y = Xpre(iQ);
%       iX = ~isnan(y);
%       y = y(iX);
%       x = xq(iX);
%       Xpre(iQ) = interp1(x,y,xq,'spline',0);
%       
%       y = Xreach(iQ);
%       iX = ~isnan(y);
%       y = y(iX);
%       x = xq(iX);
%       Xreach(iQ) = interp1(x,y,xq,'spline',0);
%       
%       y = Xgrasp(iQ);
%       iX = ~isnan(y);
%       y = y(iX);
%       x = xq(iX);
%       Xreach(iQ) = interp1(x,y,xq,'spline',0);
%       
%       y = Xretract(iQ);
%       iX = ~isnan(y);
%       y = y(iX);
%       x = xq(iX);
%       Xreach(iQ) = interp1(x,y,xq,'spline',0);
      
      iX = ~isnan(Xpre);
      y = Xpre(iX);
      x = allDays(iX);
      Xpre = max(interp1(x,y,allDays,'spline',0),0);
      
      iX = ~isnan(Xreach);
      y = Xreach(iX);
      x = allDays(iX);
      Xreach = max(interp1(x,y,allDays,'spline',0),0);
      
      iX = ~isnan(Xgrasp);
      y = Xgrasp(iX);
      x = allDays(iX);
      Xgrasp = max(interp1(x,y,allDays,'spline',0),0);
      
      iX = ~isnan(Xretract);
      y = Xretract(iX);
      x = allDays(iX);
      Xretract = max(interp1(x,y,allDays,'spline',0),0);

      Xpre = {Xpre};
      Xreach = {Xreach};
      Xgrasp = {Xgrasp};
      Xretract = {Xretract};
   end


end