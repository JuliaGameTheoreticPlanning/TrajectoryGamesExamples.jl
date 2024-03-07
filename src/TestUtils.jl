module TestUtils

using TrajectoryGamesBase:
    TrajectoryGamesBase, JointStrategy, TrajectoryGame, control_dim, num_players
using Makie: Makie

#=== strategy ===#

struct MockStrategy{T<:TrajectoryGame}
    game::T
    player_index::Int
end

function (strategy::MockStrategy)(x, t)
    zeros(control_dim(strategy.game.dynamics, strategy.player_index))
end

#=== solver ===#

struct MockSolver end

function TrajectoryGamesBase.solve_trajectory_game!(::MockSolver, game, initial_state)
    JointStrategy([MockStrategy(game, ii) for ii in 1:num_players(game)])
end

end
