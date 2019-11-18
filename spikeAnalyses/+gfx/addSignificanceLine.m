function l = addSignificanceLine(x,y,h0,alpha,varargin)
%% ADDSIGNIFICANCELINE  l = gfx.addSignificanceLine(x,y,h0,alpha);
%
%
%  l = gfx.ADDSIGNIFICANCELINE(x,y,h0,alpha);
%  l = gfx.ADDSIGNIFICANCELINE(ax,...); % Add to an axes
%  l = gfx.ADDSIGNIFICANCELINE(___,'Name',value,...);
%
%  Returns handle to hggroup object containing all line segments used to
%  add "significance" result of two-way ttest at each point specified in x
%  (some indexing vector, such as time for a time-series) testing the
%  corresponding elements of 'y' against the same corresponding elements in
%  'h0'. 

%% PARSE INPUTS
if nargin < 4
   error('No argument parsing for too few inputs (yet).');
end

if isa(x,'matlab.graphics.axis.Axes')
   if nargin < 5
      error('If Axes is first argument, then needs 5 inputs at least.');
   end 
   % Shuffle everything to match
   ax = x;
   x = y;
   y = h0;
   h0 = alpha;
   alpha = varargin{1};
   varargin(1) = [];
else
   ax = gca;
end

%% PARSE PARAMS
CFG_KEY = 'SignificanceLine_';
p = utils.parseParams(CFG_KEY,varargin);

%% RESHAPE INPUTS
x = reshape(x,numel(x),1); % column vector
if size(h0,1)~=size(x,1)
   h0 = h0.';
   if size(h0,1)~=size(x,1)
      error('Dimension mismatch between h0 and x. Check inputs.');
   end
end

if size(y,1)~=size(x,1)
   y = y.';
   if size(y,1)~=size(x,1)
      error('Dimension mismatch between h0 and x. Check inputs.');
   end
end

%%
startFlag = true;
endFlag = false;

% Append whether it was significant or not using a line above the
% plot
l = hggroup(ax,...
   'DisplayName',sprintf('Significant (\alpha = %g)',alpha));
d = min(diff(x)) * p.SignificanceLine_MinDiffScale;

yl = ax.YLim;
highPt = yl(2) * p.SignificanceLine_HighVal;
lowPt = (yl(2) - yl(1)) * p.SignificanceLine_LowVal + yl(1);

for i = 1:numel(x) 
   if iscell(h0)
      a = h0{i};
   else
      a = h0(i,:);
   end
   
   if iscell(y)
      b = y{i};
   else
      b = y(i,:);
   end
   
   if ttest2(a,b,'Alpha',alpha,'Vartype','unequal')
      if startFlag
         line([x(i),x(i),x(i)+d],[lowPt highPt highPt],...
            'Color',p.SignificanceLine_Color,...
            'LineWidth',p.SignificanceLine_LineWidth,...
            'Parent',l);
         startFlag = false;
         endFlag = true;
      else
         line([x(i-1)+d,x(i)+d],[highPt highPt],...
            'Color',p.SignificanceLine_Color,...
            'LineWidth',p.SignificanceLine_LineWidth,...
            'Parent',l);
      end
   else
      if endFlag
         line([x(i-1)+d,x(i-1)+d],[highPt lowPt],...
            'Color',p.SignificanceLine_Color,...
            'LineWidth',p.SignificanceLine_LineWidth,...
            'Parent',l);
         startFlag = true;
         endFlag = false;
      end
   end
end

% Add end flag
line([x(i),x(i)],[highPt lowPt],...
            'Color',p.SignificanceLine_Color,...
            'LineWidth',p.SignificanceLine_LineWidth,...
            'Parent',l);