function    [access, reuse, params, thruput] = os_ibm_flow(N, C, M, H, R, E, ~, alpha, J2, Q_byte, ~, WL, num_trials)

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

% x = [m, n, e]

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... (m + ne^2)CR^2 - Q
                                    ( C*R*R*(x(1) + x(2)*x(3)*x(3)) - Q ), ...
                                    [] ...
                                );
                            
num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * R^2 * alpha^2
                                    num_ifmap_values * ceil(M/x(1)) * R^2 * alpha^2 ...
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
                                    [M; N; E], ...              % upper bound of x
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
m                           =   x(1);
n                           =   x(2);
e                           =   x(3);

%% buffer level accesses optimization ------------------------------------------

% x = [p b l]
array_size_constraint       =   @(x) ...
                                deal ...
                                ( ... p * bl^2 - J^2
                                    ( x(1) * x(2) * x(3) * x(3) - J2 ), ...
                                    [] ...
                                );

num_buff_acc_func           =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * ceil(m/p) * R^2 * alpha^2 + num_weight * ceil(NE^2/ne^2) * ceil(ne^2/bl^2)
                                    num_ifmap_values * ceil(M/m) * ceil(m/x(1)) * R^2 * alpha^2 + ...
                                    num_weights * ceil(N*E^2/(n*e^2)) * ceil(n*e^2/(x(2)*x(3)^2)) ...
                                );

num_buff_acc                =   Inf;
x                           =   zeros(1, 3);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_buff_acc, ~]  = ...
                                ga ...
                                ( ...
                                    num_buff_acc_func, ...          % minimization target
                                    3, ...                          % number variables in x
                                    [], [], ...                     % linear inequality constraints
                                    [], [], ...                     % blank
                                    [1; 1; 1], ...                  % lower bound of x
                                    [m; n; e], ...                  % upper bound of x
                                    array_size_constraint, ...      % non-linear constraints
                                    [1 2 3], ...                    % integer constraints
                                    ga_opts ...                     % ga options
                                );
    if curr_buff_acc < num_buff_acc
        num_buff_acc        =   curr_buff_acc;
        x                   =   curr_x;
    end
end
                            
% get optimization results
p                           =   x(1);
b                           =   x(2);
l                           =   x(3);

%% output ----------------------------------------------------------------------

% params
params.m                    =   m;
params.n                    =   n;
params.e                    =   e;
params.p                    =   p;
params.b                    =   b;
params.l                    =   l;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * R^2 * alpha^2;
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   ceil(m/p);
reuse.buffer.weight         =   ceil(N*E^2/(b*l^2));

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   p;
reuse.array.weight          =   b*l^2;

reuse.reg.ofmap             =   C*R^2;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads         =   num_ifmap_values * ceil(M/m) * R^2 * alpha^2 + ...
                                num_weights;
access.memory.writes        =   num_ofmap_values;
access.buffer.reads         =   num_ifmap_values * ceil(M/p) * R^2 * alpha^2 + ...
                                num_weights * ceil(N*E^2/(b*l^2));
access.buffer.writes        =   0;
access.array.wiring         =   num_ifmap_values * M * R^2 * alpha^2 + ...
                                num_weights * N * E^2;
access.reg.reads            =   num_ofmap_values * ( C*R^2 - 1 );
access.reg.writes           =   num_ofmap_values * ( C*R^2 - 1 );

% thruput
thruput.active_pes          =   p*b*l^2;
thruput.active_pe_percent   =   thruput.active_pes/J2;

end