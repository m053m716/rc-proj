function fig = plotPCAreconstruction(xPC,nChannels)
%% PLOTPCARECONSTRUCTION   fig = utils.plotPCAreconstruction(xPC);
%
%  fig = utils.plotPCAreconstruction(xPC,nChannels);
%
% xPC: Struct returned by xPCA method of GROUP class object.
%
% nChannels: (Optional; default = 3) Number of channel traces to
%              superimpose.
%
% fig: Handle to diagnostic figure output
%
% By: Max Murphy  v1.0  2019-10-30  Original verison (R2017a)

%% Parse input
if nargin < 2
   nChannels = 3;
else
   % Make sure that it is small enough
   if nChannels > size(xPC.X,2)
      fprintf(1,'Too many channels requested (%g).\n',nChannels);
      fprintf(1,'Reducing nChannels to include all channels (%g).\n',size(xPC.X,2));
      nChannels = size(xPC.X,2);
   end
end

%% Make figure
fig = figure('Name','PCA Reconstruction Diagnostic',...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.3 0.3 0.3 0.5]);

%% Get random channel subset and plot
chIdx = randi(size(xPC.X,2),1,nChannels);

subplot(3,1,1); 
plot(xPC.t,xPC.X(:,chIdx)); 
title('Original'); 

subplot(3,1,2); 
plot(xPC.t,xPC.xbar(:,chIdx)); 
title('Reconstruction','FontName','Arial','Color','k','FontSize',14); 

subplot(3,1,3); 
plot(xPC.t,xPC.xbar_red(:,chIdx)); 
title('Reduced Reconstruction','FontName','Arial','Color','k','FontSize',14); 

end