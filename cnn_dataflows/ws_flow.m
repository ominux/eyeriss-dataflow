function    [access, reuse, params, thruput] = ws_flow(G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials)

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

% x = [t e]

t_max                       =   min([M floor(J/R/R)]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... N*E^2*t + rt(h-R)(R-1) - Q, r = J/R^2/t
                                    ( N*E*E*x(1) + floor(J/(R^2)/x(1)) * x(1) * ( (U*x(2)+R-U)-R ) * (R-1) - Q ), ...
                                    [] ...
                                );
                            
num_mem_reads_func          =   @(x) ...
                                ( ... num_inputs * ceil(M/t) * (alpha/beta)
                                    num_ifmap_values * ceil(M/x(1)) * ( alpha / (x(2)/(U*x(2)+R-U)) ) ...
                                );

num_mem_reads               =   Inf;
x                           =   zeros(1, 2);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_mem_reads, ~] = ...
                                ga ...
                                ( ...
                                    num_mem_reads_func, ...             % minimization target
                                    2, ...                              % number variables in x
                                    [], [], ...                         % linear inequality constraints
                                    [], [], ...                         % blank
                                    [1; 1], ...                         % lower bound of x
                                    [t_max E], ...                      % upper bound of x
                                    buffer_size_constraint, ...         % non-linear constraints
                                    [1 2], ...                          % integer constraints
                                    ga_opts ...                         % ga options
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
t                           =   x(1);
e                           =   x(2);
r                           =   min([floor(J/(R^2)/t) C]);
h                           =   U*e + R - U;
beta                        =   e/h;


%% reuse -----------------------------------------------------------------------

% parameteres
params.t                    =   t;
params.e                    =   e;
params.h                    =   h;
params.beta                 =   beta;
params.r                    =   r;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/t) * (alpha/beta);
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   R * ceil(C/r);
reuse.buffer.ifmap          =   1;
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*R;
reuse.array.ifmap           =   t * R^2 * alpha * beta;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   1;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   N*E^2;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/t) * (alpha/beta);
access.memory.reads.weight  =   num_weights;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   0;
access.buffer.reads.weight  =   0;
access.buffer.reads.ofmap   =   num_ofmap_values * ( R*ceil(C/r) - 1 );
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   num_ofmap_values * ( R*ceil(C/r) - 1 );
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M * R^2 * alpha^2;
access.array.wiring.weight  =   0;
access.array.wiring.ofmap   =   num_ofmap_values * ( C*R^2 - ceil(C/r)*R );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;

access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   num_weights * N * E^2;
access.reg.reads.ofmap      =   num_ofmap_values * ( C*R^2 - C*R^2 );
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   num_ofmap_values * ( C*R^2 - C*R^2 );
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

% thruput
thruput.active_pes          =   R^2 * r * t;
thruput.active_pe_percent   =   thruput.active_pes/J;

end