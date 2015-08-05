function buffer_size = buffer_size(storage_area, num_pes, reg_size_per_pe)

    % total register size in the array [bytes]
    regs_area_per_byte                      =   0;
    if      reg_size_per_pe >= 4096
        regs_area_per_byte                  =   12.70;
    elseif  reg_size_per_pe >= 2048
        regs_area_per_byte                  =   interp1([2048 4096], [ 13.89  12.70], reg_size_per_pe);
    elseif  reg_size_per_pe >= 1024
        regs_area_per_byte                  =   interp1([1024 2048], [ 16.14  13.89], reg_size_per_pe);
    elseif  reg_size_per_pe >= 512
        regs_area_per_byte                  =   interp1([ 512 1024], [ 20.87  16.14], reg_size_per_pe);
    elseif  reg_size_per_pe >= 256
        regs_area_per_byte                  =   interp1([ 256  512], [ 27.48  20.87], reg_size_per_pe);
    elseif  reg_size_per_pe >= 128
        regs_area_per_byte                  =   interp1([ 128  256], [ 39.94  27.48], reg_size_per_pe);
    elseif  reg_size_per_pe >= 64
        regs_area_per_byte                  =   interp1([  64  128], [ 59.15  39.94], reg_size_per_pe);
    elseif  reg_size_per_pe >= 32
        regs_area_per_byte                  =   interp1([  32   64], [ 96.06  59.15], reg_size_per_pe);
    elseif  reg_size_per_pe >= 16
        regs_area_per_byte                  =   interp1([  16   32], [169.89  96.06], reg_size_per_pe);
    elseif  reg_size_per_pe >= 8
        regs_area_per_byte                  =   interp1([   8   16], [177.07 169.89], reg_size_per_pe);
    elseif  reg_size_per_pe >= 4
        regs_area_per_byte                  =   interp1([   4    8], [172.07 177.07], reg_size_per_pe);
    elseif  reg_size_per_pe >= 2
        regs_area_per_byte                  =   interp1([   2    4], [103.47 172.07], reg_size_per_pe);
    end
    
    total_regs_area                         =   num_pes * reg_size_per_pe * regs_area_per_byte;
    
    buffer_area                             =   storage_area - total_regs_area;
    
    buffer_size                             =   0;
    if      buffer_area >= 52020
        buffer_size                         =   buffer_area / 52020 * 4096;
    elseif  buffer_area >= 28455
        buffer_size                         =   interp1([28455 52020], [2048 4096], buffer_area);
    elseif  buffer_area >= 16523
        buffer_size                         =   interp1([16523 28455], [1024 2048], buffer_area);
    elseif  buffer_area >= 10685
        buffer_size                         =   interp1([10685 16523], [ 512 1024], buffer_area);
    elseif  buffer_area >= 7034
        buffer_size                         =   interp1([ 7034 10685], [ 256  512], buffer_area);
    elseif  buffer_area >= 5112
        buffer_size                         =   interp1([ 5112  7034], [ 128  256], buffer_area);
    elseif  buffer_area >= 3785
        buffer_size                         =   interp1([ 3785  5112], [  64  128], buffer_area);
    elseif  buffer_area >= 3074
        buffer_size                         =   interp1([ 3074  3785], [  32   64], buffer_area);
    elseif  buffer_area >= 2718
        buffer_size                         =   interp1([ 2718  3074], [  16   32], buffer_area);
    elseif  buffer_area >= 1417
        buffer_size                         =   interp1([ 1417  2718], [   8   16], buffer_area);
    elseif  buffer_area >= 689
        buffer_size                         =   interp1([  689  1417], [   4    8], buffer_area);
    elseif  buffer_area >= 207
        buffer_size                         =   interp1([  207   689], [   2    4], buffer_area);
    end
end