using DrWatson
@quickactivate :CoolWalks

# setup data directories
!isdir(projectdir("data", "exp_raw")) ? mkpath(projectdir("data", "exp_raw")) : nothing
!isdir(projectdir("data", "exp_pro")) ? mkpath(projectdir("data", "exp_pro")) : nothing

# setup plots directory
!isdir(projectdir("plots")) ? mkdir(projectdir("plots")) : nothing

# setup city directories
manhattan_dir = projectdir("data", "exp_raw", "manhattan")
!isdir(manhattan_dir) ? mkpath(manhattan_dir) : nothing

barcelona_dir = projectdir("data", "exp_raw", "barcelona")
!isdir(barcelona_dir) ? mkpath(barcelona_dir) : nothing

valencia_dir = projectdir("data", "exp_raw", "valencia")
!isdir(valencia_dir) ? mkpath(valencia_dir) : nothing


# check manhattan setup
manhattan_files = [
    ["network_bike.json"],
    ["network_walk.json"],
    [["buildings", "manhattan." * i] for i in ["cpg", "dbf", "prj", "qmd", "shp", "shx"]]...
]
for file in manhattan_files
    if !isfile(joinpath(manhattan_dir, file...))
        @warn "Manhattan file missing: ", joinpath(manhattan_dir, file...)
    end
end

# check barcelona setup
barcelona_files = [
    "network_bike.json",
    "network_walk.json",
    "buildings.geojson"
]
for file in barcelona_files
    if !isfile(joinpath(barcelona_dir, file))
        @warn "Barcelona file missing: ", joinpath(barcelona_dir, file...)
    end
end

# check valencia setup
valencia_files = [
    "network_bike.json",
    "network_walk.json",
    "buildings.geojson"
]
for file in valencia_files
    if !isfile(joinpath(valencia_dir, file))
        @warn "valencia file missing: ", joinpath(valencia_dir, file...)
    end
end