# SQL Schema Query Assistant - Infrastructure

Infrastructure setup and configuration for the SQL Schema Query Assistant.

## 🎯 Components

- **Ollama**: Self-hosted LLM service
- **Milvus**: Vector database
- **Frontend**: React application container
- **Backend**: FastAPI service container
- **Nginx**: Reverse proxy

## 🔧 Configuration

### Docker Compose Services

```yaml
services:
  - frontend
  - backend
  - ollama
  - milvus
  - nginx
```

## 🚀 Deployment

```bash
docker-compose up -d
```

## 💾 Data Persistence

- Milvus data volume
- PDF storage volume
- Model weights volume

## 🔐 Security Considerations

- Network isolation
- Environment variables
- Access control
- SSL/TLS configuration

## 🔍 Monitoring

- Container health checks
- Resource monitoring
- Log aggregation
