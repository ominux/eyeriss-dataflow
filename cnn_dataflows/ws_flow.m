function    [access, reuse, params, thruput] = ws_flow(N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials)

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
Q                           =   floor(Q_byte  / WL);
% register size [in words]
RF                          =   floor(RF_byte / WL);

%% make sure problem size fit in the hardware -----------------------------

% assuming all tiling parameters are at their minimum values
if ((N*E*F)>Q) || ((R*S)>J) || (RF<1)
    access                  =   0;
    reuse                   =   0;
    params.validity         =   0;
    thruput                 =   0;
    return;
end

%% GA optimization --------------------------------------------------------

% x = [r t f]

constraints                 =   @(x) ...
                                deal ...
                                ( ... % buffer size:    NtEF + rt(w-S)(R-1) - Q, w = Uf+S-U
                                  ... % array size:     rtRS - J
                                    [   ( N*x(2)*E*F + x(1)*x(2)*( (U*x(3)+S-U)-S )*(R-1) - Q ); ...
                                        ( x(1)*x(2)*R*S - J ) ...
                                    ], ...
                                    [] ...
                                );
                            
fmin                        =   @(x) ...
                                ( ... % dram:   num_weights + num_inputs * ceil(M/t) * (alpha_h/beta_h) + num_outputs, beta_h = f/w
                                  ... % buffer: 2*num_outputs*( ceil(C/r)*R-1 )
                                  ... % array:  num_inputs * MRS(alpha_v)(alpha_h) + 2*num_outputs*(CRS-ceil(C/r)*R)
                                  ... % reg:    num_weights * NEF
                                    ( num_weights + num_ifmap_values*ceil(M/x(2))*(alpha/(x(3)/(U*x(3)+S-U))) + num_ofmap_values )  * energy_ratios.dram + ...
                                    ( 2*num_ofmap_values*(ceil(C/x(1))*R-1) )                                                       * energy_ratios.buffer + ...
                                    ( num_ifmap_values*M*R*S*alpha_v*alpha_h + 2*num_ofmap_values*(C*R*S-ceil(C/x(1))*R) )          * energy_ratios.noc + ...
                                    ( num_weights*N*E*F )                                                                           * energy_ratios.reg ...
                                );

min_f                       =   Inf;
x                           =   zeros(1, 3);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    [curr_x, curr_min_f, ~] =   ga ...
                                ( ...
                                    fmin, ...                           % minimization target
                                    3, ...                              % number variables in x
                                    [], [], ...                         % linear inequality constraints
                                    [], [], ...                         % blank
                                    [1; 1; 1], ...                      % lower bound of x
                                    [C; M; F], ...                      % upper bound of x
                                    constraints, ...                     % non-linear constraints
                                    [1 2 3], ...                        % integer constraints
                                    ga_opts ...                         % ga options
                                );
    if      curr_min_f <  min_f
        min_f               =   curr_min_f;
        x                   =   curr_x;
    elseif  curr_min_f == min_f
        if (curr_x(1)*curr_x(2)) > (x(1)*x(2)) % find the largest r*t
            x               =   curr_x;
        end
    end
end

% get optimization results
r                           =   x(1);
t                           =   x(2);
f                           =   x(3);
w                           =   U*f + S - U;
beta_h                      =   f/w;

%% sanity check -----------------------------------------------------------

if (r*t*R*S > J)
    error('PE array size constraint invalid.');
end

if ( N*t*E*F + r*t*(w-S)*(R-1) > Q)
    error('Buffer size constraint invalid.');
end


%% reuse ------------------------------------------------------------------

% parameteres
params.validity             =   1;
params.r                    =   r;
params.t                    =   t;
params.f                    =   f;
params.w                    =   w;
params.beta_h               =   beta_h;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/t) * (alpha_h/beta_h);
reuse.memory.weight         =   1;

reuse.buffer.ofmap          =   R * ceil(C/r);
reuse.buffer.ifmap          =   1;
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*S;
reuse.array.ifmap           =   t * R*S * alpha_v * beta_h;
reuse.array.weight          =   1;

reuse.reg.ofmap             =   1;
reuse.reg.ifmap             =   1;
reuse.reg.weight            =   N*E*F;
        
% access
access.memory.reads.ifmap   =   num_ifmap_values * ceil(M/t)*(alpha_h/beta_h);
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

access.array.wiring.ifmap   =   num_ifmap_values * M*R*S*alpha_v*alpha_h;
access.array.wiring.weight  =   0;
access.array.wiring.ofmap   =   num_ofmap_values * ( C*R*S - ceil(C/r)*R );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;

access.reg.reads.ifmap      =   0;
access.reg.reads.weight     =   num_weights * N*E*F;
access.reg.reads.ofmap      =   0;
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   0;
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

access.alu                  =   G*N*M*C*E*F*R*S;

% thruput
thruput.active_pes          =   R*S*r*t;
thruput.active_pe_percent   =   thruput.active_pes/J;

end