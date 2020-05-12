function showHideMetadata(src,~)
%SHOWHIDEMETADATA  Show or hide metadata associated with a scatter point
%
%  cb.showHideMetadata(src,~)
%
%  --------
%   INPUTS
%  --------
%     src      :     Object for which this function is set as
%                       'ButtonDownFcn' property. example:
%                       scatter3(x,y,z,'ButtonDownFcn',...
%							@cb.showHideMetadata);
%
%  --------
%   OUTPUT
%  --------
%	 none

srcProps = src.UserData;
if srcProps.isHighlighted
   clc;
   src.MarkerFaceColor = srcProps.origColor;
   src.MarkerEdgeColor = 'none';
   src.SizeData = 20;
else
   src.MarkerFaceColor = 'b';
   src.MarkerEdgeColor = 'c';
   src.SizeData = 72;
   disp(srcProps.metadata);
end
src.UserData.isHighlighted = ~srcProps.isHighlighted;
end