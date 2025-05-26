import os
import json
import base64
import io
from pypdf import PdfReader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Qdrant
from langchain_core.documents import Document
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams

def process_pdf_content(pdf_file):
    # Modified to accept both file path and bytes
    if isinstance(pdf_file, (str, bytes, io.BytesIO)):
        pdf_reader = PdfReader(pdf_file)
    else:
        raise ValueError("Invalid PDF input format")
    
    # Extract text from PDF
    text_content = ""
    for page in pdf_reader.pages:
        text_content += page.extract_text()
    
    # Split text into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len
    )
    
    chunks = text_splitter.split_text(text_content)
    return [Document(page_content=chunk) for chunk in chunks]

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
        # Check if the request contains multipart form data
        if event.get('headers', {}).get('Content-Type', '').startswith('multipart/form-data'):
            # Get the body content
            body = event.get('body', '')
            
            # Parse multipart form data
            import cgi
            from io import BytesIO
            
            # Create environment for cgi
            environ = {
                'REQUEST_METHOD': 'POST',
                'CONTENT_TYPE': event['headers']['Content-Type'],
                'CONTENT_LENGTH': len(body)
            }
            
            # Parse the multipart form data
            form = cgi.FieldStorage(
                fp=BytesIO(body.encode('utf-8')),
                environ=environ,
                keep_blank_values=True
            )
            
            # Get collection name from form data or use default
            collection_name = form.getvalue('collection_name', 'sql_schema_chunks')
            
            # Get the PDF file
            if 'pdf_file' not in form:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'No PDF file provided'})
                }
            
            pdf_file = BytesIO(form['pdf_file'].file.read())
            
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Content-Type must be multipart/form-data'})
            }
        
        # Process PDF and create documents
        documents = process_pdf_content(pdf_file)
        
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
