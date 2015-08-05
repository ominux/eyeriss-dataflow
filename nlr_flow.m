function    [access, reuse, params, thruput] = nlr_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, ~, WL, num_trials)
   
%% num data --------------------------------------------------------------------

% total number ifmap values
num_ifmap_values            =   N * C * H^2;
% total number weights
num_weights                 =   M * C * R^2;
% total number ofmap values
num_ofmap_values            =   N * M * E^2;

%% memory size -----------------------------------------------------------------

% buffer size [in words]
Q                           =   floor(Q_byte / WL);
% register size [in words]
% G                           =   floor(G_byte / WL);

%% memory level accesses optimization ------------------------------------------

% x = [n p e]

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... pqR^2 + nqh^2 + pne^2 - Q
                                    ( x(2)*floor(J2/x(2))*R*R + x(1)*floor(J2/x(2))*(U*x(3)+R-U)^2 + x(2)*x(1)*x(3)*x(3) - Q ), ...
                                    [] ...
                                );

num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/p) * (alpha/beta)^2 + num_weights * ceil(N/n)*ceil(E/e)^2
                                    num_ifmap_values * ceil(M/x(2)) * ( alpha / (x(3)/(U*x(3)+R-U)) )^2 + ...
                                    num_weights * ceil(N/x(1)) * ceil(E/x(3))^2 ...
                                );
                            
num_mem_reads               =   Inf;
x                           =   zeros(1, 3);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_mem_reads, ~] = ...
                                ga ...
                                ( ...
                                    num_mem_reads_func, ...  % minimization target
                                    3, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1], ...              % lower bound of x
                                    [N; min([M J2]); E], ...    % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2 3], ...                % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_mem_reads < num_mem_reads
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    end
end

% get optimization results
n                           =   x(1);
p                           =   x(2);
e                           =   x(3);
q                           =   min([floor(J2/p) C]);
h                           =   U*e + R - U;
beta                        =   e/h;

%% outputs ---------------------------------------------------------------------

% parameters
params.n                    =   n;
params.p                    =   p;
params.e                    =   e;
params.q                    =   q;
params.h                    =   h;
params.beta                 =   beta;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/p) * (alpha/beta)^2;
reuse.memory.weight         =   ceil(N/n) * ceil(E/e)^2;

reuse.buffer.ofmap          =   ceil(C/q) * R^2;
reuse.buffer.ifmap          =   R^2 * beta^2;
reuse.buffer.weight         =   n*e^2;

reuse.array.ofmap           =   q;
reuse.array.ifmap           =   p;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   1;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;

% access
access.memory.reads         =   num_ifmap_values * ceil(M/p) * (alpha/beta)^2   + ...
                                num_weights * ceil(N/n) * ceil(E/e)^2;
access.memory.writes        =   num_ofmap_values;
access.buffer.reads         =   num_ifmap_values * ceil(M/p) * R^2 * alpha^2    + ...
                                num_weights * N * E^2                           + ...
                                num_ofmap_values * ( ceil(C/q)*R^2 - 1 );
access.buffer.writes        =   num_ofmap_values * ( ceil(C/q)*R^2 - 1 );
access.array.wiring         =   num_ifmap_values * M * R^2 * alpha^2            + ...
                                num_ofmap_values * ( C*R^2 - ceil(C/q)*R^2 );
access.reg.reads            =   0;
access.reg.writes           =   0;

% thruput
thruput.active_pes          =   p*q;
thruput.active_pe_percent   =   thruput.active_pes/J2;

end










