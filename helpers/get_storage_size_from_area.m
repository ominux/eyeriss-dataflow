function size = get_storage_size_from_area(area)

    size                             =   0;
    if      area >= 52020
        size                         =   area / 52020 * 4096;
    elseif  area >= 28455
        size                         =   interp1([28455 52020], [2048 4096], area);
    elseif  area >= 16523
        size                         =   interp1([16523 28455], [1024 2048], area);
    elseif  area >= 10685
        size                         =   interp1([10685 16523], [ 512 1024], area);
    elseif  area >= 7034
        size                         =   interp1([ 7034 10685], [ 256  512], area);
    elseif  area >= 5112
        size                         =   interp1([ 5112  7034], [ 128  256], area);
    elseif  area >= 3785
        size                         =   interp1([ 3785  5112], [  64  128], area);
    elseif  area >= 3074
        size                         =   interp1([ 3074  3785], [  32   64], area);
    elseif  area >= 2718
        size                         =   interp1([ 2718  3074], [  16   32], area);
    elseif  area >= 1417
        size                         =   interp1([ 1417  2718], [   8   16], area);
    elseif  area >= 689
        size                         =   interp1([  689  1417], [   4    8], area);
    elseif  area >= 207
        size                         =   interp1([  207   689], [   2    4], area);
    end

end