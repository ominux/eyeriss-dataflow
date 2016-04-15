function results = run_all_flows(N, model_params, A, J, WL, energy_ratios, num_trials)
    %% row stationary -----------------------------------------------------
    RF_byte                         =   256 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   rs_flow         (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials); 
    results.RS.thruput              =   thruput;
    results.RS.params               =   params;
    results.RS.access               =   access;
    %% weight stationary --------------------------------------------------
    RF_byte                         =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   ws_flow         (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
    results.WS.thruput              =   thruput;
    results.WS.params               =   params;
    results.WS.access               =   access;
    %% output stationary soc-mop ------------------------------------------
%     RF_byte                         =   (1+model_params.U+model_params.R*model_params.U) * WL; 
    RF_byte                         =   (1 + 4 + 4*11) * WL;
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_soc_mop_flow (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
    results.OS_SOC_MOP.thruput      =   thruput;
    results.OS_SOC_MOP.params       =   params;
    results.OS_SOC_MOP.access       =   access;
    %% output stationary moc-mop ------------------------------------------
%     RF_byte                         =   (1+model_params.U) * WL; 
    RF_byte                         =   (1+4) * WL;
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_moc_mop_flow (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
    results.OS_MOC_MOP.thruput      =   thruput;
    results.OS_MOC_MOP.params       =   params;
    results.OS_MOC_MOP.access       =   access;
    %% output stationary moc-sop ------------------------------------------
    RF_byte                         =   1 * WL; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   os_moc_sop_flow (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
    results.OS_MOC_SOP.thruput      =   thruput;
    results.OS_MOC_SOP.params       =   params;
    results.OS_MOC_SOP.access       =   access;
    %% no local reuse -----------------------------------------------------
    RF_byte                         =   0; 
    Q_byte                          =   get_buffer_size(A, J, RF_byte);
    [access, ~, params, thruput]    =   nlr_flow        (N, model_params, J, Q_byte, RF_byte, WL, energy_ratios, num_trials);
    results.NLR.thruput             =   thruput;
    results.NLR.params              =   params;
    results.NLR.access              =   access;
end