function    [access, reuse, params, thruput] = os_soc_mop_flow(G, N, C, M, H, R, E, U, alpha, J, Q_byte, ~, WL, num_trials)

%% num data --------------------------------------------------------------------

% total number ifmap values
num_ifmap_values            =   G * N * C * H^2;
% total number weights
num_weights                 =   G * M * C * R^2;
% total number ofmap values
num_ofmap_values            =   G * N * M * E^2;

%% memory size -----------------------------------------------------------------

% buffer size [in words]
Q                           =   floor(Q_byte / WL);

%% memory level accesses optimization ------------------------------------------

% x = [m, n, e]

e_max                       =   min([E floor(sqrt(J))]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... mCR^2 + nCh^2 - Q, h = eU+R-U
                                    ( x(1)*C*R^2 + x(2)*C*(x(3)*U+R-U)^2 - Q ), ...
                                    [] ...
                                );
                            
num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * (alpha/beta)^2 + num_weights
                                    num_ifmap_values * ceil(M/x(1)) * (alpha/(x(3)/(x(3)*U+R-U)))^2 + ...
                                    num_weights...
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
                                    [M; N; e_max], ...          % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2 3], ...                % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_mem_reads < num_mem_reads
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    elseif curr_mem_reads == num_mem_reads
        if prod(curr_x) > prod(x)
            x               =   curr_x;
        end
    end
end

% get optimization results
m                           =   x(1);
e                           =   x(3);
n                           =   min([x(2) floor(J/(e^2))]);
f                           =   e;
h                           =   e*U + R - U;
w                           =   h;
beta                        =   e/h;

%% output ----------------------------------------------------------------------

% parameters
params.m                    =   m;
params.n                    =   n;
params.e                    =   e;
params.f                    =   f;
params.h                    =   h;
params.w                    =   w;
params.beta                 =   beta;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta)^2;
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   m;
reuse.buffer.weight         =   ceil(N/n) * ceil(E/e) * ceil(E/f);

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   R^2 * beta^2;
reuse.array.weight          =   n*e*f;

reuse.reg.ofmap             =   C*R^2;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m) * (alpha/beta)^2;
access.memory.reads.weight  =   num_weights;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * M * (alpha/beta)^2;
access.buffer.reads.weight  =   num_weights * (N/n) * ceil(E/e)^2;
access.buffer.reads.ofmap   =   0;
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   0;
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M * R^2 * alpha^2;
access.array.wiring.weight  =   num_weights * N * E^2;
access.array.wiring.ofmap   =   0;
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;
                                              
access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   0;
access.reg.reads.ofmap      =   num_ofmap_values * ( C*R^2 - 1 );
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   num_ofmap_values * ( C*R^2 - 1 );
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

% thruput
thruput.active_pes          =   n*e*f;
thruput.active_pe_percent   =   thruput.active_pes/J;

end
