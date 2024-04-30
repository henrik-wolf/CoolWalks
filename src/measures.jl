function coolwalkability(a, len_a, len_1)
    relative_fl = felt_length(len_a) / felt_length(len_1)
    result = (a - relative_fl) / (a - 1)
    return result
end

function shadow_fraction(sw)
    sw.shade / real_length(sw)
end

sun_fraction(sw) = 1 - shadow_fraction(sw)