function A = get_total_storage_area(J2, buffer_size, reg_size_per_pe)

    % both buffer size and reg size/PE are in byte
    
    buffer_area         =   get_storage_area_from_size(buffer_size);
    reg_area_per_pe     =   get_storage_area_from_size(reg_size_per_pe);
    
    A                   =   J2 * reg_area_per_pe + buffer_area;

end