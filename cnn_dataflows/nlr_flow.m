function    [access, reuse, params, thruput] = nlr_flow(N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials)
   
%% extract model parameters -----------------------------------------------

G                           =   model_params.G;
C                           =   model_params.C;
M                           =   model_params.M;
H                           =   model_params.H;
W                           =   model_params.W;
R                           =   model_params.R;
S                           =   model_params.S;
E                           =   model_params.E;
F                           =   model_params.F;
U                           =   model_params.U;
alpha_v                     =   model_params.alpha_v;
alpha_h                     =   model_params.alpha_h;

%% num data ---------------------------------------------------------------

% total number ifmap values
num_ifmap_values            =   G * N * C * H * W;
% total number weights
num_weights                 =   G * M * C * R * S;
% total number ofmap values
num_ofmap_values            =   G * N * M * E * F;

%% memory size ------------------------------------------------------------

% buffer size [in words]
Q                           =   floor(Q_byte / WL);
% register size [in words]
RF                          =   floor(RF_byte / WL);

%% make sure problem size fit in the hardware -----------------------------

% assuming all tiling parameters are at their minimum values
if (J<1) || ((R*S+1)>Q) || (RF<1)
    access                  =   0;
    reuse                   =   0;
    params.validity         =   0;
    thruput                 =   0;
    return;
end

%% GA optimization --------------------------------------------------------

% x = [n m p q e f]

constraints                 =   @(x) ...
                                deal ...
                                ( ... % buffer size:    nqhw + mqRS + nmef - Q, h = eU+R-U, w = fU+S-U
                                  ... % array size:     pq - J
                                  ... % filt tiling:    p - m
                                    [   ( x(1)*x(4)*(x(5)*U+R-U)*(x(6)*U+S-U) + x(2)*x(4)*R*S + x(1)*x(2)*x(5)*x(6) - Q ); ...
                                        ( x(3)*x(4) - J ); ...
                                        ( x(3) - x(2) ); ...
                                    ], ...
                                    [] ...
                                );

fmin                        =   @(x) ...
                                ( ... % dram:   num_weights * ceil(N/n)*ceil(E/e)*ceil(F/f) + num_inputs * ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h) +  num_outputs
                                  ... % buffer: num_weights * NEF + num_inputs * ceil(M/p)*R*S*alpha_v*alpha_h + 2*num_outputs*( ceil(C/q)*R*S - 1 )
                                  ... % noc:    num_inputs * MRS*alpha_v*alpha_h + 2*num_outputs*( CRS - ceil(C/q)*R*S )
                                  ... $ reg:    0
                                    ( num_weights*ceil(N/x(1))*ceil(E/x(5))*ceil(F/x(6)) + num_ifmap_values*ceil(M/x(2))*(alpha_v/(x(5)/(U*x(5)+R-U)))*(alpha_h/(x(6)/(U*x(6)+S-U))) + num_ofmap_values )   * energy_ratios.dram + ...
                                    ( num_weights*N*E*F + num_ifmap_values*ceil(M/x(3))*R*S*alpha_v*alpha_h + 2*num_ofmap_values*(ceil(C/x(4))*R*S-1) )                                                     * energy_ratios.buffer + ...
                                    ( num_ifmap_values*M*R*S*alpha_v*alpha_h + 2*num_ofmap_values*(C*R*S-ceil(C/x(4))*R*S) )                                                                                * energy_ratios.noc ...
                                );
                            
min_f                       =   Inf;
x                           =   zeros(1, 6);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_min_f, ~] =   ga ...
                                ( ...
                                    fmin, ...                   % minimization target
                                    6, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1; 1; 1; 1], ...     % lower bound of x
                                    [N; M; M; C; E; F], ...     % upper bound of x
                                    constraints, ...            % non-linear constraints
                                    [1 2 3 4 5 6], ...          % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_min_f < min_f
        min_f               =   curr_min_f;
        x                   =   curr_x;
    elseif curr_min_f == min_f
        if (curr_x(3)*curr_x(4)) > (x(3)*x(4)) % find the largest p*q
            x               =   curr_x;
        end
    end
end

% get optimization results
n                           =   x(1);
m                           =   x(2);
p                           =   x(3);
q                           =   x(4);
e                           =   x(5);
f                           =   x(6);
h                           =   U*e + R - U;
w                           =   U*f + S - U;
beta_v                      =   e/h;
beta_h                      =   f/w;

%% sanity check -----------------------------------------------------------

if (p*q > J)
    error('PE array size constraint invalid.');
end

if ( n*q*h*w + m*q*R*S + n*m*e*f > Q)
    error('Buffer size constraint invalid.');
end

%% outputs ----------------------------------------------------------------

% parameters
params.n                    =   n;
params.m                    =   m;
params.p                    =   p;
params.q                    =   q;
params.e                    =   e;
params.f                    =   f;
params.h                    =   h;
params.w                    =   w;
params.beta_v               =   beta_v;
params.beta_h               =   beta_h;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h);
reuse.memory.weight         =   ceil(N/n)*ceil(E/e)*ceil(F/f);

reuse.buffer.ofmap          =   ceil(C/q)*R*S;
reuse.buffer.ifmap          =   ceil(m/p)*R*S*beta_v*beta_h;
reuse.buffer.weight         =   n*e*f;

reuse.array.ofmap           =   q;
reuse.array.ifmap           =   p;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   1;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;

% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h);
access.memory.reads.weight  =   num_weights * ceil(N/n)*ceil(E/e)*ceil(F/f);
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * ceil(M/p)*R*S*alpha_v*alpha_h;
access.buffer.reads.weight  =   num_weights * N*E*F;
access.buffer.reads.ofmap   =   num_ofmap_values * ( ceil(C/q)*R*S - 1 );
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   num_ofmap_values * ( ceil(C/q)*R*S - 1 );
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M*R*S*alpha_v*alpha_h;
access.array.wiring.weight  =   0;
access.array.wiring.ofmap   =   num_ofmap_values * ( C*R*S - ceil(C/q)*R*S );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;
                                              
access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   0;
access.reg.reads.ofmap      =   0;
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   0;
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

access.alu                  =   G*N*M*C*E*F*R*S;

% thruput
thruput.active_pes          =   p*q;
thruput.active_pe_percent   =   thruput.active_pes/J;

end

