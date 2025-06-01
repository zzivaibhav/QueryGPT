# ⚙️ QueryGPT Backend Service

<div align="center">

![Python](https://img.shields.io/badge/python-3.8%2B-blue)
![FastAPI](https://img.shields.io/badge/framework-FastAPI-009688)
![LangChain](https://img.shields.io/badge/RAG-LangChain-yellowgreen)
![Ollama](https://img.shields.io/badge/LLM-Ollama-orange)
![Qdrant](https://img.shields.io/badge/Vector%20DB-Qdrant-blueviolet)

</div>

A robust FastAPI-powered backend service that forms the intelligence layer of QueryGPT. This component handles the sophisticated RAG (Retrieval Augmented Generation) pipeline, document processing, vector storage, and natural language understanding.

<div align="center">
<img src="https://fastapi.tiangolo.com/img/logo-margin/logo-teal.png" alt="FastAPI Logo" height="100">
</div>

## 🎯 Core Capabilities

- **📄 PDF Processing Engine**: Efficiently extracts and processes SQL schema information from PDF documentation
- **🔄 RAG Pipeline**: Sophisticated implementation of Retrieval Augmented Generation for enhanced responses
- **💾 Vector Storage Management**: Seamless integration with Qdrant for powerful document embedding storage
- **🔄 Natural Language Processing**: Converts conversational questions into precise SQL queries
- **🌐 RESTful API Interface**: Comprehensive endpoints for communication with the frontend

## 🔧 Technical Stack

<div align="center">

<table>
  <tr>
    <td align="center"><img src="https://fastapi.tiangolo.com/img/favicon.png" width="40" height="40"/></td>
    <td><b>FastAPI</b></td>
    <td>High-performance web framework for building APIs</td>
  </tr>
  <tr>
    <td align="center"><img src="https://python.langchain.com/img/favicon.ico" width="40" height="40"/></td>
    <td><b>LangChain</b></td>
    <td>Framework for developing LLM-powered applications</td>
  </tr>
  <tr>
    <td align="center">📄</td>
    <td><b>PyPDF2</b></td>
    <td>Pure-python PDF document processing</td>
  </tr>
  <tr>
    <td align="center">🧠</td>
    <td><b>Ollama Client</b></td>
    <td>Integration with self-hosted LLM service</td>
  </tr>
  <tr>
    <td align="center">🔍</td>
    <td><b>Qdrant Client</b></td>
    <td>Vector database access and management</td>
  </tr>
</table>

</div>

## 🚀 Getting Started

### Local Development Setup

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# OR
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn app.routes.routes:app --reload --port 8000
```

### Environment Configuration

```bash
# Configure Ollama host
export OLLAMA_HOST=http://localhost:11434
# OR for specific remote instance
export OLLAMA_HOST=http://your.ollama.host:11434
```

## 📁 Project Structure

<div align="center">

```
backend/
├── 📄 run.py               # Entry point
├── 📄 requirements.txt     # Dependencies
├── 📄 Dockerfile           # Container definition
├── 📁 app/                 # Application package
│   ├── 📄 __init__.py      # Package initializer
│   ├── 📁 routes/          # API route definitions
│   │   └── 📄 routes.py    # Endpoint implementations
│   └── 📁 services/        # Business logic
│       └── 📄 services.py  # Core service implementations
└── 📁 tests/               # Test suite
    └── 📄 ...              # Test modules
```

</div>

## 🔄 API Endpoints

<table>
  <tr>
    <th>Endpoint</th>
    <th>Method</th>
    <th>Description</th>
    <th>Request Body</th>
    <th>Response</th>
  </tr>
  <tr>
    <td><code>/upload</code></td>
    <td>POST</td>
    <td>Upload PDF schema documents</td>
    <td>Multipart form with PDF file</td>
    <td>Upload status and schema ID</td>
  </tr>
  <tr>
    <td><code>/query</code></td>
    <td>POST</td>
    <td>Process natural language queries</td>
    <td>JSON with query text and schema ID</td>
    <td>SQL query and explanation</td>
  </tr>
  <tr>
    <td><code>/schemas</code></td>
    <td>GET</td>
    <td>List available schemas</td>
    <td>-</td>
    <td>Array of available schemas</td>
  </tr>
  <tr>
    <td><code>/history</code></td>
    <td>GET</td>
    <td>Retrieve query history</td>
    <td>-</td>
    <td>Array of past queries and results</td>
  </tr>
</table>

## 🐳 Docker Deployment

```bash
# Build the container
docker build -t querygpt-backend .

# Run the container
docker run -d -p 8000:8000 \
  -e OLLAMA_HOST=http://ollama:11434 \
  -e QDRANT_HOST=http://qdrant:6333 \
  --name querygpt-backend \
  querygpt-backend
```