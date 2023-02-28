function planar_double_integrator(; dt = 0.1, m = 1, kwargs...)
    dt2 = 0.5 * dt * dt
    # Layout is x := (px, py, vx, vy) and u := (ax, ay).
    time_invariant_linear_dynamics(;
        A = [
            1.0 0.0 dt 0.0
            0.0 1.0 0.0 dt
            0.0 0.0 1.0 0.0
            0.0 0.0 0.0 1.0
        ],
        B = [
            dt2 0.0
            0.0 dt2
            dt 0.0
            0.0 dt
        ] / m,
        kwargs...,
    )
end

struct UnicycleDynamics{T1,T2} <: AbstractDynamics
    dt::Float64
    m::Float64
    state_bounds::T1
    control_bounds::T2
    integration_scheme::Symbol

    function UnicycleDynamics(;
        dt = 0.1,
        m = 1.0,
        state_bounds::T1 = (; lb = [-Inf, -Inf, -Inf, -Inf], ub = [Inf, Inf, Inf, Inf]),
        control_bounds::T2 = (; lb = [-Inf, -Inf], ub = [Inf, Inf]),
        integration_scheme = :forward_euler,
    ) where {T1,T2}
        supported_integration_schemes = (:forward_euler, :reverse_euler, :hybrid)
        integration_scheme ∈ supported_integration_schemes ||
            throw(ArgumentError("integration_scheme must be one of $supported_integration_schemes"))
        new{T1,T2}(dt, m, state_bounds, control_bounds, integration_scheme)
    end
end

function TrajectoryGamesBase.horizon(sys::UnicycleDynamics)
    ∞
end

function TrajectoryGamesBase.state_dim(dynamics::UnicycleDynamics)
    4
end

function TrajectoryGamesBase.control_dim(dynamics::UnicycleDynamics)
    2
end

function TrajectoryGamesBase.state_bounds(dynamics::UnicycleDynamics)
    dynamics.state_bounds
end

function TrajectoryGamesBase.control_bounds(dynamics::UnicycleDynamics)
    dynamics.control_bounds
end

function (sys::UnicycleDynamics)(state, control, t)
    px, py, v, θ = state
    F, τ = control
    dt = sys.dt
    m = sys.m

    v′ = v + F * dt / m
    θ′ = θ + τ * dt / m

    if sys.integration_scheme === :forward_euler
        px′ = px + cos(θ) * v * dt
        py′ = py + sin(θ) * v * dt
    elseif sys.integration_scheme === :hybrid
        px′ = px + cos(θ) * (v * dt + 0.5 * F * dt^2 / m)
        py′ = py + sin(θ) * (v * dt + 0.5 * F * dt^2 / m)
    elseif sys.integration_scheme === :reverse_euler
        px′ = px + cos(θ′) * v′ * dt
        py′ = py + sin(θ′) * v′ * dt
    end

    # next state
    [px′, py′, v′, θ′]
end

wrap_pi(x) = mod2pi(x + pi) - pi

struct BicycleDynamics{T1,T2} <: AbstractDynamics
    dt::Float64
    l::Float64
    state_bounds::T1
    control_bounds::T2
    integration_scheme::Symbol

    function BicycleDynamics(;
        dt = 0.1,
        l = 1.0,
        state_bounds::T1 = (;
            lb = [-Inf, -Inf, -Inf, -Inf],
            ub = [Inf, Inf, Inf, Inf],
        ),
        control_bounds::T2 = (; lb = [-Inf, -Inf], ub = [Inf, Inf]),
        integration_scheme = :forward_euler,
    ) where {T1,T2}
        supported_integration_schemes = (:forward_euler, :reverse_euler, :hybrid)
        integration_scheme ∈ supported_integration_schemes ||
            throw(ArgumentError("integration_scheme must be one of $supported_integration_schemes"))
        new{T1,T2}(dt, l, state_bounds, control_bounds, integration_scheme)
    end
end

function TrajectoryGamesBase.horizon(sys::BicycleDynamics)
    ∞
end

function TrajectoryGamesBase.state_dim(dynamics::BicycleDynamics)
    4
end

function TrajectoryGamesBase.control_dim(dynamics::BicycleDynamics)
    2
end

function TrajectoryGamesBase.state_bounds(dynamics::BicycleDynamics)
    dynamics.state_bounds
end

function TrajectoryGamesBase.control_bounds(dynamics::BicycleDynamics)
    dynamics.control_bounds
end

function (sys::BicycleDynamics)(state, control, t)
    px, py, v, θ = state
    a, ϕ = control
    dt = sys.dt
    l = sys.l

    tan_approx(x) = x - x^3 / 3 + x^5 / 5
    v′ = v + a * dt

    if sys.integration_scheme === :forward_euler
        θ′ = θ + v / l * tan_approx(ϕ) * dt
        sθ, cθ = sincos(θ)
        px′ = px + cθ * v * dt
        py′ = py + sθ * v * dt
    elseif sys.integration_scheme === :hybrid
        θ′ = θ + v′ / l * tan_approx(ϕ) * dt
        sθ, cθ = sincos(θ)
        px′ = px + cθ * (v * dt + 0.5 * a * dt^2)
        py′ = py + sθ * (v * dt + 0.5 * a * dt^2)
    elseif sys.integration_scheme === :reverse_euler
        θ′ = θ + v′ / l * tan_approx(ϕ) * dt
        sθ′, cθ′ = sincos(θ′)
        px′ = px + cθ′ * v′ * dt
        py′ = py + sθ′ * v′ * dt
    end

    [px′, py′, v′, θ′]
end
