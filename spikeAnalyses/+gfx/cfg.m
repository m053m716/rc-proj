function varargout = cfg(varargin)
%% CFG  param = gfx.cfg('param_name'); 
%
%  param = gfx.CFG('ParamName');
%  [param1,param2,...] = gfx.CFG('ParamName1','ParamName2',...);
%  paramStruct = gfx.CFG();
%
% Configure parameters for +gfx package here.

%% CHANGE CONFIGURATION HERE
p = struct;
p.ShadedError_Marker = 'none';
p.ShadedError_LineWidth = 2;
p.ShadedError_Color = 'k';
p.ShadedError_FaceColor = [0.2 0.2 0.2];
p.ShadedError_FaceAlpha = 0.3;
p.ShadedError_DisplayName = 'Data';
p.ShadedError_UserData = [];

p.SignificanceLine_LineWidth = 2.5;
p.SignificanceLine_Color = 'k';
p.SignificanceLine_HighVal = 0.9;
p.SignificanceLine_LowVal = 0.875;
p.SignificanceLine_MinDiffScale = 0.1; % Scalar for min diff (for adding end of bracket)

%% Return variable output (DO NOT CHANGE)
if nargin < 1
   varargout = {p};
else
   varargout = cell(size(varargin));
   for i = 1:numel(varargin)
      varargout{i} = utils.getParamField(p,varargin{i});
   end   
end

end