function E = get_energy_cost(access)
    
    % energy cost ratio
%     cost_alu                =   1;
    cost_reg_read           =   2;
    cost_reg_write          =   2;
    cost_array_wiring       =   5;
    cost_buff_read          =   15;
    cost_buff_write         =   15;
    cost_mem_read           =   500;
    cost_mem_write          =   500;

    % calculate energy cost
    E                       =   access.memory.reads     * cost_mem_read     + ...
                                access.memory.writes    * cost_mem_write    + ...
                                access.buffer.reads     * cost_buff_read    + ...
                                access.buffer.writes    * cost_buff_write   + ...
                                access.array.wiring     * cost_array_wiring + ...
                                access.reg.reads        * cost_reg_read     + ...
                                access.reg.writes       * cost_reg_write    ;
    
end