function    [access, reuse, params] = os_sdn_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, ~, WL, num_trials)

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

% x = [m, n, e, k]

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... mkR^2 + nkh^2 + nme^2 - Q
                                    ( x(1)*x(4)*R^2 + x(2)*x(4)*(U*x(3)+R-U)^2 + x(1)*x(2)*x(3)^2 - Q ), ...
                                    [] ...
                                );
                            
num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * (alpha/beta)^2 + num_weights * ceil(N/n) * ceil(E/e)^2
                                    num_ifmap_values * ceil(M/x(1)) * (alpha/(x(3)/(U*x(3)+R-U)))^2 + ...
                                    num_weights * ceil(N/x(2)) * ceil(E/x(3))^2 ...
                                );

num_mem_reads               =   Inf;
x                           =   zeros(1, 4);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_mem_reads, ~] = ...
                                ga ...
                                ( ...
                                    num_mem_reads_func, ...  % minimization target
                                    4, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1; 1], ...           % lower bound of x
                                    [M; N; E; C], ...           % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2 3 4], ...              % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_mem_reads < num_mem_reads
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    end
end

% get optimization results
m                           =   x(1);
n                           =   x(2);
e                           =   x(3);
k                           =   x(4);
h                           =   U*e + R - U;
beta                        =   e/h;
l                           =   min([e floor(sqrt(J2))]);
w                           =   U*l + R - U;
gamma                       =   l/w;

%% output ----------------------------------------------------------------------

% parameters
params.m                    =   m;
params.n                    =   n;
params.e                    =   e;
params.k                    =   k;
params.h                    =   h;
params.w                    =   w;
params.l                    =   l;
params.beta                 =   beta;
params.gamma                =   gamma;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta)^2;
reuse.memory.weight         =   ceil(N/n) * ceil(E/e)^2;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   m * (beta/gamma)^2;
reuse.buffer.weight         =   n * ceil(e/l)^2;

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   R^2 * gamma^2;
reuse.array.weight          =   l^2;

reuse.reg.ofmap             =   C*R^2;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads         =   num_ifmap_values * ceil(M/m) * (alpha/beta)^2   + ...
                                num_weights * ceil(N/n) * ceil(E/e)^2;
access.memory.writes        =   num_ofmap_values;
access.buffer.reads         =   num_ifmap_values * M * (alpha/gamma)^2          + ...
                                num_weights * N * ceil(E/l)^2;
access.buffer.writes        =   0;
access.array.wiring         =   num_ifmap_values * M * alpha^2 * R^2            + ...
                                num_weights * N * E^2;
access.reg.reads            =   num_ofmap_values * ( C*R^2 - 1 );
access.reg.writes           =   num_ofmap_values * ( C*R^2 - 1 );

end
