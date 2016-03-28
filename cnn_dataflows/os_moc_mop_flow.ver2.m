function    [access, reuse, params, thruput] = os_moc_mop_flow(G, N, C, M, H, R, E, ~, alpha, J, Q_byte, ~, WL, num_trials)

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

% x = [m ne2]

dram_to_buff_energy_ratio   =   50;
ne2_max                     =   min([N*E^2 J]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... (m+ne2)CR^2 - Q,
                                    ((x(1) + x(2))*C*R^2 - Q ), ...
                                    [] ...
                                );
                            
mem_buff_energy_func        =   @(x) ...
                                ( ... dram: num_inputs * ceil(M/m) * R^2 * alpha^2 + num_weights + num_outputs
                                  ... buff: num_inputs * ceil(M/m) * ceil(m/p) * R^2 * alpha^2 + num_weights * ceil(NE^2 / ne2)
                                    dram_to_buff_energy_ratio * ((num_ifmap_values * ceil(M/x(1)) * R^2 * alpha^2) + num_weights + num_ofmap_values) + ...
                                    ( (num_ifmap_values * ceil(M/x(1)) * ceil(x(1)/floor(J/x(2))) * R^2 * alpha^2) + (num_weights * ceil((N*E^2)/x(2))) ) ...
                                );

num_mem_reads               =   Inf;
x                           =   zeros(1, 2);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_mem_reads, ~] = ...
                                ga ...
                                ( ...
                                    mem_buff_energy_func, ...   % minimization target
                                    2, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1], ...                 % lower bound of x
                                    [M; ne2_max], ...           % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2], ...                  % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_mem_reads < num_mem_reads
        num_mem_reads       =   curr_mem_reads;
        x                   =   curr_x;
    elseif curr_mem_reads == num_mem_reads
        if (min([curr_x(1) floor(J/curr_x(2))])*curr_x(2)) > (min([x(1) floor(J/x(2))])*x(2)) % find the largest p*ne2
            x               =   curr_x;
        end
    end
end

% get optimization results
m                           =   x(1);
ne2                         =   x(2);
p                           =   min([m floor(J/ne2)]);

%% sanity check ----------------------------------------------------------------

if (p*ne2 > J)
    error('PE array size constraint invalid.');
end

if ( m*C*R^2 + ne2*C*R^2 > Q)
    error('Buffer size constraint invalid.');
end

%% output ----------------------------------------------------------------------

% params
params.m                    =   m;
params.ne2                  =   ne2;
params.p                    =   p;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * R^2 * alpha^2;
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   ceil(m/p);
reuse.buffer.weight         =   ceil(N*E^2/ne2);

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   p;
reuse.array.weight          =   ne2;

reuse.reg.ofmap             =   C*R^2;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m) * R^2 * alpha^2;
access.memory.reads.weight  =   num_weights;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * ceil(M/p) * R^2 * alpha^2;
access.buffer.reads.weight  =   num_weights * ceil(N*E^2/ne2);
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

access.alu                  =   G*N*M*C*E^2*R^2;

% thruput
thruput.active_pes          =   p * ne2;
thruput.active_pe_percent   =   thruput.active_pes/J;

end