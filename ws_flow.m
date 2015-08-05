function    [access, reuse, params, thruput] = ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials)

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

% x = [t e]

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... N*E^2*t + rt(h-R)(R-1) - Q
                                    ( N*E*E*x(1) + floor(J2/(R^2)/x(1)) * x(1) * ( (U*x(2)+R-U)-R ) * (R-1) - Q ), ...
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
                                    [min([M floor(J2/(R^2))]); E], ...  % upper bound of x
                                    buffer_size_constraint, ...         % non-linear constraints
                                    [1 2], ...                          % integer constraints
                                    ga_opts ...                         % ga options
                                );
    if curr_mem_reads < num_mem_reads
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    end
end

% get optimization results
t                           =   x(1);
e                           =   x(2);
r                           =   floor(J2/(R^2)/t);
h                           =   U*e + R - U;
beta                        =   e/h;
q                           =   min([(G - 1) ceil(C/r)]);


%% reuse -----------------------------------------------------------------------

% parameteres
params.t                    =   t;
params.e                    =   e;
params.h                    =   h;
params.beta                 =   beta;
params.r                    =   r;
params.q                    =   q;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/t) * (alpha/beta);
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   R * ceil(C/(r*q));
reuse.buffer.ifmap          =   1;
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*R;
reuse.array.ifmap           =   t * R^2 * alpha * beta;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   q;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   N*E^2;
        
% access
access.memory.reads         =   num_ifmap_values * ceil(M/t) * (alpha/beta)     + ...
                                num_weights;
access.memory.writes        =   num_ofmap_values;
access.buffer.reads         =   num_ofmap_values * ( R*ceil(C/(r*q)) - 1 );
access.buffer.writes        =   num_ofmap_values * ( R*ceil(C/(r*q)) - 1 );
access.array.wiring         =   num_ifmap_values * M * R^2 * alpha^2            + ...
                                num_ofmap_values * ( ceil(C/q)*R^2 - ceil(C/(r*q))*R );
access.reg.reads            =   num_weights * N * E^2                           + ...
                                num_ofmap_values * ( C*R^2 - ceil(C/q)*R^2 );
access.reg.writes           =   num_ofmap_values * ( C*R^2 - ceil(C/q)*R^2 );

% thruput
thruput.active_pes          =   R^2 * r * t;
thruput.active_pe_percent   =   thruput.active_pes/J2;

end