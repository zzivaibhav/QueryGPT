# SQL Schema Query Assistant

A sophisticated RAG-based application that helps users understand and query SQL schemas using natural language. This project leverages LLM capabilities to convert natural language questions into SQL queries based on provided schema documentation.

## 🌟 Key Features

- **PDF Schema Processing**: Upload and process SQL schema documentation in PDF format
- **Natural Language to SQL**: Convert natural language questions into accurate SQL queries
- **Interactive Query Interface**: User-friendly interface for asking questions about the schema
- **Self-hosted LLM**: Utilizing Ollama for local LLM hosting
- **Vector Search**: Powered by Qdrant vector database for efficient similarity search

## 🏗️ Architecture

```
SQL Schema Query Assistant
├── Frontend (React + TypeScript)
├── Backend (Python + FastAPI)
└── Infrastructure (Docker + Docker Compose)
```

## 🔧 Technology Stack

- **LLM**: Self-hosted Ollama
- **Vector Database**: Qdrant
- **Frontend**: React.js with TypeScript
- **Backend**: Python with FastAPI
- **Document Processing**: LangChain + PyPDF2
- **Containerization**: Docker & Docker Compose

## 💾 Vector Database: Qdrant

We chose Qdrant as our vector database for several key benefits:

- High Performance: Memory-efficient with disk persistence
- Simple Architecture: Easy to deploy and maintain
- Flexible Search: Rich filtering capabilities with payload
- Production Ready: Built for production workloads
- Open Source: Active community and regular updates
- Native Rust Implementation: Optimized for performance

## 📚 Getting Started

1. Clone the repository
2. Install dependencies (see individual README files in frontend and backend directories)
3. Set up Ollama with required models
4. Configure Qdrant database
5. Start the application using Docker Compose

## 🔗 Component Documentation

- [Frontend Documentation](./frontend/README.md)
- [Backend Documentation](./backend/README.md)
- [Infrastructure Setup](./infra/README.md)

## 📋 Prerequisites

- Docker and Docker Compose
- Node.js 16+
- Python 3.8+
- Ollama setup with required models
- Qdrant database instance
