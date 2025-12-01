using Agents, Random
using StaticArrays: SVector

@agent struct Car(ContinuousAgent{2,Float64})
    speed::Float64 = 0.5
end

@agent struct TrafficLight(ContinuousAgent{2,Float64})
    state::String = "green"
    timer::Int = 0
    offset::Int = 0
end

function traffic_light_ahead(agent::Car, model)
    for neighbor in nearby_agents(agent, model, 10.0)
        if neighbor isa TrafficLight
            if neighbor.pos[1] > agent.pos[1] && abs(neighbor.pos[2] - agent.pos[2]) < 2.0
                return neighbor
            end
        end
    end
    return nothing
end

function agent_step!(agent::Car, model)
    light = traffic_light_ahead(agent, model)
    should_stop = false

    if light !== nothing
        distance_to_light = light.pos[1] - agent.pos[1]
        if (light.state == "yellow" || light.state == "red") && distance_to_light < 6.0
            should_stop = true
        end
    end

    if !should_stop
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

function initialize_model(extent=(100, 100))
    space2d = ContinuousSpace(extent; spacing=0.5, periodic=false)
    rng = Random.MersenneTwister()

    model = StandardABM(
        Union{Car,TrafficLight},
        space2d;
        rng,
        agent_step!,
        scheduler=Schedulers.ByID()
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
            car_x = rand(rng, valid_positions)
            println("Creando auto en posición: x=$car_x, y=$car_street")
            add_agent!(
                SVector{2,Float64}(car_x, Float64(car_street)),
                Car,
                model,
                SVector{2,Float64}(0.5, 0.0),
                0.5
            )
            println("Auto creado exitosamente en carril $car_street")
        else
            println("ERROR: No hay posiciones válidas para el auto en carril $car_street")
        end
    end

    return model
end