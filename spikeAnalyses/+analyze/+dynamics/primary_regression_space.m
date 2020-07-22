function D = primary_regression_space(D)
%PRIMARY_REGRESSION_SPACE Classify fixed point in primary regression space of least-squares optimal regression matrix of top PCs
%
%  D = analyze.dynamics.primary_regression_space(D);
%
%  Uses the following rules for classification of linearized dynamics in 2-
%  or 3-D state spaces:
%    -----------------
%     2-D State Space
%    -----------------
%     * Saddle if:
%       - product of the eigenvalues is negative;
%     * Center (circles) if: 
%       - sum of the eigenvalues is zero;  
%     * If the eigenvalues are of the same sign, then estimate 
%        ```
%           tau = eig1 + eig2;
%           delta = eig1*eig2;
%           thresh = tau.^2 - 4*delta;
%        ```
%        + Unstable Node if:
%           - thresh < 0 and tau > 0;
%        + Unstable Spiral if:
%           - thresh > 0 and tau > 0;
%        + Stable Spiral if:
%           - thresh < 0 and tau > 0;
%        + Stable Node if:
%           - thresh < 0 and tau < 0;
%        + Degenerate Node if:
%           - thresh == 0, (A(2,1)~=0) || (A(1,2)~=0)
%        + Star Node if:
%           - thresh == 0, (A(2,1)==0) && (A(1,2)==0)
%
%  Textbook: 
%     Strogatz, Steven H. "Nonlinear dynamics and chaos." (1996).
%
%    -----------------
%     3-D State Space
%    -----------------
%      * Node if:
%        - all eigenvalues are real and negative; 
%      * Repellor if:
%        - all positive real eigenvalues; 
%      * Saddle Point (index 1) if:
%        - all real with one positive and others negatives; 
%      * Saddle Point (index 2) if: 
%        - all real with one negative and others positive; 
%      * Spiral Node if:
%        - one real and two complex conjugate but all negative real parts; 
%      * Spiral Repellor if: 
%        - one real and two complex conjugate but positive real parts; 
%      * Spiral Saddle (index 1) if:
%        - one positive real and the two others complex conjugate 
%          with negative real parts;
%      * Spiral Saddle (index 2) if:
%        - one negative real and the two others complex conjugate with 
%          positive real parts.
%
%  Source: 
%     https://www.physicsforums.com/threads/classification-of-fixed-points-of-n-dimensional-linear-dynamical-system.517582/
%        (Author: Bob Shandy)
%
%  Textbook:
%     Julien Clinton Sprott, Chaos and Time-Series Analysis, 
%        Oxford University Press Inc., New York 2003
%
% Inputs
%  D  - Table exported by analyze.jPCA.multi_jPCA or in file
%        defaults.files('multi_jpca_long_timescale_matfile');
%
% Output
%  D  - Same as input but with additional variables: 
%        * FP_Classification - Classification of fixed point in main space
%                                of least-squares optimal regression matrix
%        * FP_Dim            - Dimension of state-space for this point
%        * FP_Explained      - Amount of data explained by state-space
%        * FP_VarCapt        - Mean regression variance explained for
%                                each state-space dimension
%
% See also: analyze.dynamics, analyze.jPCA, analyze.jPCA.multi_jPCA

D.FP_Classification = strings(size(D,1),1);
D.FP_Dim = nan(size(D,1),1);
D.FP_Explained = nan(size(D,1),1);
D.FP_VarCapt = nan(size(D,1),1);

if size(D,1)>1
   for ii = 1:size(D,1)
      D(ii,:) = analyze.dynamics.primary_regression_space(D(ii,:));
   end
   return;
end
% Get relevant fields from cell struct element for this table row
A = D.Summary{1}.best.M;
lambda = D.Summary{1}.best.lambda;
vc = D.Summary{1}.SS.best.explained.varcapt;
expl = D.Summary{1}.SS.best.explained.eig;

% Sort by Eigenvalue
[~,iSort] = sort(abs(lambda),'descend');
lambda = lambda(iSort);
expl = expl(iSort);
A = A(:,iSort);
vc = vc(iSort);

% If top dimensions are plane, then only use plane; otherwise, use top-3
% dimensions in a 3D state-space, since typically second and third would
% form a plane with rotatory dynamics. However, do a check and if they are
% also not complex conjugates, then only return top-2 dimensions 
%  (Note: 7 of 116 recordings recover matrix `A` such that there are no
%         "rotatory" planar dynamics in the top-3 dimensions). 

if lambda(1) == conj(lambda(2))
   D.FP_Dim = 2;
else
   if lambda(2) == conj(lambda(3))
      D.FP_Dim = 3;
   else
      D.FP_Dim = 2;
   end
end
A = A(1:D.FP_Dim,1:D.FP_Dim);
lambda = lambda(1:D.FP_Dim);

D.FP_Explained = sum(expl(1:D.FP_Dim));
D.FP_VarCapt = nanmean(vc(1:D.FP_Dim));

switch D.FP_Dim
   case 2
      %     * Saddle Point if:
      %       - product of the eigenvalues is negative;
      %     * Center (circles) if: 
      %       - sum of the eigenvalues is zero;  
      %     * If the eigenvalues are of the same sign, then estimate 
      %        ```
      %           tau = eig1 + eig2; % or trace(A)
      %           delta = eig1*eig2; % or det(A)
      %           thresh = tau.^2 - 4*delta;
      %        ```
      %        + Unstable Node if:
      %           - thresh < 0 and tau > 0;
      %        + Unstable Spiral if:
      %           - thresh > 0 and tau > 0;
      %        + Stable Spiral if:
      %           - thresh < 0 and tau > 0;
      %        + Stable Node if:
      %           - thresh < 0 and tau < 0;
      %        + Degenerate Node if:
      %           - thresh == 0, (A(1,2) ~= 0) || (A(2,1)~=0)
      %        + Star Node if:
      %           - thresh == 0, (A(1,2) == 0) && (A(2,1)~=0)
      %        + Non-Isolated if:
      %           - tau == 0
              
      tau = trace(A);
      delta = det(A);
      thresh = tau.^2 - 4*delta;
      if delta < 0
         D.FP_Classification = "Saddle Point";
         return;
      end
      if delta == 0
         D.FP_Classification = "Center";
         return;
      end
      if tau == 0
         D.FP_Classification = "Non-Isolated";
         return;
      end
      
      if thresh < 0
         if tau > 0
            D.FP_Classification = "Unstable Spiral";
         elseif tau < 0
            D.FP_Classification = "Stable Spiral";            
         end
         return;
      elseif thresh > 0
         if tau > 0
            D.FP_Classification = "Unstable Node";
         elseif tau < 0
            D.FP_Classification = "Stable Node";
         end
         return;
      else
         if tau > 0
            if (A(1,2)==0) && (A(2,1)==0)
               D.FP_Classification = "Unstable Star Node";
            else
               D.FP_Classification = "Unstable Degenerate Node";
            end
         elseif tau < 0
            if (A(1,2)==0) && (A(2,1)==0)
               D.FP_Classification = "Stable Star Node";
            else
               D.FP_Classification = "Stable Degenerate Node";
            end
         end
         return;
      end
      % Shouldn't be possible to reach this part:
      D.FP_Classification = "Unknown"; %#ok<UNRCH>
   case 3
      %      * Node if:
      %        - all eigenvalues are real and negative; 
      %      * Repellor if:
      %        - all positive real eigenvalues; 
      %      * Saddle Point (index 1) if:
      %        - all real with one positive and others negatives; 
      %      * Saddle Point (index 2) if: 
      %        - all real with one negative and others positive; 
      %      * Spiral Node if:
      %        - one real and two complex conjugate but all negative real parts; 
      %      * Spiral Repellor if: 
      %        - one real and two complex conjugate but positive real parts; 
      %      * Spiral Saddle ( index 1) if:
      %        - one positive real and the two others complex conjugate 
      %          with negative real parts;
      %      * Spiral Saddle(index 2) if:
      %        - one negative real and the two others complex conjugate with 
      %          positive real parts.
      
      switch sum(imag(lambda)==0)
         case 3 % All real
            if all(lambda < 0) && all(imag(lambda)==0)
               D.FP_Classification = "Node";
               return;
            elseif all(lambda > 0)
               D.FP_Classification = "Repellor";
               return;
            elseif sum(lambda>0)==1
               D.FP_Classification = "Saddle Point (index 1)";
               return;
            elseif sum(lambda>0)==2
               D.FP_Classification = "Saddle Point (index 2)";
               return;
            else
               D.FP_Classification = "Unknown";
            end
         case 1 % Complex-conjugate pair, one real
            if all(real(lambda) < 0)
               D.FP_Classification = "Spiral Node";
               return;
            elseif all(real(lambda) > 0)
               D.FP_Classification = "Spiral Repellor";
               return;
            elseif lambda(imag(lambda)==0) > 0
               e = lambda(imag(lambda)~=0);
               if (e(1)==conj(e(2))) && all(real(e)<0)
                  D.FP_Classification = "Spiral Saddle Point (index 1)";
               else
                  D.FP_Classification = "Unknown";
               end
            elseif lambda(imag(lambda)==0) < 0
               e = lambda(imag(lambda)~=0);
               if (e(1)==conj(e(2))) && all(real(e)>0)
                  D.FP_Classification = "Spiral Saddle Point (index 2)";
               else
                  D.FP_Classification = "Unknown";
               end
            else
               D.FP_Classification = "Unknown";
            end
            return;
         otherwise % e.g. 3 complex values.. shouldn't happen
            D.FP_Classification = "Unknown";
      end 
end

end