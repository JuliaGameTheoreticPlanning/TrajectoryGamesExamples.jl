using TrajectoryGamesBase:
    TrajectoryGamesBase, TrajectoryGame, RecedingHorizonStrategy, num_players, rollout
using TrajectoryGamesExamples: TestUtils, animate_sim_steps, two_player_meta_tag

using Test: @testset
using BlockArrays: mortar
using GLMakie: GLMakie
using Makie: Makie
using Random: MersenneTwister

@testset "TrajectoryGamesExamples" begin
    for (description, game) in [("meta tag", two_player_meta_tag())]
        @testset "$description" begin
            if num_players(game) == 2
                initial_state = mortar([[-1.0, 0.0, 0.0, 0.0], [1.0, 0.0, 0.0, 0.0]])
            elseif num_players(game) == 3
                initial_state =
                    mortar([[0.0, 0.0, 0.0, 0.0], [-1.0, 0.0, 0.0, 0.0], [1.0, 0.0, 0.0, 0.0]])
            else
                error("No config for games of this size.")
            end

            planning_horizon = 20
            rng = MersenneTwister(1)
            turn_length = 10

            @testset "Receding horizon" begin
                solver = TestUtils.MockSolver()
                receding_horizon_strategy =
                    RecedingHorizonStrategy(; solver, game, turn_length = 10)

                local sim_steps

                @testset "rollout" begin
                    sim_steps = rollout(
                        game.dynamics,
                        receding_horizon_strategy,
                        initial_state,
                        100;
                        get_info = (γ, x, t) -> γ.receding_horizon_strategy,
                    )
                end

                @testset "animation" begin
                    animate_sim_steps(game, sim_steps; live = false, framerate = 30)
                end
            end
        end
    end
end
