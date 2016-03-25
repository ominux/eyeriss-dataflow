function [E, breakdown] = get_energy_cost(access)
    
    % energy cost ratio
%     cost_alu                =   1;
    cost_reg_read           =   1;
    cost_reg_write          =   1;
    cost_array_wiring       =   2;
    cost_buff_read          =   6;
    cost_buff_write         =   6;
    cost_mem_read           =   100;
    cost_mem_write          =   100;

    % calculate energy cost                        
    breakdown.memory        =   access.memory.reads.total   * cost_mem_read     + ...
                                access.memory.writes.total  * cost_mem_write;
    breakdown.buffer        =   access.buffer.reads.total   * cost_buff_read    + ...
                                access.buffer.writes.total  * cost_buff_write;
    breakdown.array         =   access.array.wiring.total   * cost_array_wiring;
    breakdown.reg           =   access.reg.reads.total      * cost_reg_read     + ...
                                access.reg.writes.total     * cost_reg_write;
                            
    E                       =   breakdown.memory    + ...
                                breakdown.buffer    + ...
                                breakdown.array     + ...
                                breakdown.reg       ;

end