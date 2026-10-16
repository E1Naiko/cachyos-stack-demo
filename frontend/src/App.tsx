
import { BrowserRouter, Routes, Route } from "react-router-dom";

import Login from "./components/login/login";
import Dashboard from "./pages/Dashboard";
import valenprueba from "./pages/valenprueba";
import "./App.css";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/valenprueba" element={<valenprueba />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
