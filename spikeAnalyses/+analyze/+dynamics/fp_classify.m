function classification = fp_classify(dim,A,lambda)
%FP_CLASSIFY Classify fixed-point for row of table D
%
%  classification = analyze.dynamics.fp_classify(dim,A,lambda);
%
% Inputs
%  dim    - System dimension (2 or 3)
%  A      - Matrix of coefficients for linearized system
%  lambda - Eigenvalues of `A`
%
% Output
%  classification - String: classification based on inputs
%
% See also: analyze.dynamics, analyze.dynamics.primary_regression_space


switch dim
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
         classification = "Saddle Point";
         return;
      end
      if delta == 0
         classification = "Center";
         return;
      end
      if tau == 0
         classification = "Non-Isolated (Plane of Fixed Points)";
         return;
      end
      
      if thresh < 0
         if tau > 0
            classification = "Unstable Spiral";
         elseif tau < 0
            classification = "Stable Spiral";            
         end
         return;
      elseif thresh > 0
         if tau > 0
            classification = "Unstable Node";
         elseif tau < 0
            classification = "Stable Node";
         end
         return;
      else
         if tau > 0
            if (A(1,2)==0) && (A(2,1)==0)
               classification = "Unstable Star Node";
            else
               classification = "Unstable Degenerate Node";
            end
         elseif tau < 0
            if (A(1,2)==0) && (A(2,1)==0)
               classification = "Stable Star Node";
            else
               classification = "Stable Degenerate Node";
            end
         end
         return;
      end
      % Shouldn't be possible to reach this part:
      classification = "Unknown"; %#ok<UNRCH>
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
               classification = "Node";
               return;
            elseif all(lambda > 0)
               classification = "Repellor";
               return;
            elseif sum(lambda>0)==1
               classification = "Saddle Point (index 1)";
               return;
            elseif sum(lambda>0)==2
               classification = "Saddle Point (index 2)";
               return;
            else
               classification = "Unknown";
            end
         case 1 % Complex-conjugate pair, one real
            if all(real(lambda) < 0)
               classification = "Spiral Node";
               return;
            elseif all(real(lambda) > 0)
               classification = "Spiral Repellor";
               return;
            elseif lambda(imag(lambda)==0) > 0
               e = lambda(imag(lambda)~=0);
               if (e(1)==conj(e(2))) && all(real(e)<0)
                  classification = "Spiral Saddle Point (index 1)";
               else
                  classification = "Unknown";
               end
            elseif lambda(imag(lambda)==0) < 0
               e = lambda(imag(lambda)~=0);
               if (e(1)==conj(e(2))) && all(real(e)>0)
                  classification = "Spiral Saddle Point (index 2)";
               else
                  classification = "Unknown";
               end
            else
               classification = "Unknown";
            end
            return;
         otherwise % e.g. 3 complex values.. shouldn't happen
            classification = "Unknown";
      end 
end
end