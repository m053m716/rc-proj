function fig = view_h0(h0)
%VIEW_H0  Make figures showing h0 for each row of h0
%
%  fig = analyze.nnm.view_h0(h0);
%
%  -- Inputs --
%  h0 : Table returned by `h0 = analyze.nnm.get_init_factors(T)`
%
%  -- Output --
%  fig : Figure handle or array of figure handles (depending on how many
%           rows of h0)

if size(h0,1) > 1
   fig = [];
   for i = 1:size(h0,1)
      fig = [fig; analyze.nnm.view_h0(h0(i,:))]; %#ok<AGROW>
   end
   return;
end

H = h0.H{1};
nFactor = size(H,1);
t = h0.Properties.UserData.t(h0.Properties.UserData.t_mask);

str = sprintf('%s - Successes',char(h0.Alignment));
ox = randn(1)*0.05;
oy = randn(1)*0.05;
fig = figure('Name',sprintf('h0: %s',str),...
   'Units','Normalized',...
   'NumberTitle','off',...
   'Color','w',...
   'Position',[0.2+ox,0.2+oy,0.4,0.4]);
nRow = floor(sqrt(nFactor));
nCol = ceil(nFactor/nRow);

for i = 1:nFactor
   subplot(nRow,nCol,i);
   plot(t,H(i,:),'Color','k','LineWidth',2);
   xlim([t(1) t(end)]);
   ylim([0 1]);
   title(sprintf('Factor-%02g',i));
end
suptitle(str);

end