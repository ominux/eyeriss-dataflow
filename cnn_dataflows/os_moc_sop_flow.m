function    [access, reuse, params, thruput] = os_moc_sop_flow(G, N, C, M, H, R, E, ~, alpha, J, Q_byte, ~, WL, ~)

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

m                           =   min([floor( (Q - C*R^2)/(C*R^2) ) M]);
p                           =   min([m J]);

%% sanity check ----------------------------------------------------------------

if (p > J)
    error('PE array size constraint invalid.');
end

if ( m*C*R^2 + C*R^2 > Q)
    error('Buffer size constraint invalid.');
end

%% output ----------------------------------------------------------------------

% parameters
params.m                    =   m;
params.p                    =   p;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * R^2 * alpha^2;
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   ceil(m/p);
reuse.buffer.weight         =   N*E^2;

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   p;
reuse.array.weight          =   1;

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
access.buffer.reads.weight  =   num_weights * N * E^2;
access.buffer.reads.ofmap   =   0;
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   0;
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M * R^2 * alpha^2;
access.array.wiring.weight  =   0;
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
thruput.active_pes          =   p;
thruput.active_pe_percent   =   thruput.active_pes/J;

end
