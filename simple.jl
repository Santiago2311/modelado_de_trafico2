using Agents, Random
using StaticArrays: SVector

@agent struct Car(ContinuousAgent{2,Float64})
    speed::Float64 = 0.5
    max_speed::Float64 = 1.0
    min_speed::Float64 = 0.1
end

@agent struct TrafficLight(ContinuousAgent{2,Float64})
    state::String = "green"
    timer::Int = 0
    offset::Int = 0
end

function car_ahead(agent::Car, model, distance=15.0)
    min_distance = distance
    closest_car = nothing

    for neighbor in nearby_agents(agent, model, distance)
        if neighbor isa Car && neighbor.id != agent.id
            if neighbor.pos[1] > agent.pos[1] && abs(neighbor.pos[2] - agent.pos[2]) < 2.0
                dist = neighbor.pos[1] - agent.pos[1]
                if dist < min_distance
                    min_distance = dist
                    closest_car = neighbor
                end
            end
        end
    end

    return closest_car, min_distance
end

function traffic_light_ahead(agent::Car, model)
    for neighbor in nearby_agents(agent, model, 15.0)
        if neighbor isa TrafficLight
            if neighbor.pos[1] > agent.pos[1] && abs(neighbor.pos[2] - agent.pos[2]) < 2.0
                return neighbor, neighbor.pos[1] - agent.pos[1]
            end
        end
    end
    return nothing, Inf
end

function agent_step!(agent::Car, model)
    light, light_distance = traffic_light_ahead(agent, model)
    car, car_distance = car_ahead(agent, model)
    should_stop = false
    should_slow = false

    if light !== nothing
        if (light.state == "yellow" || light.state == "red") && light_distance < 8.0
            should_stop = true
        elseif (light.state == "yellow" || light.state == "red") && light_distance < 12.0
            should_slow = true
        end
    end

    if car !== nothing && car_distance < 5.0
        should_stop = true
    elseif car !== nothing && car_distance < 10.0
        should_slow = true
    end

    if should_stop
        agent.speed = max(agent.min_speed, agent.speed - 0.2)
    elseif should_slow
        agent.speed = max(agent.min_speed, agent.speed - 0.1)
    else
        agent.speed = min(agent.max_speed, agent.speed + 0.1)
    end

    if agent.speed > agent.min_speed
        new_x = agent.pos[1] + agent.speed

        if new_x >= 100.0
            new_pos = SVector{2,Float64}(0.0, agent.pos[2])
            move_agent!(agent, new_pos, model)
        else
            new_pos = SVector{2,Float64}(new_x, agent.pos[2])
            move_agent!(agent, new_pos, model)
        end
    end
end

function agent_step!(agent::TrafficLight, model)
    agent.timer += 1

    effective_time = agent.timer + agent.offset
    cycle_time = effective_time % 28

    if cycle_time < 10
        agent.state = "green"
    elseif cycle_time < 14
        agent.state = "yellow"
    else
        agent.state = "red"
    end
end

function initialize_model(cars_per_street=5, extent=(100, 100))
    space2d = ContinuousSpace(extent; spacing=0.5, periodic=false)
    rng = Random.MersenneTwister()

    properties = Dict(:total_speed => 0.0, :car_count => 0, :step_count => 0)

    model = StandardABM(
        Union{Car,TrafficLight},
        space2d;
        rng,
        agent_step!,
        scheduler=Schedulers.ByID(),
        properties=properties
    )

    streets = [20, 40, 60, 80]

    for x in streets
        for y in streets
            add_agent!(
                SVector{2,Float64}(Float64(x - 5), Float64(y)),
                TrafficLight,
                model,
                SVector{2,Float64}(0.0, 0.0),
                "green",
                0,
                0
            )

            add_agent!(
                SVector{2,Float64}(Float64(x), Float64(y - 5)),
                TrafficLight,
                model,
                SVector{2,Float64}(0.0, 0.0),
                "red",
                0,
                14
            )
        end
    end

    for car_street in streets
        valid_positions = Float64[]
        for pos in 1:99
            is_valid = true
            for street_x in streets
                if pos >= (street_x - 12) && pos <= (street_x + 2)
                    is_valid = false
                    break
                end
            end
            if is_valid
                push!(valid_positions, Float64(pos))
            end
        end

        if !isempty(valid_positions)
            for i in 1:cars_per_street
                car_x = rand(rng, valid_positions)
                initial_speed = rand(rng) * 0.8 + 0.2

                add_agent!(
                    SVector{2,Float64}(car_x, Float64(car_street)),
                    Car,
                    model,
                    SVector{2,Float64}(initial_speed, 0.0),
                    initial_speed,
                    1.0,
                    0.1
                )

                filter!(x -> abs(x - car_x) > 10.0, valid_positions)

                if isempty(valid_positions)
                    break
                end
            end
        end
    end

    return model
end

function model_step!(model)
    model.step_count += 1
    total_speed = 0.0
    car_count = 0

    for agent in allagents(model)
        if agent isa Car
            total_speed += agent.speed
            car_count += 1
        end
    end

    model.total_speed = total_speed
    model.car_count = car_count
end

function get_average_speed(model)
    if model.car_count > 0
        return model.total_speed / model.car_count
    else
        return 0.0
    end
end