function results = flow_energy_comparison(J2, A, N, alexnet_layer_id, WL, num_trials)

    [H, R, U, C, M, E, alpha] =   get_alexnet_params(alexnet_layer_id);

    results.energy          =   zeros(1,5);
    results.thruput         =   zeros(1,5);
    
    % row stationary
    G_byte                  =   256 * WL; 
    Q_byte                  =   get_buffer_size(A, J2, G_byte);
    [access, ~, ~, thruput] =   rs_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials); 
    results.energy(1)       =   get_energy_cost(access);
    results.thruput(1)      =   thruput.active_pes;
    % channel reuse
    G_byte                  =   0; 
    Q_byte                  =   get_buffer_size(A, J2, G_byte);
    [access, ~, ~, thruput] =   nlr_flow    (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results.energy(2)       =   get_energy_cost(access);
    results.thruput(2)      =   thruput.active_pes;
    % output stationary (ibm)
    G_byte                  =   1 * WL; 
    Q_byte                  =   get_buffer_size(A, J2, G_byte);
    [access, ~, ~, thruput] =   os_ibm_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results.energy(3)       =   get_energy_cost(access);
    results.thruput(3)      =   thruput.active_pes;
    % output stationary (shidiannao)
    G_byte                  =   (U+R*U) * WL; 
    Q_byte                  =   get_buffer_size(A, J2, G_byte);
    [access, ~, ~, thruput] =   os_sdn_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results.energy(4)       =   get_energy_cost(access);
    results.thruput(4)      =   thruput.active_pes;
    % weight stationary
    G_byte                  =   128 * WL; 
    Q_byte                  =   get_buffer_size(A, J2, G_byte);
    [access, ~, ~, thruput] =   ws_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results.energy(5)       =   get_energy_cost(access);
    results.thruput(5)      =   thruput.active_pes;

end