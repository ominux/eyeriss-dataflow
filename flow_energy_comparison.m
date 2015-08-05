function results = flow_energy_comparison(J2, A, N, alexnet_layer_id, WL, num_trials)

    [H, R, U, C, M, E, alpha] =   get_alexnet_params(alexnet_layer_id);

    % row stationary
    G_byte              =   256 * WL; 
    Q_byte              =   buffer_size(A, J2, G_byte);
    [access, ~, ~]      =   rs_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials); 
    results(1)          =   get_energy_cost(access);
    % channel reuse
    G_byte              =   0; 
    Q_byte              =   buffer_size(A, J2, G_byte);
    [access, ~, ~]      =   nlr_flow    (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results(2)          =   get_energy_cost(access);
    % output stationary (ibm)
    G_byte              =   1 * WL; 
    Q_byte              =   buffer_size(A, J2, G_byte);
    [access, ~, ~]      =   os_ibm_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results(3)          =   get_energy_cost(access);
    % output stationary (shidiannao)
    G_byte              =   (U+R*U) * WL; 
    Q_byte              =   buffer_size(A, J2, G_byte);
    [access, ~, ~]      =   os_sdn_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results(4)          =   get_energy_cost(access);
    % weight stationary
    G_byte              =   128 * WL; 
    Q_byte              =   buffer_size(A, J2, G_byte);
    [access, ~, ~]      =   ws_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    results(5)          =   get_energy_cost(access);

end