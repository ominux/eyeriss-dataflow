function area = get_storage_area_from_size(size)

    % size is in byte

    if      size >= 4096
        area_per_byte       =   12.70;
    elseif  size >= 2048
        area_per_byte       =   interp1([2048 4096], [ 13.89  12.70], size);
    elseif  size >= 1024
        area_per_byte       =   interp1([1024 2048], [ 16.14  13.89], size);
    elseif  size >= 512
        area_per_byte       =   interp1([ 512 1024], [ 20.87  16.14], size);
    elseif  size >= 256
        area_per_byte       =   interp1([ 256  512], [ 27.48  20.87], size);
    elseif  size >= 128
        area_per_byte       =   interp1([ 128  256], [ 39.94  27.48], size);
    elseif  size >= 64
        area_per_byte       =   interp1([  64  128], [ 59.15  39.94], size);
    elseif  size >= 32
        area_per_byte       =   interp1([  32   64], [ 96.06  59.15], size);
    elseif  size >= 16
        area_per_byte       =   interp1([  16   32], [169.89  96.06], size);
    elseif  size >= 8
        area_per_byte       =   interp1([   8   16], [177.07 169.89], size);
    elseif  size >= 4
        area_per_byte       =   interp1([   4    8], [172.07 177.07], size);
    elseif  size >= 2
        area_per_byte       =   interp1([   2    4], [103.47 172.07], size);
    else
        area_per_byte       =   103.47;
    end

    area                    =   area_per_byte * size;
    
end