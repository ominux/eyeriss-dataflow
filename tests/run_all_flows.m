function results = run_all_flows(J, A, N, model_name, layer_id, WL, num_trials)

    if      strcmp(model_name, 'alexnet')
        [G, H, R, U, C, M, E, alpha, ~] =   get_alexnet_params(layer_id);
    elseif  strcmp(model_name, 'vgg16')
        [G, H, R, U, C, M, E, alpha, ~] =   get_vgg16_params(layer_id);
    else
        error(['cannot recognize model name: ' model_name]);
    end

    % row stationary
    RF_byte                         =   256 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   rs_flow         (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials); 
    [~, results.RS.energy]          =   get_energy_cost(access);
    results.RS.thruput              =   thruput.active_pes;
    results.RS.params               =   params;
    results.RS.access               =   access;
    % weight stationary
    RF_byte                         =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   ws_flow         (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials);
    [~, results.WS.energy]          =   get_energy_cost(access);
    results.WS.thruput              =   thruput.active_pes;
    results.WS.params               =   params;
    results.WS.access               =   access;
    % output stationary soc-mop
    RF_byte                         =   (1+U+R*U) * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_soc_mop_flow (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials);
    [~, results.OS_SOC_MOP.energy]  =   get_energy_cost(access);
    results.OS_SOC_MOP.thruput      =   thruput.active_pes;
    results.OS_SOC_MOP.params       =   params;
    results.OS_SOC_MOP.access       =   access;
    % output stationary moc-mop
    RF_byte                         =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_moc_mop_flow (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials);
    [~, results.OS_MOC_MOP.energy]  =   get_energy_cost(access);
    results.OS_MOC_MOP.thruput      =   thruput.active_pes;
    results.OS_MOC_MOP.params       =   params;
    results.OS_MOC_MOP.access       =   access;
    % output stationary moc-sop
    RF_byte                         =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_moc_sop_flow (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials);
    [~, results.OS_MOC_SOP.energy]  =   get_energy_cost(access);
    results.OS_MOC_SOP.thruput      =   thruput.active_pes;
    results.OS_MOC_SOP.params       =   params;
    results.OS_MOC_SOP.access       =   access;
    % no local reuse
    RF_byte                         =   0; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   nlr_flow    (G, N, C, M, H, R, E, U, alpha, J, Q_byte, RF_byte, WL, num_trials);
    [~, results.NLR.energy]         =   get_energy_cost(access);
    results.NLR.thruput             =   thruput.active_pes;
    results.NLR.params              =   params;
    results.NLR.access              =   access;
end