# SQL Schema Query Assistant - Backend

FastAPI-based backend service for processing queries and managing the RAG pipeline.

## 🎯 Features

- **PDF Processing**: Extract and process SQL schema information from PDFs
- **RAG Pipeline**: Implementation of Retrieval Augmented Generation
- **Vector Storage**: Management of document embeddings in Milvus
- **Query Processing**: Natural language to SQL query conversion
- **API Endpoints**: RESTful API for frontend communication

## 🔧 Technical Stack

- FastAPI
- LangChain for RAG implementation
- PyPDF2 for PDF processing
- Ollama client for LLM integration
- Milvus client for vector storage

## 🚀 Getting Started

```bash
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
uvicorn main:app --reload
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/
│   ├── core/
│   ├── services/
│   └── utils/
├── tests/
└── requirements.txt
```

## 🔄 API Endpoints

- `POST /upload`: Upload PDF schema documents
- `POST /query`: Process natural language queries
- `GET /schemas`: List available schemas
- `GET /history`: Retrieve query history
