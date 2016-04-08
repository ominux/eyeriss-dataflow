function    [access, reuse, params, thruput] = os_soc_mop_flow(N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials)

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
if ((C*R*S)>Q) || ((U+U*R+1)>RF) || (J<1)
    access                  =   0;
    reuse                   =   0;
    params.validity         =   0;
    thruput                 =   0;
    return;
end

%% GA optimization --------------------------------------------------------

% x = [m n e f]

constraints                 =   @(x) ...
                                deal ...
                                ( ... % buffer size:    mCRS + nChw - Q, h = Ue+R-U, w = Uf+S-U
                                  ... % array size:     nef - J
                                    [   ( x(1)*C*R*S + x(2)*C*(x(3)*U+R-U)*(x(4)*U+S-U) - Q ); ...
                                        ( x(2)*x(3)*x(4) - J ); ...
                                    ], ...
                                    [] ...
                                );
                            
fmin                        =   @(x) ...
                                ( ... % dram:   num_weights + num_inputs*ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h) + num+outputs, beta_v = e/h, beta_h = f/w
                                  ... % buffer: num_weights*ceil(N/n)*ceil(E/e)*ceil(F/f) + num_inputs*M*(alpha_v/beta_v)*(alpha_h/beta_h)
                                  ... % noc:    num_weights*N*E*F + num_inputs*M*R*S*alpha_v*alpha_h
                                  ... % reg:    2*num_outputs*(C*R*S-1)
                                    ( num_weights + num_ifmap_values*ceil(M/x(1))*(alpha_v/(x(3)/(x(3)*U+R-U)))*(alpha_h/(x(4)/(x(4)*U+S-U))) + num_ofmap_values )          * energy_ratios.dram + ...
                                    ( num_weights*ceil(N/x(2))*ceil(E/x(3))*ceil(F/x(4)) + num_ifmap_values*M*(alpha_v/(x(3)/(x(3)*U+R-U)))*(alpha_h/(x(4)/(x(4)*U+S-U))) ) * energy_ratios.buffer + ...
                                    ( num_weights*N*E*F + num_ifmap_values*M*R*S*alpha_v*alpha_h )                                                                          * energy_ratios.noc + ...
                                    ( 2*num_ofmap_values*(C*R*S-1) )                                                                                                        * energy_ratios.reg ...
                                );

min_f                       =   Inf;
x                           =   zeros(1, 4);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_min_f, ~] =   ga ...
                                ( ...
                                    fmin, ...                   % minimization target
                                    4, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1; 1], ...           % lower bound of x
                                    [M; N; E; F], ...           % upper bound of x
                                    constraints, ...            % non-linear constraints
                                    [1 2 3 4], ...              % integer constraints
                                    ga_opts ...                 % ga options
                                );
    if curr_min_f < min_f
        min_f               =   curr_min_f;
        x                   =   curr_x;
    elseif curr_min_f == min_f
        if (curr_x(2)*curr_x(3)*curr_x(4)) > (x(2)*x(3)*x(4)) % find the largest n*e*f
            x               =   curr_x;
        end
    end
end

% get optimization results
m                           =   x(1);
n                           =   x(2);
e                           =   x(3);
f                           =   x(4);
h                           =   e*U + R - U;
w                           =   f*U + S - U;
beta_v                      =   e/h;
beta_h                      =   f/w;

%% sanity check -----------------------------------------------------------

if (n*e*f > J)
    error('PE array size constraint invalid.');
end

if ( m*C*R*S + n*C*h*w > Q)
    error('Buffer size constraint invalid.');
end

%% output -----------------------------------------------------------------

% parameters
params.validity             =   1;
params.m                    =   m;
params.n                    =   n;
params.e                    =   e;
params.f                    =   f;
params.h                    =   h;
params.w                    =   w;
params.beta_v               =   beta_v;
params.beta_h               =   beta_h;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h);
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   1;
reuse.buffer.ifmap          =   m;
reuse.buffer.weight         =   ceil(N/n)*ceil(E/e)*ceil(F/f);

reuse.array.ofmap           =   1;
reuse.array.ifmap           =   R*S*beta_v*beta_h;
reuse.array.weight          =   n*e*f;

reuse.reg.ofmap             =   C*R*S;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   1;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/m)*(alpha_v/beta_v)*(alpha_h/beta_h);
access.memory.reads.weight  =   num_weights;
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values * M*(alpha_v/beta_v)*(alpha_h/beta_h);
access.buffer.reads.weight  =   num_weights*(N/n)*ceil(E/e)*ceil(F/f);
access.buffer.reads.ofmap   =   0;
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   0;
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values * M*R*S*alpha_v*alpha_h;
access.array.wiring.weight  =   num_weights * N*E*F;
access.array.wiring.ofmap   =   0;
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;
                                              
access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   0;
access.reg.reads.ofmap      =   num_ofmap_values * ( C*R*S - 1 );
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   num_ofmap_values * ( C*R*S - 1 );
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

access.alu                  =   G*N*M*C*E*F*R*S;

% thruput
thruput.active_pes          =   n*e*f;
thruput.active_pe_percent   =   thruput.active_pes/J;

end
