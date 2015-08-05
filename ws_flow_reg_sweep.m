function [results, energy_bar_plot_array] = ws_flow_reg_sweep(J2, A, N, alexnet_layer_id, WL, G_byte_sweep, num_trials)

    [H, R, U, C, M, E, alpha]                   =   get_alexnet_params(alexnet_layer_id);
    
    % result arrays
    results                                     =   cell(size(G_byte_sweep));
    energy_bar_plot_array                       =   zeros(1, length(G_byte_sweep));
    
    % run flow optimization
    for i = 1:length(G_byte_sweep)
        Q_byte                                  =   get_buffer_size(A, J2, G_byte_sweep(i));
        [access, reuse, params]                 =   ws_flow(N, C, M, H, R, E, U, alpha, J2, Q_byte, G_byte_sweep(i), WL, num_trials);
        % collect result
        params.J2                               =   J2;
        params.A                                =   A;
        params.G_byte                           =   G_byte_sweep(i);
        params.Q_byte                           =   Q_byte;
        params.total_storage_byte               =   (G_byte_sweep(i) * J2 + Q_byte);
        params.alexnet_layer_id                 =   alexnet_layer_id;
        results{i}.reuse                        =   reuse;
        results{i}.access                       =   access;
        results{i}.params                       =   params;
        results{i}.energy_cost                  =   get_energy_cost(access);
        energy_bar_plot_array(i)                =   results{i}.energy_cost;
    end
end