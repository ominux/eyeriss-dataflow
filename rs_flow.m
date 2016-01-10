function    [access, reuse, params, thruput] = rs_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials)

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
G                           =   floor(G_byte / WL);

%% memory level accesses optimization ------------------------------------------

% x = [m n k e]

e_max                       =   min([E floor(J2/R)]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... % mnEe + nkHh - Q, h = Ue+R-U
                                    ( x(1)*x(2)*E*x(4) + x(2)*x(3)*H*(U*x(4)+R-U) - Q ), ...
                                    [] ...
                                );

num_mem_reads_func          =   @(x) ... % num_weights * ceil(N/n)ceil(E/e) + num_inputs * ceil(M/m)*(alpha/beta), beta = e/h
                                ( ...
                                    num_weights * ceil(E/x(4)) * ceil(N/x(2)) + ...
                                    num_ifmap_values * ceil(M/x(1)) * ( alpha / (x(4)/(U*x(4)+R-U)) ) ...
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
                                    [M; N; C; e_max], ...       % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2 3 4], ...              % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_mem_reads <= num_mem_reads * 0.95
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    elseif curr_mem_reads <= num_mem_reads
        if prod(curr_x) > prod(x)
            x               =   curr_x;
        end
    end
end
                                
% get optimization results
m                           =   x(1);
n                           =   x(2);
k                           =   x(3);
e                           =   x(4);
h                           =   U*e + R - U;
beta                        =   e/h;

% hack begins
% m = 64;
% n = 4;
% k = 6;
% e = 13;
% h = U*e + R - U;
% beta =   e/h;
% hack ends

%% buffer level accesses optimization ------------------------------------------

% x = [p q r]
register_size_constraint    =   @(x) ...
                                deal ...
                                ( ... pqR + qR + p - G
                                    ( x(1)*x(2)*R + x(2)*R + x(1) - G ), ...
                                    [] ...
                                );

num_buff_acc_func           =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * ceil(m/pt) * (alpha/beta) + 2 * num_outputs * (ceil(C/k)*ceil(k/qr)-1)
                                    num_ifmap_values * ceil(M/m) * ceil( m/(x(1)*floor(J2/(R*e*x(3)))) ) * (alpha/beta) + ...
                                    2 * num_ofmap_values * ( ceil(C/k) * ceil(k/(x(2)*x(3))) - 1 ) ...
                                );

num_buff_acc                =   Inf;
x                           =   zeros(1, 3);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_buff_acc, ~]  = ...
                                ga ...
                                ( ...
                                    num_buff_acc_func, ...              % minimization target
                                    3, ...                              % number variables in x
                                    [], [], ...                         % linear inequality constraints
                                    [], [], ...                         % blank
                                    [1; 1; 1], ...                      % lower bound of x
                                    [m; k; min([floor(J2/R/e) k])], ... % upper bound of x
                                    register_size_constraint, ...       % non-linear constraints
                                    [1 2 3], ...                        % integer constraints
                                    ga_opts ...                         % ga options
                                );
    if curr_buff_acc < num_buff_acc
        num_buff_acc        =   curr_buff_acc;
        x                   =   curr_x;
    elseif curr_buff_acc == num_buff_acc
        if prod(curr_x) > prod(x)
            x               =   curr_x;
        end
    end
end
                            
% get optimization results
p                           =   x(1);
q                           =   x(2);
r                           =   x(3);
t                           =   min([floor(J2/R/e/r) ceil(m/p)]);

% % hack begins
% p                           =   16;
% q                           =   3;
% r                           =   2;
% t                           =   2;
% hack ends

%% output ----------------------------------------------------------------------

% params
params.m                    =   m;
params.n                    =   n;
params.k                    =   k;
params.e                    =   e;
params.h                    =   h;
params.beta                 =   beta;
params.p                    =   p;
params.q                    =   q;
params.r                    =   r;
params.t                    =   t;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta);
reuse.memory.weight         =   ceil(N/n) * ceil(E/e);

reuse.buffer.ofmap          =   ceil(C/(q*r));
reuse.buffer.ifmap          =   ceil(m/(p*t));
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*R;
reuse.array.ifmap           =   t*R*beta;
reuse.array.weight          =   e;

reuse.reg.ofmap             =   q*R;
reuse.reg.ifmap             =   p*R*alpha;
reuse.reg.weight            =   n*E;

% access
access.memory.reads         =   num_ifmap_values    * ceil(M/m) * (alpha/beta)  + ...
                                num_weights         * ceil(N/n) * ceil(E/e);
access.memory.writes        =   num_ofmap_values;

access.buffer.reads         =   num_ifmap_values    * ceil(M/(p*t)) * (alpha/beta)   + ...
                                num_ofmap_values    * ( ceil(C/(q*r)) - 1 );
access.buffer.writes        =   num_ofmap_values    * ( ceil(C/(q*r)) - 1 );

access.array.wiring         =   num_ifmap_values    * ceil(M/p) * R * alpha + ...
                                num_weights         * ceil(N/n) * E         + ...
                                num_ofmap_values    * ( ceil(C/q)*R - ceil(C/(q*r)) );

access.reg.reads            =   num_ifmap_values    * M*R^2*alpha^2 + ...
                                num_weights         * N*E^2         + ...
                                num_ofmap_values    * ( C*R^2 - ceil(C/q)*R );
access.reg.writes           =   num_ofmap_values    * ( C*R^2 - ceil(C/q)*R );

% thruput
thruput.active_pes          =   R*e*r*t;
thruput.active_pe_percent   =   thruput.active_pes/J2;

end