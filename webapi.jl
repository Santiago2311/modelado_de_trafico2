include("simple.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

route("/simulations", method=POST) do
    try
        payload = jsonpayload()
        cars_per_street = get(payload, "cars_per_street", 5)

        model = initialize_model(cars_per_street, (100, 100))
        id = string(uuid1())
        instances[id] = model

        agents_data = []
        for agent in allagents(model)
            agent_dict = Dict(
                "id" => agent.id,
                "pos" => [agent.pos[1], agent.pos[2]]
            )
            if agent isa TrafficLight
                agent_dict["type"] = "trafficlight"
                agent_dict["state"] = agent.state
                agent_dict["timer"] = agent.timer
                agent_dict["offset"] = agent.offset
            elseif agent isa Car
                agent_dict["type"] = "car"
                agent_dict["speed"] = agent.speed
            end
            push!(agents_data, agent_dict)
        end

        json(Dict(
            "Location" => "/simulations/$id",
            "agents" => agents_data,
            "stats" => Dict(
                "car_count" => model.car_count,
                "average_speed" => 0.0,
                "step_count" => 0
            )
        ))
    catch e
        println("Error en POST /simulations: ", e)
        json(Dict("error" => "Failed to create simulation", "message" => string(e)), status=500)
    end
end

route("/simulations/:id") do
    try
        id = params(:id)

        if !haskey(instances, id)
            return json(Dict("error" => "Simulation not found"), status=404)
        end

        model = instances[id]
        step!(model, 1)
        model_step!(model)

        agents_data = []
        for agent in allagents(model)
            agent_dict = Dict(
                "id" => agent.id,
                "pos" => [agent.pos[1], agent.pos[2]]
            )
            if agent isa TrafficLight
                agent_dict["type"] = "trafficlight"
                agent_dict["state"] = agent.state
                agent_dict["timer"] = agent.timer
                agent_dict["offset"] = agent.offset
            elseif agent isa Car
                agent_dict["type"] = "car"
                agent_dict["speed"] = agent.speed
            end
            push!(agents_data, agent_dict)
        end

        avg_speed = get_average_speed(model)

        json(Dict(
            "agents" => agents_data,
            "stats" => Dict(
                "car_count" => model.car_count,
                "average_speed" => avg_speed,
                "step_count" => model.step_count
            )
        ))
    catch e
        println("Error en GET /simulations/:id: ", e)
        json(Dict("error" => "Failed to process simulation", "message" => string(e)), status=500)
    end
end

route("/simulations") do
    json(Dict("simulations" => collect(keys(instances)), "count" => length(instances)))
end

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

up()