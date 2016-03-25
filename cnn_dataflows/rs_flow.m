function    [access, reuse, params, thruput] = rs_flow(G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials)

%% num data --------------------------------------------------------------------

% total number ifmap values
num_ifmap_values            =   G * N * C * H^2;
% total number weights
num_weights                 =   G * M * C * R^2;
% total number ofmap values
num_ofmap_values            =   G * N * M * E^2;

%% memory size -----------------------------------------------------------------

% buffer size [in words]
Q                           =   floor(Q_byte  / WL);
% register size [in words]
RF                          =   floor(RF_byte / WL);

%% memory level accesses optimization ------------------------------------------

% x = [m n k f]

f_max                       =   min([E floor(J/R)]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... % nmEf + nkHw - Q, w = Uf+R-U
                                    ( x(2)*x(1)*E*x(4) + x(2)*x(3)*H*(U*x(4)+R-U) - Q ), ...
                                    [] ...
                                );

num_mem_reads_func          =   @(x) ... % num_weights * ceil(N/n)ceil(E/f) + num_inputs * ceil(M/m)*(alpha/beta), beta = e/h
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
                                    [M; N; C; f_max], ...       % upper bound of x
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
f                           =   x(4);
w                           =   U*f + R - U;
beta                        =   f/w;

% hack begins
% m = 64;
% n = 1;
% e = 13;
% k = 2;
% h = U*f + R - U;
% beta =   f/w;
% hack ends

%% buffer level accesses optimization ------------------------------------------

% x = [p q r]

r_max                       =   min([floor(J/R/f) k]);

register_size_constraint    =   @(x) ...
                                deal ...
                                ( ... pqR + qR + p - RF
                                    ( x(1)*x(2)*R + x(2)*R + x(1) - RF ), ...
                                    [] ...
                                );

num_buff_acc_func           =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * ceil(m/pt) * (alpha/beta) + 2 * num_outputs * (ceil(C/k)*ceil(k/qr)-1)
                                    num_ifmap_values * ceil(M/m) * ceil( m/(x(1)*floor(J/(R*f*x(3)))) ) * (alpha/beta) + ...
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
                                    [m; k; r_max], ...                  % upper bound of x
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
t                           =   min([floor(J/R/f/r) ceil(m/p)]);

% % hack begins
% p                           =   16;
% q                           =   1;
% r                           =   1;
% t                           =   2;
% hack ends

%% output ----------------------------------------------------------------------

% params
params.m                    =   m;
params.n                    =   n;
params.f                    =   f;
params.k                    =   k;
params.w                    =   w;
params.beta                 =   beta;
params.p                    =   p;
params.q                    =   q;
params.r                    =   r;
params.t                    =   t;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta);
reuse.memory.weight         =   ceil(N/n) * ceil(E/f);

reuse.buffer.ofmap          =   ceil(C/(q*r));
reuse.buffer.ifmap          =   ceil(m/(p*t));
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*R;
reuse.array.ifmap           =   t*R*beta;
reuse.array.weight          =   f;

reuse.reg.ofmap             =   q*R;
reuse.reg.ifmap             =   p*R*alpha;
reuse.reg.weight            =   n*E;

% access
access.memory.reads.ifmap   =   num_ifmap_values    * ceil(M/m) * (alpha/beta);
access.memory.reads.weight  =   num_weights         * ceil(N/n) * ceil(E/f);
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values    * ceil(M/(p*t)) * (alpha/beta);
access.buffer.reads.weight  =   0;
access.buffer.reads.ofmap   =   num_ofmap_values    * ( ceil(C/(q*r)) - 1 );
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   num_ofmap_values    * ( ceil(C/(q*r)) - 1 );
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values    * ceil(M/p) * R * alpha;
access.array.wiring.weight  =   num_weights         * ceil(N/n) * E;
access.array.wiring.ofmap   =   num_ofmap_values    * ( ceil(C/q)*R - ceil(C/(q*r)) );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;

access.reg.reads.ifmap      =   num_ifmap_values    * M*R^2*alpha^2;
access.reg.reads.weight     =   num_weights         * N*E^2;
access.reg.reads.ofmap      =   num_ofmap_values    * ( C*R^2 - ceil(C/q)*R );
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   num_ofmap_values    * ( C*R^2 - ceil(C/q)*R );
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

% thruput
thruput.active_pes          =   R*f*r*t;
thruput.active_pe_percent   =   thruput.active_pes/J;

end