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

Base.@kwdef struct UnicycleDynamics{T1,T2} <: AbstractDynamics
    dt::Float64 = 0.1
    m::Float64 = 1.0
    state_bounds::T1 = (; lb = [-Inf, -Inf, -Inf, -Inf], ub = [Inf, Inf, Inf, Inf])
    control_bounds::T2 = (; lb = [-Inf, -Inf], ub = [Inf, Inf])
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

function (sys::UnicycleDynamics)(state, control, t)
    px, py, v, θ = state
    F, τ = control
    dt = sys.dt
    m = sys.m

    # next state
    [px + cos(θ) * dt, py + sin(θ) * dt, v + F * dt / m, θ + τ * dt / m]
end

wrap_pi(x) = mod2pi(x + pi) - pi
