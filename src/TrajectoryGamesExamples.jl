module TrajectoryGamesExamples

using TrajectoryGamesBase:
    TrajectoryGamesBase,
    AbstractDynamics,
    PolygonEnvironment,
    ProductDynamics,
    TimeSeparableTrajectoryGameCost,
    TrajectoryGame,
    ZeroSumCostStructure,
    num_players,
    time_invariant_linear_dynamics,
    visualize!
using LinearAlgebra: norm, norm_sqr
using BlockArrays: Block, blocks, blocksize
using InfiniteArrays: ∞

using Makie: Makie
using Colors: @colorant_str

# model tools
include("dynamics.jl")
export planar_double_integrator

# test utils
include("TestUtils.jl")

# visualization
include("visualize_simulation.jl")
export animate_sim_steps,
    create_environment_axis,#
    visualize_players!,
    visualize_obstacle_bounds!,
    visualize_targets!

# games
include("two_player_meta_tag.jl")
export two_player_meta_tag

end
