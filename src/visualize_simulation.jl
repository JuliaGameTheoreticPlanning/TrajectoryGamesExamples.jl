function create_environment_axis(
    figure,
    environment;
    margin = 0.2,
    xlabel = "Horizontal position [m]",
    ylabel = "Vertical position [m]",
    xlabelpadding = 0,
    ylabelpadding = -5,
    viz_kwargs = (;),
    axis_kwargs...,
)
    points = environment.set.vertices
    limit_margins = (-margin, +margin)
    x_limits = extrema(point -> point[1], points) .+ limit_margins
    y_limits = extrema(point -> point[2], points) .+ limit_margins
    aspect = x_limits[2] / y_limits[2]
    limits = (x_limits, y_limits)
    environment_axis = Makie.Axis(
        figure;
        aspect,
        limits,
        xlabel,
        ylabel,
        xlabelpadding,
        ylabelpadding,
        axis_kwargs...,
    )

    visualize!(environment_axis, environment; viz_kwargs...)
    environment_axis
end

function visualize_players!(
    axis,
    players;
    player_colors = range(colorant"red", colorant"blue", length = blocksize(players[], 1)),
)
    for player_i in 1:blocksize(players[], 1)
        player_color = player_colors[player_i]
        position = Makie.@lift Makie.Point2f($players[Block(player_i)][1:2])
        Makie.scatter!(axis, position; color = player_color)
    end
end

function visualize_obstacle_bounds!(
    axis,
    players;
    player_colors = range(colorant"red", colorant"blue", length = blocksize(players[], 1)),
    obstacle_radius = 1.0,
)
    for player_i in 1:blocksize(players[], 1)
        player_color = player_colors[player_i]
        position = Makie.@lift Makie.Point2f($players[Block(player_i)][1:2])
        Makie.scatter!(
            axis,
            position;
            color = (player_color, 0.4),
            markersize = 2 * obstacle_radius,
            markerspace = :data,
        )
    end
end

function visualize_targets!(
    axis,
    targets;
    player_colors = range(colorant"red", colorant"blue", length = blocksize(targets[], 1)),
    marker = "+",
)
    for player_i in 1:blocksize(targets[], 1)
        color = player_colors[player_i]
        target = Makie.@lift Makie.Point2f($targets[Block(player_i)])
        Makie.scatter!(axis, target; color, marker)
    end
end

function visualize_sim_step(
    game,
    step;
    fig = Makie.Figure(),
    ax_kwargs = (;),
    xlims = (-5, 5),
    ylims = (-5, 5),
    aspect = 1,
    player_colors = range(colorant"red", colorant"blue", length = num_players(game)),
    player_names = ["Pursuer", "Evader"],
    weight_offset = 0.0,
    heading = "",
    show_legend = false,
    show_turn = false,
)
    s = Makie.Observable(step)

    if !show_turn
        title = "$heading"
    else
        title = Makie.@lift "$heading\nstep: $($s.turn)"
    end

    ax = Makie.Axis(
        fig[1, 1];
        title,
        aspect,
        limits = (xlims, ylims),
        xlabel = "Horizontal position [m]",
        ylabel = "Vertical position [m]",
        xlabelpadding = 0,
        ylabelpadding = -5,
        ax_kwargs...,
    )

    visualize!(ax, game.env)

    plots = []

    for ii in eachindex(s[].strategy.substrategies)
        color = player_colors[ii]
        γ = Makie.@lift $s.strategy.substrategies[ii]
        pos = Makie.@lift Makie.Point2f($s.state[Block(ii)][1:2])
        scatter = Makie.scatter!(ax, pos; color)
        visualize!(ax, γ; weight_offset, color)
        push!(plots, [scatter])
    end

    if show_legend
        Makie.Legend(fig[0, 1], plots, player_names, orientation = :horizontal, halign = :left)
    end

    fig, s
end

# TODO: this should probably live somewhere else
function animate_sim_steps(
    game::TrajectoryGame,
    steps;
    filename = "sim_steps",
    heading = filename,
    framerate = 10,
    live = true,
    kwargs...,
)
    fig, s = visualize_sim_step(game, steps[begin]; heading, kwargs...)

    Makie.record(fig, "$filename.mp4", steps; framerate) do step
        dt = @elapsed s[] = step
        if live
            time_to_sleep = 1 / framerate - dt
            sleep(max(time_to_sleep, 0.0))
        end
    end
    fig
end

function animate_sim_steps(game::TrajectoryGame, steps::NamedTuple; kwargs...)
    states, inputs, strategies = steps
    sim_steps =
        map(Iterators.countfrom(), states, inputs, strategies) do turn, state, control, strategy
            (; turn, state, control, strategy)
        end

    animate_sim_steps(game, sim_steps; kwargs...)
end
