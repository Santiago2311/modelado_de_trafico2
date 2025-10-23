include("simple.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

route("/simulations", method=POST) do
    payload = jsonpayload()
    model = initialize_model()
    id = string(uuid1())
    instances[id] = model

    agents_data = []
    for agent in allagents(model)
        push!(agents_data, Dict(
            "id" => agent.id,
            "type" => "trafficlight",
            "pos" => agent.pos,
            "state" => agent.state
        ))
    end

    json(Dict("Location" => "/simulations/$id", "agents" => agents_data))
end

route("/simulations/:id") do
    id = params(:id)
    println(id)
    model = instances[id]
    run!(model, 1)

    agents_data = []
    for agent in allagents(model)
        push!(agents_data, Dict(
            "id" => agent.id,
            "type" => "trafficlight",
            "pos" => agent.pos,
            "state" => agent.state
        ))
    end

    json(Dict("agents" => agents_data))
end

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

up()