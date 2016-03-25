function    [access, reuse, params, thruput] = os_moc_mop_flow(G, N, C, M, H, R, E, U, alpha, J, Q_byte, ~, WL, num_trials)

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

% x = [m, n, f]

f_max                       =   min([E J]);
n_max                       =   min([N J]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... mCR^2 + nCRw - Q, w = fU+R-U
                                    ( x(1)*C*R^2 + x(2)*C*R*(x(3)*U+R-U) - Q ), ...
                                    [] ...
                                );
                            
num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/m) * (alpha/beta) * R * alpha
                                    num_ifmap_values * ceil(M/x(1)) * (alpha / (x(3)/(x(3)*U+R-U)) ) * R * alpha + ...
                                    num_weights ...
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
                                    [M; n_max; f_max], ...      % upper bound of x
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
n                           =   x(2);
f                           =   x(3);
w                           =   f*U + R - U;
beta                        =   f/w;
p                           =   min([floor(J/n/f) m]);

%% output ----------------------------------------------------------------------

% params
params.m                    =   m;
params.n                    =   n;
params.f                    =   f;
params.w                    =   w;
params.p                    =   p;
params.beta                 =   beta;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta) * R * alpha;
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   ceil(m/p) * R * beta;
reuse.buffer.weight         =   ceil(N/n) * E * ceil(E/f);

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   p;
reuse.array.weight          =   n*f;

reuse.reg.ofmap             =   C*R^2;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m) * (alpha/beta) * R * alpha;
access.memory.reads.weight  =   num_weights;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * ceil(M/p) * R^2 * alpha^2;
access.buffer.reads.weight  =   num_weights * ceil(N/n) * E * ceil(E/f);
access.buffer.reads.ofmap   =   0;
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   0;
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * R^2 * alpha^2;
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
thruput.active_pes          =   n*p*f;
thruput.active_pe_percent   =   thruput.active_pes/J;

end