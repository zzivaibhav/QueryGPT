import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Upload from './pages/upload';
import Chat from './pages/Chat';
import Navigation from './components/header/Navigation';

import './App.css'

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen w-full">
        <Navigation />
        <Routes>
          <Route path="/" element={<Upload />} />
          <Route path="/chat" element={<Chat />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
