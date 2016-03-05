function buffer_size = get_buffer_size(storage_area, num_pes, reg_size_per_pe)

    % total register size in the array [bytes]
    reg_area_per_pe                         =   get_storage_area_from_size(reg_size_per_pe);
    total_reg_area                          =   num_pes * reg_area_per_pe;
    
    buffer_area                             =   storage_area - total_reg_area;
    buffer_size                             =   get_storage_size_from_area(buffer_area);
end