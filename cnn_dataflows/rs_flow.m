function    [access, reuse, params, thruput] = rs_flow(N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials)

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

%% check for validity -----------------------------------------------------

% assuming all tiling parameters are at their minimum values
if ((E+H)>Q) || (R>J) || ((2*R)>RF)
    access                  =   0;
    reuse                   =   0;
    params.validity         =   0;
    thruput                 =   0;
    return;
end

%% GA optimization --------------------------------------------------------

% x = [m n f p q r t]
constraints                 =   @(x) ...
                                deal ...
                                ( ...   % 1) buffer size constraint:    nmEf + nqrHw - Q, w = Uf+S-U
                                  ...   % 2) array size constraint:     Rfrt - J
                                  ...   % 3) reg size constraint:       pqR+qR+p - RF
                                  ...   % 4) filt tiling constraint:    qr - C
                                  ...   % 5) chnl tiling constraint:    pt - m
                                    [   ( x(2)*x(1)*E*x(3) + x(2)*x(5)*x(6)*H*(U*x(3)+S-U) - Q ); ...
                                        ( R*x(3)*x(6)*x(7) - J ); ...
                                        ( x(4)*x(5)*R+x(5)*R+x(4) - RF ); ...
                                        ( x(5)*x(6) - C ); ...
                                        ( x(4)*x(7) - x(1) ) ...
                                    ], ...
                                    [] ...
                                );

fmin                        =   @(x) ... 
                                ( ...   % dram:     num_weights * ceil(N/n)*ceil(F/f) + num_inputs * ceil(M/m)*(alpha_h/beta_h) + num_outputs, beta_h = f/w
                                  ...   % buffer:   num_inputs * ceil(M/pt)*(alpha_h/beta_h) + 2*num_outputs*(ceil(C/qr)-1)
                                  ...   % array:    num_weights * ceil(N/n)*F + num_inputs * ceil(M/p)*S*alpha_h + 2*num_outputs*(ceil(C/q)*S-ceil(C/qr))
                                  ...   % reg:      num_weights * NEF + num_inputs * MRS(alpha_v)(alpha_h) + 2*num_outputs*(CRS-ceil(C/q)*S)
                                    ( num_weights*ceil(N/x(2))*ceil(F/x(3)) + num_ifmap_values*ceil(M/x(1))*(alpha_h/(x(3)/(U*x(3)+S-U))) + num_ofmap_values )      * energy_ratios.dram + ...
                                    ( num_ifmap_values*ceil(M/x(4)/x(7))*(alpha_h/(x(3)/(U*x(3)+S-U))) + 2*num_ofmap_values*(ceil(C/x(5)/x(6))-1) )                 * energy_ratios.buffer + ...
                                    ( num_weights*ceil(N/x(2))*F + num_ifmap_values*ceil(M/x(4))*S*alpha_h + 2*num_ofmap_values*(ceil(C/x(5))*S-ceil(C/x(5)/x(6))) )* energy_ratios.noc + ...
                                    ( num_weights*N*E*F + num_ifmap_values*M*R*S*(alpha_v)*(alpha_h) + 2*num_ofmap_values*(C*R*S-ceil(C/x(5))*S) )                  * energy_ratios.reg ...
                                );

min_f                       =   Inf;
x                           =   zeros(1, 7);
ga_opts                     =   gaoptimset('Display', 'off');
for i = 1:num_trials
    % run GA optimization
    [curr_x, curr_min_f, ~] =   ga ...
                                ( ...
                                    fmin, ...                   % minimization target
                                    7, ...                      % number variables in x
                                    [], [], ...                 % linear inequality constraints
                                    [], [], ...                 % blank
                                    [1; 1; 1; 1; 1; 1; 1], ...  % lower bound of x
                                    [M; N; F; M; C; C; M], ...  % upper bound of x
                                    constraints, ...            % non-linear constraints
                                    [1 2 3 4 5 6 7], ...        % integer constraints
                                    ga_opts ...                 % ga options
                                );
    % check if the current GA result is better
    if      curr_min_f <  min_f
        min_f               =   curr_min_f;
        x                   =   curr_x;
    elseif  curr_min_f == min_f
        if (curr_x(3)*curr_x(6)*curr_x(7)) > (x(3)*x(6)*x(7)) % find the largest f*r*t
            x               =   curr_x;
        end
    end
end
                                
% get optimization results
m                           =   x(1);
n                           =   x(2);
f                           =   x(3);
p                           =   x(4);
q                           =   x(5);
r                           =   x(6);
t                           =   x(7);
w                           =   U*f + S - U;
k                           =   q*r;
beta_h                      =   f/w;

%% sanity check -----------------------------------------------------------

if (p*q*R+q*R+p > RF)
    error('RF size constraint invalid.');
end

if (R*f*r*t > J)
    error('PE array size constraint invalid.');
end

if ( n*m*E*f + n*k*H*w > Q)
    error('Buffer size constraint invalid.');
end

%% output -----------------------------------------------------------------

% params
params.validity             =   1;
params.m                    =   m;
params.n                    =   n;
params.f                    =   f;
params.k                    =   k;
params.w                    =   w;
params.beta                 =   beta_h;
params.p                    =   p;
params.q                    =   q;
params.r                    =   r;
params.t                    =   t;

% reuse
reuse.memory.ofmap          =   1;
reuse.memory.ifmap          =   ceil(M/m) * (alpha_h/beta_h);
reuse.memory.weight         =   ceil(N/n) * ceil(F/f);

reuse.buffer.ofmap          =   ceil(C/(q*r));
reuse.buffer.ifmap          =   ceil(m/(p*t));
reuse.buffer.weight         =   1;

reuse.array.ofmap           =   r*S;
reuse.array.ifmap           =   t*S*beta_h;
reuse.array.weight          =   f;

reuse.reg.ofmap             =   q*R;
reuse.reg.ifmap             =   p*R*alpha_v;
reuse.reg.weight            =   n*E;

% access
access.memory.reads.ifmap   =   num_ifmap_values    * ceil(M/m) * (alpha_h/beta_h);
access.memory.reads.weight  =   num_weights         * ceil(N/n) * ceil(F/f);
access.memory.reads.ofmap   =   0;
access.memory.reads.total   =   access.memory.reads.ifmap + access.memory.reads.weight + access.memory.reads.ofmap;
access.memory.writes.ifmap  =   0;
access.memory.writes.weight =   0;
access.memory.writes.ofmap  =   num_ofmap_values;
access.memory.writes.total  =   access.memory.writes.ifmap + access.memory.writes.weight + access.memory.writes.ofmap;

access.buffer.reads.ifmap   =   num_ifmap_values    * ceil(M/(p*t)) * (alpha_h/beta_h);
access.buffer.reads.weight  =   0;
access.buffer.reads.ofmap   =   num_ofmap_values    * ( ceil(C/(q*r)) - 1 );
access.buffer.reads.total   =   access.buffer.reads.ifmap + access.buffer.reads.weight + access.buffer.reads.ofmap;
access.buffer.writes.ifmap  =   0;
access.buffer.writes.weight =   0;
access.buffer.writes.ofmap  =   num_ofmap_values    * ( ceil(C/(q*r)) - 1 );
access.buffer.writes.total  =   access.buffer.writes.ifmap + access.buffer.writes.weight + access.buffer.writes.ofmap;

access.array.wiring.ifmap   =   num_ifmap_values    * ceil(M/p) * S * alpha_h;
access.array.wiring.weight  =   num_weights         * ceil(N/n) * F;
access.array.wiring.ofmap   =   num_ofmap_values    * ( ceil(C/q)*S - ceil(C/(q*r)) );
access.array.wiring.total   =   access.array.wiring.ifmap + access.array.wiring.weight + access.array.wiring.ofmap;

access.reg.reads.ifmap      =   num_ifmap_values    * M*R*S*alpha_v*alpha_h;
access.reg.reads.weight     =   num_weights         * N*E*F;
access.reg.reads.ofmap      =   num_ofmap_values    * ( C*R*S - ceil(C/q)*S );
access.reg.reads.total      =   access.reg.reads.ifmap + access.reg.reads.weight + access.reg.reads.ofmap;
access.reg.writes.ifmap     =   0;
access.reg.writes.weight    =   0;
access.reg.writes.ofmap     =   num_ofmap_values    * ( C*R*S - ceil(C/q)*S );
access.reg.writes.total     =   access.reg.writes.ifmap + access.reg.writes.weight + access.reg.writes.ofmap;

access.alu                  =   G*N*M*C*E*F*R*S;

% thruput
thruput.active_pes          =   R*f*r*t;
thruput.active_pe_percent   =   thruput.active_pes/J;

end