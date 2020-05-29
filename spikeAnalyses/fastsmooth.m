function Y=fastsmooth(X,N,varargin)
%FASTSMOOTH Method for smoothing data
%% FASTSMOOTH    Smooths vector X
%
%   Y = FASTSMOOTH(X,N)
%
%   Y = FASTSMOOTH(X,N,Type)
%
%   Y = FASTSMOOTH(X,N,Type,Ends)
%
%   Y = FASTSMOOTH(X,N,Type,Ends,Dim)
%
%	Example:
%   fastsmooth([1 1 1 10 10 10 1 1 1 1],3)= [0 1 4 7 10 7 4 1 1 0]
%   fastsmooth([1 1 1 10 10 10 1 1 1 1],3,1,1)= [1 1 4 7 10 7 4 1 1 1]
%
%   --------
%    INPUTS
%   --------
%      X        :       Vector with > N elements.
%
%      N        :       Window length (scalar, integer) for smoothing.
%                       Given as number of indices to smooth over.
%
%     Type      :       (Optional) Determines smooth type:
%                       - 'abs_med' (sliding-absolute-median)
%                       - 'med'  (sliding-median)
%                       - 'rect' (sliding-average/boxcar)
%                       - 'tri'  (def; 2-passes of sliding-average (f/b))
%                       - 'pg'   (4-passes of sliding-average (f/b/f/b))
%
%     Ends      :       (Optional) Controls the "ends" of the signal.
%                       (First N/2 points and last N/2 points).
%                       - 0 (sets ends to zero; fastest)
%                       - 1 (def; progressively smooths ends with shorter
%                            widths. can take a long time for long windows)
%
%     Dim      :        (Optional) If submitting a matrix, specifies
%                                   dimension to smooth (default: smooth 
%                                   dimensions with largest size). 
%                                   Specify as 1 to smooth rows.
%                                   Specify as 2 to smooth columns.
%
%   --------
%    OUTPUT
%   --------
%      Y        :       Smoothed (low-pass filtered) version of X. Degree
%                       of smoothing depends mostly on window length, and
%                       slightly on window type.
%
% Original version by: T. C. O'Haver, May, 2008. (v2.0)
%
% Adapted by: Max Murphy 10/11/2018 v5.0 Change so that 'tri' and 'pg'
%                                        attempt to mitigate phase offset
%                                        by alternating forward and reverse
%                                        sweeps. 'pg' changed to 4 sweeps.
%                        06/30/2018 v4.1 Added recursion to handle matrix
%                                        arrays.
%                        03/22/2018 v4.0 Added recursion to make it handle
%                                        cell arrays.
%                        03/14/2017 v3.0 Added argument parsing, changed
%                                        defaults, added documentation and
%                                        changed variable names for
%                                        clarity. (Matlab R2016b)
%                        12/28/2017 v3.1 Added "median" smoothing.

%% DEFAULTS
DEF_TYPE = 'tri';
DEF_ENDS = 1;
[~,DEF_DIM] = min(size(X)); % use "min" since it smoothes along that dim

TYPE_OPTS = {'med', 'abs_med', 'tri', 'rect', 'pg', 'gauss'};

%% VALIDATION FUNCTIONS
validateX = @(input) validateattributes(input,{'numeric','cell'},...
                        {'nonsparse','nonempty'},...
                        mfilename,'X');
                 
validateN = @(input) validateattributes(input, ...
                        {'numeric'}, ...
                        {'scalar','positive','integer'},...
                        mfilename,'N');
                 
validateType = @(input) any(validatestring(input,TYPE_OPTS));

validateEnds = @(input) isnumeric(input) && ...
                           isscalar(input) && ...
                           ((abs(input)<eps)||abs(input-1)<eps);

validateDim = @(input) isnumeric(input) && ...
                           isscalar(input) && ...
                           ((abs(input-1)<eps)||abs(input-2)<eps);
%% CHECK ARGUMENTS
p = inputParser;

addRequired(p,'X',validateX);
addRequired(p,'N',validateN);
addOptional(p,'Type',DEF_TYPE,validateType);
addOptional(p,'Ends',DEF_ENDS,validateEnds);
addOptional(p,'Dim',DEF_DIM,validateDim);

parse(p,X,N,varargin{:});

Type = p.Results.Type;
Ends = p.Results.Ends;
Dim = p.Results.Dim;

%% USE RECURSION IF X IS PASSED AS A CELL
if iscell(X)
   [d1,d2] = size(X);
   Y = cell(d1,d2);
   for i1 = 1:d1
      for i2 = 1:d2
         Y{i1,i2} = fastsmooth(X{i1,i2},N,Type,Ends);
      end
   end
   return;
elseif (size(X,1) > 1) && (size(X,2) > 1)
   
   [d1,d2] = size(X);
   Y = nan(d1,d2);
   switch Dim
      case 1
         for ii = 1:d1
            Y(ii,:) = fastsmooth(X(ii,:),N,Type,Ends);
         end
      case 2
         for ii = 1:d2
            Y(:,ii) = fastsmooth(X(:,ii),N,Type,Ends);
         end
   end
   return;
end

%% RUN DIFFERENT SUBFUNCTION DEPENDING ON SMOOTHING KERNEL FUNCTION
switch Type
   case 'abs_med'
      Y=med_smoother(abs(X),N,Ends);
   case 'med'
      Y=med_smoother(X,N,Ends);
   case 'rect'
      Y=smoother(X,N,Ends); % 1 - forward
   case 'tri'
      Y= rev_smoother(...             % 2 - back
         smoother(X,N,Ends),N,Ends);  % 1 - forward
   case {'pg', 'gauss'}
      Y=rev_smoother(...                             % 4 - back
         smoother(...                                % 3 - forward
         rev_smoother(...                            % 2 - back
         smoother(X,N,Ends),N,Ends),N,Ends),N,Ends); % 1 - forward
end

%% IMPLEMENT SMOOTHING
   function y=smoother(x,n,ends)
      % Actually implements the smoothing   
      SumPoints=nansum(x(1:n));
      s=zeros(size(x));
      halfw=round(n/2);
      L=numel(x);
      for k=1:L-n
        s(k+halfw-1)=SumPoints;
        SumPoints=nansum([SumPoints,-x(k)]);
        SumPoints=nansum([SumPoints,x(k+n)]);
      end
      s(k+halfw)=SumPoints; % So loop doesn't break
      y=s./n;

      % Taper the ends of the signal if ends=1.
      if ends==1
        startpoint=(n + 1)/2;
        y(1)=(x(1)+x(2))./2;
        for k=2:startpoint
            y(k)=nanmean(x(1:(2*k-1)));
            y(L-k+1)=nanmean(x(L-2*k+2:L));
        end
        y(L)=(x(L)+x(L-1))./2;
      end

   end

   % Function for "reverse" sliding average smoothing
   function y=rev_smoother(x,n,ends)
      % Actually implements the smoothing   
      SumPoints=nansum(x(end:-1:(end-n+1)));
      s=zeros(size(x));
      halfw=round(n/2);
      L=numel(x);
      for k=L:-1:(n+1)
        s(k-halfw+1)=SumPoints;
        SumPoints=nansum([SumPoints,-x(k)]);
        SumPoints=nansum([SumPoints,x(k-n)]);
      end
      s(k-halfw)=SumPoints; % So loop doesn't break
      y=s./n;

      % Taper the ends of the signal if ends=1.
      if ends==1
        startpoint=(n + 1)/2;
        y(1)=(x(1)+x(2))./2;
        for k=2:startpoint
            y(k)=nanmean(x(1:(2*k-1)));
            y(L-k+1)=nanmean(x(L-2*k+2:L));
        end
        y(L)=(x(L)+x(L-1))./2;
      end

   end
 
   function y=med_smoother(x,n,ends)
      % Actually implements the smoothing   
      y=zeros(size(x));
      halfw=round(n/2);
      L=numel(x);
      for k=1:L-n
        y(k+halfw-1)=nanmedian(x(k:(k+n)));
      end

      % Taper the ends of the signal if ends=1.
      if ends==1
        startpoint=(n + 1)/2;
        y(1)=(x(1)+x(2))./2;
        for k=2:startpoint
            y(k)=nanmedian(x(1:(2*k-1)));
            y(L-k+1)=nanmedian(x(L-2*k+2:L));
        end
        y(L)=(x(L)+x(L-1))./2;
      end
    
    end

end
