function fig = plotBasicChannelRateInfo(stats,xName,yName,zName,groupBy)
%% PLOTBASICCHANNELRATEINFO   Plot basic info about rate stats
%
%  fig = PLOTBASICCHANNELRATEINFO(stats);
%
%  --------
%   INPUTS
%  --------
%    stats     :     Table returned by GETCHANNELWISERATESTATS method
%                       called on GROUP class object.
%
% By: Max Murphy  v1.0  2019-06-21  Original version (R2017a)

%%
if nargin < 5
   groupBy = 'Group';
end

if nargin < 4
   zName = 'varRate';
end

if nargin < 3
   yName = 'maxRate';
end

if nargin < 2
   xName = 'tMaxRate';
end

s = screenStats(stats);

fig = figure('Name','Basic Channel-wise Rate Stats',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'Color','w');

if iscell(groupBy)
   doMultiAlign = true;
   u = cell(size(groupBy));
   for ii = 1:numel(groupBy)
      u{ii} = unique(s.(groupBy{ii}));
   end
else
   doMultiAlign = false;
   u = unique(s.(groupBy));
end


if doMultiAlign
   legText = [];
   vec = cellfun(@numel,u);
   htmp = redgreencmap(prod(vec));
   switch numel(vec)
      
      case 2
         iU = 0;
         for i1 = 1:vec(1)
            for i2 = 1:vec(2)
               iU = iU + 1;
               idx = find(ismember(s.(groupBy{1}),u{1}(i1)) & ...
                          ismember(s.(groupBy{2}),u{2}(i2)));

               if isempty(idx)
                  continue;
               end

               scatter3(...
                     s.(xName)(idx,:),...
                     s.(yName)(idx,:),...
                     s.(zName)(idx,:),...
                     s.PostOpDay(idx)*2,'filled','k',...
                     'MarkerFaceColor',htmp(iU,:),...
                     'MarkerEdgeColor','none',...
                     'Marker','o'); 
               hold on;

               if iscell(u{1}) && iscell(u{2})
                  legText = [legText; {sprintf('%s-%s-%s-%s',groupBy{1},u{1}{i1},groupBy{2},u{2}{i2})}]; %#ok<*AGROW>
               elseif iscell(u{1})
                  legText = [legText; {sprintf('%s-%g-%s-%s',groupBy{1},u{1}(i1),groupBy{2},u{2}{i2})}];
               elseif iscell(u{2})
                  legText = [legText; {sprintf('%s-%s-%s-%g',groupBy{1},u{1}{i1},groupBy{2},u{2}(i2))}];
               else
                  legText = [legText; {sprintf('%s-%g-%s-%g',groupBy{1},u{1}(i1),groupBy{2},u{2}(i2))}];
               end
            end
         end
      case 3
         iU = 0;
         for i1 = 1:vec(1)
            for i2 = 1:vec(2)
               for i3 = 1:vec(3)
                  iU = iU + 1;
                  idx = find(ismember(s.(groupBy{1}),u{1}(i1)) & ...
                             ismember(s.(groupBy{2}),u{2}(i2)) & ...
                             ismember(s.(groupBy{3}),u{3}(i3)));

                  if isempty(idx)
                     continue;
                  end

                  scatter3(...
                        s.(xName)(idx,:),...
                        s.(yName)(idx,:),...
                        s.(zName)(idx,:),...
                        s.PostOpDay(idx)*2,'filled','k',...
                        'MarkerFaceColor',htmp(iU,:),...
                        'MarkerEdgeColor','none',...
                        'Marker','o'); 
                  hold on;

                  if iscell(u{1}) && iscell(u{2}) && iscell(u{3})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}{i1},groupBy{2},u{2}{i2},groupBy{3},u{3}{i3})}]; 
                  elseif iscell(u{1}) && iscell(u{2})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}{i1},groupBy{2},u{2}{i2},groupBy{3},u{3}(i3))}]; 
                  elseif iscell(u{2}) && iscell(u{3})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}(i1),groupBy{2},u{2}{i2},groupBy{3},u{3}{i3})}]; 
                  elseif iscell(u{1}) && iscell(u{3})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}{i1},groupBy{2},u{2}(i2),groupBy{3},u{3}{i3})}]; 
                  elseif iscell(u{1})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}{i1},groupBy{2},u{2}(i2),groupBy{3},u{3}(i3))}]; 
                  elseif iscell(u{2})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}(i1),groupBy{2},u{2}{i2},groupBy{3},u{3}(i3))}]; 
                  elseif iscell(u{3})
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}(i1),groupBy{2},u{2}(i2),groupBy{3},u{3}{i3})}]; 
                  else
                     legText = [legText; {sprintf('%s-%s-%s-%s-%s-%s',groupBy{1},u{1}(i1),groupBy{2},u{2}(i2),groupBy{3},u{3}(i3))}]; 
                  end
                  
               end
            end
         end         
      otherwise
         error('Max. 3 alignments.');
   end

else
   htmp = flipud(redgreencmap(numel(u)));
   legText = [];
   for iU = 1:numel(u)
      if iscell(u)
         idx = find(ismember(s.(groupBy),u{iU}));
      else
         idx = find(ismember(s.(groupBy),u(iU)));
      end
      if isempty(idx)
         continue;
      end

      scatter3(...
            s.(xName)(idx,:),...
            s.(yName)(idx,:),...
            s.(zName)(idx,:),...
            s.PostOpDay(idx)*2,'filled','k',...
            'MarkerFaceColor',htmp(iU,:),...
            'MarkerEdgeColor','none',...
            'Marker','o'); 
      hold on;

      if iscell(u)
         legText = [legText; {sprintf('%s-%s',groupBy,u{iU})}];
      else
         legText = [legText; {sprintf('%s-%g',groupBy,u(iU))}];
      end
   end

end
xlabel(xName); 
ylabel(yName); 
zlabel(zName);
legend(legText);



end