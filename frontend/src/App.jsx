import { useState, useRef } from 'react';

export default function App() {
  let [location, setLocation] = useState("");
  let [cars, setCars] = useState([]);
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
        setCars(data["cars"]);
      });
  }

  const handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
        .then(res => res.json())
        .then(data => {
          setCars(data["cars"]);
        });
    }, 1000 / simSpeed);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

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
        {/* <SliderField label="Car Speed" min={1} max={10} type='number' value={simSpeed} onChange={handleSimSpeedSliderChange}/> */}
      </div>
      <svg width="1500" height="500" xmlns="http://www.w3.org/2000/svg" style={{ backgroundColor: "white" }}>

        <rect x={0} y={200} width={1500} height={80} style={{ fill: "darkgray" }}></rect>
        {
          cars.map(car =>
            <image id={car.id} x={car.pos[0] * 32} y={200} width={32} href="./racing-car.png" />
          )
        }
      </svg>
    </div>
  );
}
