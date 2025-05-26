import os
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

# Example usage
if __name__ == "__main__":
    docs = [
        Document(
            page_content="Table: Customers\nColumns:\n  - customer_id (INT)\n  - name (VARCHAR)\n  - email (VARCHAR)",
            metadata={"table": "Customers"}
        ),
        Document(
            page_content="Table: Orders\nColumns:\n  - order_id (INT)\n  - customer_id (INT)\n  - order_date (DATE)\n  - total_amount (DECIMAL)",
            metadata={"table": "Orders"}
        ),
    ]
    # Make sure to set ENV before running
    print(index_documents_to_qdrant(docs, "sql_schema_chunks"))
