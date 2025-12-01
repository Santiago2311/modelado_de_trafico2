# Simulación de Tráfico con Semáforos 🚦🚗

Simulación urbana basada en agentes donde vehículos y semáforos interactúan dentro de una red de calles. El sistema permite múltiples autos por calle, control adaptativo de velocidad, detección de autos cercanos, semáforos inteligentes y estadísticas en tiempo real mediante API + Frontend.

---

## 📌 Características Principales

- Múltiples vehículos por calle.
- Aceleración y desaceleración realista.
- Detección de autos delanteros para evitar colisiones.
- Interacción con semáforos (rojo/amarillo/verde).
- Estadísticas globales del modelo (velocidad promedio, número de autos, pasos simulados).
- API REST en Julia.
- Frontend con React para visualización y control.

---

## 🚗 Cambios Recientes

### 1. Múltiples Vehículos por Calle

Antes solo existía 1 auto.  
Ahora se generan varios autos por cada calle:

function initialize_model(cars_per_street=5, extent=(100, 100))
    for car_street in streets
        for i in 1:cars_per_street
            initial_speed = rand(rng) * 0.8 + 0.2
            add_agent!(...)
        end
    end
end

2. Sistema de Aceleración / Desaceleración

@agent struct Car(ContinuousAgent{2,Float64})
    speed::Float64 = 0.5
    max_speed::Float64 = 1.0
    min_speed::Float64 = 0.1
end

El auto acelera si el camino está libre y se desacelera si hay un semáforo o vehículo cerca.
3. Detección de Autos Adelante

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

Permite mantener distancia segura y evitar colisiones.
4. Movimiento Mejorado

La lógica combina condiciones de semáforos + autos adelante:

if should_stop
    agent.speed = max(agent.min_speed, agent.speed - 0.2)
elseif should_slow
    agent.speed = max(agent.min_speed, agent.speed - 0.1)
else
    agent.speed = min(agent.max_speed, agent.speed + 0.1)
end

5. Estadísticas Globales del Modelo

Se calculan métricas globales:

properties = Dict(:total_speed => 0.0, :car_count => 0, :step_count => 0)

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
    return model.car_count > 0 ? model.total_speed / model.car_count : 0.0
end

6. API Mejorada
POST /simulations

Ahora acepta parámetros:

payload = jsonpayload()
cars_per_street = get(payload, "cars_per_street", 5)
model = initialize_model(cars_per_street, (100, 100))

GET /simulations/:id

Devuelve:

    lista de agentes

    velocidad promedio

    número de autos

    pasos simulados

step!(model, 1)
model_step!(model)

avg_speed = get_average_speed(model)

json(Dict(
    "agents" => agents_data,
    "stats" => Dict(
        "car_count" => model.car_count,
        "average_speed" => avg_speed,
        "step_count" => model.step_count
    )
))

7. Frontend con Configuración y Estadísticas
Selección de cantidad de autos

const [carsPerStreet, setCarsPerStreet] = useState(5);

Envío al backend

body: JSON.stringify({ cars_per_street: carsPerStreet })

Estadísticas en tiempo real

<span>Autos: {stats.car_count}</span>
<span>Velocidad promedio: {stats.average_speed.toFixed(2)}</span>
<span>Pasos: {stats.step_count}</span>