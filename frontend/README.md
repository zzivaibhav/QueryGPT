# 🖥️ QueryGPT Frontend Application

<div align="center">

![React](https://img.shields.io/badge/framework-React-61DAFB)
![Vite](https://img.shields.io/badge/bundler-Vite-646CFF)
![TailwindCSS](https://img.shields.io/badge/styling-TailwindCSS-38B2AC)
![ESLint](https://img.shields.io/badge/linting-ESLint-4B32C3)

</div>

A modern, responsive React-based frontend application that provides an intuitive interface for interacting with the QueryGPT system. This component focuses on delivering an exceptional user experience with real-time feedback and elegant visualizations.

<div align="center">
<img src="https://reactjs.org/logo-og.png" alt="React Logo" height="150">
</div>

## 📱 Application Screenshots

<div align="center">
  <div style="display: flex; justify-content: space-around; margin-bottom: 20px;">
    <div style="width: 48%;">
      <img src="./Upload.png" alt="Schema Upload Interface" style="width: 100%; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
      <p><em>Schema Upload Interface: Upload and manage your database schema documents</em></p>
    </div>
    <div style="width: 48%;">
      <img src="./Chat.png" alt="Query Assistant Interface" style="width: 100%; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
      <p><em>Query Assistant: Natural language to SQL conversion interface</em></p>
    </div>
  </div>
</div>

## 🎯 User Experience Features

- **📤 Intuitive Document Upload**: Drag-and-drop interface with visual feedback for schema document upload
- **💬 Conversational Query Interface**: Clean, chat-like interface for natural language interaction
- **📊 SQL Visualization**: Beautifully formatted display of generated SQL queries with syntax highlighting
- **📈 Schema Representation**: Visual diagrams of database structure for better understanding
- **🕒 Query History & Management**: Convenient access to past queries with the ability to refine and reuse

## 🔧 Technical Stack

<div align="center">

<table>
  <tr>
    <td align="center"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/React-icon.svg/512px-React-icon.svg.png" width="40" height="40"/></td>
    <td><b>React.js</b></td>
    <td>UI library with TypeScript for type safety</td>
  </tr>
  <tr>
    <td align="center"><img src="https://vitejs.dev/logo.svg" width="40" height="40"/></td>
    <td><b>Vite</b></td>
    <td>Next generation frontend tooling</td>
  </tr>
  <tr>
    <td align="center"><img src="https://tailwindcss.com/favicons/apple-touch-icon.png?v=3" width="40" height="40"/></td>
    <td><b>TailwindCSS</b></td>
    <td>Utility-first CSS framework</td>
  </tr>
  <tr>
    <td align="center">📊</td>
    <td><b>CodeMirror</b></td>
    <td>SQL syntax highlighting</td>
  </tr>
  <tr>
    <td align="center">📄</td>
    <td><b>PDF.js</b></td>
    <td>PDF preview and processing</td>
  </tr>
  <tr>
    <td align="center">🔄</td>
    <td><b>React Query</b></td>
    <td>Data fetching and state management</td>
  </tr>
</table>

</div>

## 🚀 Getting Started

### Local Development Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Visit http://localhost:5173 in your browser
```

### Build for Production

```bash
# Generate production build
npm run build

# Preview production build
npm run preview
```

## 📁 Project Structure

<div align="center">

```
frontend/
├── 📄 package.json          # Package configuration
├── 📄 index.html            # Entry HTML file
├── 📄 vite.config.js        # Vite configuration
├── 📄 tailwind.config.js    # TailwindCSS configuration
├── 📄 eslint.config.js      # ESLint configuration
├── 📁 public/               # Static assets
│   └── 📄 vite.svg          # Vite logo
└── 📁 src/                  # Source code
    ├── 📄 main.jsx          # Application entry point
    ├── 📄 App.jsx           # Root component
    ├── 📄 index.css         # Global styles
    ├── 📁 assets/           # Images and resources
    ├── 📁 components/       # Reusable UI components
    │   ├── 📁 header/       # Header components
    │   └── 📁 upload/       # Upload components
    ├── 📁 context/          # React context providers
    └── 📁 pages/            # Page components
```

</div>

## 💻 Available Scripts

<table>
  <tr>
    <th>Command</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>npm run dev</code></td>
    <td>Start development server with hot module replacement</td>
  </tr>
  <tr>
    <td><code>npm run build</code></td>
    <td>Build for production with optimizations</td>
  </tr>
  <tr>
    <td><code>npm run preview</code></td>
    <td>Preview production build locally</td>
  </tr>
  <tr>
    <td><code>npm run lint</code></td>
    <td>Run ESLint to check code quality</td>
  </tr>
  <tr>
    <td><code>npm test</code></td>
    <td>Execute test suite</td>
  </tr>
</table>

## 🎨 Theme and Styling

The application features a modern, responsive design with:

- Light/Dark mode toggle
- Responsive layouts for all device sizes
- Smooth animations and transitions
- Accessible color schemes
- Consistent typography and spacing

<div align="center">
<img src="https://tailwindcss.com/_next/static/media/social-card-large.a6e71726.jpg" alt="TailwindCSS" height="150">
</div>
