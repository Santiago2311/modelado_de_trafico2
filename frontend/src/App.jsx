import { useState, useRef } from 'react';

export default function App() {
  let [location, setLocation] = useState("");
  let [agents, setAgents] = useState([]);
  let [simSpeed] = useState(10);
  const running = useRef(null);

  let setup = () => {
    console.log("Hola");
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify()
    }).then(resp => resp.json())
      .then(data => {
        console.log(data);
        setLocation(data["Location"]);
        setAgents(data["agents"]);
      });
  }

  const handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
        .then(res => res.json())
        .then(data => {
          setAgents(data["agents"]);
        });
    }, 1000 / simSpeed);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

  const scale = 8;
  const width = 100 * scale;
  const height = 100 * scale;
  const streetWidth = 8 * scale;
  const streets = [20, 40, 60, 80];

  return (
    <div>
      <div>
        <button onClick={setup}>
          Setup
        </button>
        <button onClick={handleStart}>
          Start
        </button>
        <button onClick={handleStop}>
          Stop
        </button>
      </div>
      <svg width={width} height={height} xmlns="http://www.w3.org/2000/svg" style={{ backgroundColor: "white" }}>
        
        {/* Horizontal Streets */}
        {streets.map(pos => (
          <g key={`h-street-${pos}`}>
            <rect 
              x={0} 
              y={(pos - 4) * scale} 
              width={width} 
              height={streetWidth} 
              fill="#555"
            />
            {/* Yellow line */}
            <line 
              x1={0} 
              y1={pos * scale} 
              x2={width} 
              y2={pos * scale} 
              stroke="#ffff00" 
              strokeWidth="2" 
              strokeDasharray="10,10"
            />
          </g>
        ))}
        
        {/* Vertical Streets */}
        {streets.map(pos => (
          <g key={`v-street-${pos}`}>
            <rect 
              x={(pos - 4) * scale} 
              y={0} 
              width={streetWidth} 
              height={height} 
              fill="#555"
            />
            <line 
              x1={pos * scale} 
              y1={0} 
              x2={pos * scale} 
              y2={height} 
              stroke="#ffff00" 
              strokeWidth="2" 
              strokeDasharray="10,10"
            />
          </g>
        ))}
        
        {/* Intersections */}
        {streets.map(x => 
          streets.map(y => (
            <rect 
              key={`intersection-${x}-${y}`}
              x={(x - 4) * scale} 
              y={(y - 4) * scale} 
              width={streetWidth} 
              height={streetWidth} 
              fill="#444"
            />
          ))
        )}
        
        {/* Trafficlight */}
        {agents.filter(a => a.type === "trafficlight").map(light => {
          const x = light.pos[0] * scale;
          const y = light.pos[1] * scale;
          
          return (
            <g key={light.id}>
              <rect x={x - 4} y={y - 15} width={8} height={30} fill="#222" rx="2" />
              
              <circle 
                cx={x} 
                cy={y - 10} 
                r={3} 
                fill={light.state === "red" ? "#ff0000" : "#440000"} 
              />
              
              <circle 
                cx={x} 
                cy={y} 
                r={3} 
                fill={light.state === "yellow" ? "#ffff00" : "#444400"} 
              />
              
              <circle 
                cx={x} 
                cy={y + 10} 
                r={3} 
                fill={light.state === "green" ? "#00ff00" : "#004400"} 
              />
            </g>
          );
        })}
        
        {/* Cars */}
        {agents.filter(a => a.type === "car").map(car => {
          const x = car.pos[0] * scale;
          const y = car.pos[1] * scale;
          return (
            <g key={car.id}>
              <rect 
                x={x - 8}
                y={y - 4}
                width={16}
                height={8}
                fill="#3498db"
                stroke="#2c3e50"
                strokeWidth="1"
                rx="2"
              />
              {/* Ventanas */}
              <rect x={x - 5} y={y - 2} width={4} height={4} fill="#87ceeb" />
              <rect x={x + 1} y={y - 2} width={4} height={4} fill="#87ceeb" />
            </g>
          );
        })}
      </svg>
    </div>
  );
}