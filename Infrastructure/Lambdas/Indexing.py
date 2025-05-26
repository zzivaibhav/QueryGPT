import os
import json
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Qdrant
from langchain_core.documents import Document
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams

def index_documents_to_qdrant(documents, collection_name):
    # 1. Read ENV for Qdrant connection
    QDRANT_HOST = os.environ.get("QDRANT_HOST", "localhost")
    QDRANT_PORT = int(os.environ.get("QDRANT_PORT", 6333))

    # 2. Qdrant setup
    client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    
    if client.collection_exists(collection_name):
        client.delete_collection(collection_name)

    client.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=384, distance=Distance.COSINE),
    )

    # 3. Embedding model
    embedding_model = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

    # 4. Store vectors in Qdrant
    vectorstore = Qdrant.from_documents(
        documents=documents,
        embedding=embedding_model,
        collection_name=collection_name,
        url=f"http://{QDRANT_HOST}:{QDRANT_PORT}",
    )

    return {"status": "success", "collection": collection_name}

def lambda_handler(event, context):
    try:
        # Parse the incoming request body
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        # Get collection name and documents from the request
        collection_name = body.get('collection_name', 'sql_schema_chunks')
        schema_documents = body.get('documents', [])
        
        if not schema_documents:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No documents provided in the request'})
            }
        
        # Convert the incoming documents to Document objects
        documents = [
            Document(
                page_content=doc.get('content', ''),
                metadata=doc.get('metadata', {})
            ) for doc in schema_documents
        ]
        
        # Index the documents
        result = index_documents_to_qdrant(documents, collection_name)
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
