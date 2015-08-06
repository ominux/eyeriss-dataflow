function results = run_all_flows(J2, A, N, alexnet_layer_id, WL, num_trials)

    [H, R, U, C, M, E, alpha] =   get_alexnet_params(alexnet_layer_id);

    % row stationary
    G_byte                          =   256 * WL; 
    Q_byte                          =   get_buffer_size(A, J2, G_byte);
    [access, ~, params, thruput]    =   rs_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials); 
    [~, results.RS.energy]          =   get_energy_cost(access);
    results.RS.thruput              =   thruput.active_pes;
    results.RS.params               =   params;
    results.RS.access               =   access;
    % no local reuse
    G_byte                          =   0; 
    Q_byte                          =   get_buffer_size(A, J2, G_byte);
    [access, ~, params, thruput]    =   nlr_flow    (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, results.NLR.energy]         =   get_energy_cost(access);
    results.NLR.thruput             =   thruput.active_pes;
    results.NLR.params              =   params;
    results.NLR.access              =   access;
    % output stationary (ibm)
    G_byte                          =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J2, G_byte);
    [access, ~, params, thruput]    =   os_ibm_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, results.OS_IBM.energy]      =   get_energy_cost(access);
    results.OS_IBM.thruput          =   thruput.active_pes;
    results.OS_IBM.params           =   params;
    results.OS_IBM.access           =   access;
    % output stationary (shidiannao)
    G_byte                          =   (U+R*U) * WL; 
    Q_byte                          =   get_buffer_size(A, J2, G_byte);
    [access, ~, params, thruput]    =   os_sdn_flow (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, results.OS_SDN.energy]      =   get_energy_cost(access);
    results.OS_SDN.thruput          =   thruput.active_pes;
    results.OS_SDN.params           =   params;
    results.OS_SDN.access           =   access;
    % weight stationary
    G_byte                          =   128 * WL; 
    Q_byte                          =   get_buffer_size(A, J2, G_byte);
    [access, ~, params, thruput]    =   ws_flow     (N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte, WL, num_trials);
    [~, results.WS.energy]          =   get_energy_cost(access);
    results.WS.thruput              =   thruput.active_pes;
    results.WS.params               =   params;
    results.WS.access               =   access;

end