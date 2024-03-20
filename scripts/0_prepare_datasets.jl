using DrWatson
@quickactivate :CoolWalks

# setup data directories
!isdir(projectdir("data", "exp_raw")) ? mkdir(projectdir("data", "exp_raw")) : nothing
!isdir(projectdir("data", "exp_pro")) ? mkdir(projectdir("data", "exp_pro")) : nothing

# setup plots directory
!isdir(projectdir("plots")) ? mkdir(projectdir("plots")) : nothing

# download new york

# download barcelona

# download valencia
