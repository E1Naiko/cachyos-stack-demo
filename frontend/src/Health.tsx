import { useEffect, useState } from "react";

export default function Health() {
const [status, setStatus] = useState("Comprobando...");

useEffect(() => {
    fetch("http://localhost:8000/health")
        .then((response) => response.json())
        .then((data) => {
            setStatus(data.status);
        })
        .catch(() => {
            setStatus("Servidor desconectado");
        });
}, []);

return (
    <div>
        <h1>Estado del servidor</h1>
        <p>{status}</p>
        <img src="https://i.pinimg.com/564x/d4/6e/24/d46e243f0723760c167f2f8dc0ac2447.jpg" alt="Imagen de salud" />
    </div>
);
}
