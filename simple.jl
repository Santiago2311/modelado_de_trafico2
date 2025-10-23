using Agents, Random
using StaticArrays: SVector

# @agent struct Car(ContinuousAgent{2,Float64})
#     accelerating::Bool = true
# end

@agent struct TrafficLight(ContinuousAgent{2,Float64})
    state::String = "green"
    timer::Int = 0
    offset::Int = 0
end

# accelerate(agent) = agent.vel[1] + 0.05
# decelerate(agent) = agent.vel[1] - 0.1

# function car_ahead(agent, model)
#     for neighbor in nearby_agents(agent, model, 1.0)
#         if neighbor.pos[1] > agent.pos[1]
#             return neighbor
#         end
#     end
#     nothing
# end

# function agent_step!(agent::Car, model)
#     new_velocity = agent.accelerating ? accelerate(agent) : decelerate(agent)
#     if new_velocity >= 1.0
#         new_velocity = 1.0
#         agent.accelerating = false
#     elseif new_velocity <= 0.0
#         new_velocity = 0.0
#         agent.accelerating = true
#     end
#     agent.vel = (new_velocity, 0.0)
#     move_agent!(agent, model, 0.4)
# end

function agent_step!(agent::TrafficLight, model)
    agent.timer += 1

    # Apply offset to the synchronization
    effective_time = agent.timer + agent.offset
    # Complete cycle -> 10 ticks green + 4 ticks yellow + 14 ticks red = 28 ticks
    cycle_time = effective_time % 28

    if cycle_time < 10
        agent.state = "green"
    elseif cycle_time < 14
        agent.state = "yellow"
    else
        agent.state = "red"
    end
end

function initialize_model(extent=(100, 100))
    space2d = ContinuousSpace(extent; spacing=0.5, periodic=false)
    rng = Random.MersenneTwister()
    model = StandardABM(TrafficLight, space2d; rng, agent_step!, scheduler=Schedulers.Randomly())

    streets = [20, 40, 60, 80]

    for x in streets
        for y in streets
            # Horizontal trafficlight
            # Starts with offset = 0 (green)
            add_agent!(
                SVector{2,Float64}(Float64(x - 5), Float64(y)),
                model;
                vel=SVector{2,Float64}(0.0, 0.0),
                state="green",
                timer=0,
                offset=0
            )

            # Vertical trafficlight
            # Starts with offset = 14 (red)
            add_agent!(
                SVector{2,Float64}(Float64(x), Float64(y - 5)),
                model;
                vel=SVector{2,Float64}(0.0, 0.0),
                state="red",
                timer=0,
                offset=14
            )
        end
    end

    model
end