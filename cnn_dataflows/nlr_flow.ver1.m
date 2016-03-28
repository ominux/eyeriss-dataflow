function    [access, reuse, params, thruput] = nlr_flow(G, N, C, M, H, R, E, U, alpha, J, Q_byte, ~, WL, num_trials)
   
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

% x = [n m q e]

dram_to_buff_energy_ratio   =   50;
q_max                       =   min([C J]);

buffer_size_constraint      =   @(x) ...
                                deal ...
                                ( ... nqh^2 + mqR^2 + nme^2 - Q, h = eU+R-U
                                    ( x(1)*x(3)*(x(4)*U+R-U)^2 + x(2)*x(3)*R^2 + x(1)*x(2)*x(4)^2 - Q ), ...
                                    [] ...
                                );

dram_buff_energy_func       =   @(x) ...
                                ( ... dram: num_inputs * ceil(M/m) * (alpha/beta)^2             + num_weights * ceil(N/n)*ceil(E/e)^2   + num_outputs
                                  ... buff: num_inputs * ceil(M/m) * ceil(m/p) * R^2 * alpha^2  + num_weights * NEF                     + 2 * num_outputs * ( ceil(C/q)*R^2 - 1 )
                                    dram_to_buff_energy_ratio * ( (num_ifmap_values * ceil(M/x(2)) * ( alpha / (x(4)/(U*x(4)+R-U)) )^2) + (num_weights * ceil(N/x(1)) * ceil(E/x(4))^2) + num_ofmap_values ) + ...
                                    ( (num_ifmap_values * ceil(M/x(2)) * ceil(x(2)/floor(J/x(3))) * R^2 * alpha^2) + (num_weights * N*E^2) + (2 * num_ofmap_values * (ceil(C/x(3))*R^2 - 1)) ) ...
                                );
                            
energy_cost                 =   Inf;
x                           =   zeros(1, 4);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_energy_cost, ~] = ...
                                ga ...
                                ( ...
                                    dram_buff_energy_func, ...  % minimization target
                                    4, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1; 1], ...           % lower bound of x
                                    [N; M; q_max; E], ...       % upper bound of x
                                    buffer_size_constraint, ... % non-linear constraints
                                    [1 2 3 4], ...              % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_energy_cost < energy_cost
        energy_cost         =   curr_energy_cost;
        x                   =   curr_x;
    elseif curr_energy_cost == energy_cost
        if (curr_x(3)*min([floor(J/curr_x(3)) curr_x(2)])) > (x(3)*min([floor(J/x(3)) x(2)])) % find the largest p*q
            energy_cost     =   curr_energy_cost;
            x               =   curr_x;
        end
    end
end

% get optimization results
n                           =   x(1);
m                           =   x(2);
q                           =   x(3);
e                           =   x(4);
f                           =   e;
h                           =   U*e + R - U;
w                           =   h;
p                           =   min([floor(J/q) m]);
beta                        =   e/h;

%% sanity check ----------------------------------------------------------------

if (p*q > J)
    error('PE array size constraint invalid.');
end

if ( n*q*h*w + m*q*R^2 + n*m*e*f > Q)
    error('Buffer size constraint invalid.');
end

%% outputs ---------------------------------------------------------------------

% parameters
params.n                    =   n;
params.m                    =   m;
params.p                    =   p;
params.q                    =   q;
params.e                    =   e;
params.f                    =   f;
params.h                    =   h;
params.w                    =   w;
params.beta                 =   beta;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha/beta)^2;
reuse.memory.weight         =   ceil(N/n) * ceil(E/e)^2;

reuse.buffer.ofmap          =   ceil(C/q) * R^2;
reuse.buffer.ifmap          =   ceil(m/p) * R^2 * beta^2;
reuse.buffer.weight         =   n*e^2;

reuse.array.ofmap           =   q;
reuse.array.ifmap           =   p;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   1;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;

% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m) * (alpha/beta)^2;
access.memory.reads.weight  =   num_weights * ceil(N/n) * ceil(E/e)^2;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * ceil(M/p) * R^2 * alpha^2;
access.buffer.reads.weight  =   num_weights * N * E^2;
access.buffer.reads.ofmap   =   num_ofmap_values * ( ceil(C/q)*R^2 - 1 );
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   num_ofmap_values * ( ceil(C/q)*R^2 - 1 );
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M * R^2 * alpha^2;
access.array.wiring.weight  =   0;
access.array.wiring.ofmap   =   num_ofmap_values * ( C*R^2 - ceil(C/q)*R^2 );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;
                                              
access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   0;
access.reg.reads.ofmap      =   0;
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   0;
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

access.alu                  =   G*N*M*C*E^2*R^2;

% thruput
thruput.active_pes          =   p*q;
thruput.active_pe_percent   =   thruput.active_pes/J;

end

