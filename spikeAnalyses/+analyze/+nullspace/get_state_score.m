function b = get_state_score(TID,D,nComponent)
%GET_STATE_SCORE  Returns PC "Score" vector for TID, which has .State var
%
%  b = analyze.nullspace.get_state_score(TID,Coeff,nComponent);
%
%  -- Inputs --
%  TID : Returned by `TID = analyze.nullspace.get.on_event(X,'event');`
%
%  D : Returned by `D = analyze.nullspace.sample.grasp(X);`

b0 = TID.State;
A = D.Coeff;
b_hat = b0 - D.Mu;
b = (b_hat \ A)';

if nargin > 2
   b = b(1:nComponent);
end

end