function [c,ceq] = nonlinear_constraint(p)
%NONLINEAR_CONSTRAINT Nonlinear constraint(s) on parameter array p
%
%  [c,ceq] = analyze.stat.nonlinear_constraint(p);
%
% Inputs
%  p   - Array for `fmincon` that is [`tau`,`sigma`,`omega`];
%
% Output
%  c   - Array where c <= 0 always in order to meet constraint
%  ceq - Array where c == 0 always in order to meet constraint

c = p(2) * p(3) - 8; % Must always be below 8-Hz (Nyquist frequency)
ceq = 0;
end