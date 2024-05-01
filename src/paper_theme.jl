theme_paper(; kwargs...) = merge(theme_aps(; usetexfont=false, kwargs...), overwrite_theme())
theme_paper_2col(; kwargs...) = merge(theme_aps_2col(; usetexfont=false, kwargs...), overwrite_theme())

function overwrite_theme()
    fonts = (; regular="/System/Library/Fonts/Supplemental/Arial.ttf", bold="/System/Library/Fonts/Supplemental/Arial Bold.ttf")
    label = (; fontsize=12, font=:bold)
    text = (; fontsize=12, font=:regular)
    legend = (; patchsize=(10, 20))

    Theme(fonts=fonts, Label=label, Text=text, colgap=8, rowgap=8, Legend=legend)
end

const SEQ_COL = Dict(1.1 => colorant"#edf8fb", 1.25 => colorant"#bfd3e6", 1.5 => colorant"#9ebcda", 2.0 => colorant"#8c96c6", 4.0 => colorant"#8856a7", 10.0 => colorant"#810f7c")