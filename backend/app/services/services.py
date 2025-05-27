import os
import json
import logging
from flask import jsonify, request
from pypdf import PdfReader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Qdrant
from langchain_core.documents import Document
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams
import io
import ollama
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_hello_world():
    return jsonify({"message": "Hello, World!"})

def health_check():
    return jsonify({"status": "healthy"}), 200

def process_pdf_content(pdf_file):
    try:
        # Try to create PdfReader with the input directly
        pdf_reader = PdfReader(pdf_file)
        
        text_content = ""
        for page in pdf_reader.pages:
            text_content += page.extract_text()
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len
        )
        
        chunks = text_splitter.split_text(text_content)
        return [Document(page_content=chunk) for chunk in chunks]
    
    except Exception as e:
        logger.error(f"Error processing PDF: {str(e)}")
        raise ValueError(f"Could not process PDF file: {str(e)}")

def index_documents_to_qdrant(documents, collection_name):
    QDRANT_HOST = os.environ.get("QDRANT_HOST", "127.0.0.1")
    QDRANT_PORT = int(os.environ.get("QDRANT_PORT", "6333"))

    client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    
    # Check if collection exists and recreate if needed
    try:
        if client.get_collection(collection_name) is not None:
            client.delete_collection(collection_name)
    except:
        pass  # Collection doesn't exist
    
    # Create collection with simplified configuration
    client.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=384, distance=Distance.COSINE),
        hnsw_config={
            "m": 16,
            "ef_construct": 100,
        }
    )

    embedding_model = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

    # Create vectorstore with explicit client instance
    vectorstore = Qdrant(
        client=client,
        collection_name=collection_name,
        embeddings=embedding_model,
    )
    
    # Add documents to the collection
    vectorstore.add_documents(documents)

    return {"status": "success", "collection": collection_name}

def process_upload():
    try:
        if 'pdf_file' not in request.files:
            return jsonify({'error': 'No PDF file provided'}), 400
            
        pdf_file = request.files['pdf_file']
        collection_name = request.form.get('collection_name', 'sql_schema_chunks')
        
        # Process PDF and create documents
        documents = process_pdf_content(pdf_file)
        
        # Index the documents
        result = index_documents_to_qdrant(documents, collection_name)
        
        return jsonify(result), 200
        
    except Exception as e:
        logger.error(f"Error processing upload: {str(e)}")
        return jsonify({'error': str(e)}), 500

class QueryService:
    def __init__(self, collection_name="sql_schema_chunks"):
        self.collection_name = collection_name
        self.setup_qdrant()
        self.setup_embeddings()
        
    def setup_qdrant(self):
        try:
            QDRANT_HOST = os.environ.get("QDRANT_HOST", "localhost")
            QDRANT_PORT = int(os.environ.get("QDRANT_PORT", 6333))
            
            # Simple connection setup without additional checks
            self.client = QdrantClient(
                host=QDRANT_HOST, 
                port=QDRANT_PORT
            )
            logger.info(f"Connected to Qdrant at {QDRANT_HOST}:{QDRANT_PORT}")
            
        except Exception as e:
            logger.error(f"Error connecting to Qdrant: {str(e)}")
            raise

    def setup_embeddings(self):
        self.embedding_model = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
        self.vectorstore = Qdrant(
            client=self.client,
            collection_name=self.collection_name,
            embeddings=self.embedding_model,
        )
        self.retriever = self.vectorstore.as_retriever(search_kwargs={"k": 2})
        
    def process_query(self, user_query):
        results = self.retriever.invoke(user_query)
        schema_context = "\n\n".join(doc.page_content.strip() for doc in results)
        
        final_prompt = f"""
        Given the following SQL schema:

        {schema_context}

        Write a SQL query for the question:
        "{user_query}"

        Requirements:
        1. Use only the exact column names shown in the schema
        2. Return only the SQL query without any explanations
        3. The query must be executable in MySQL
        4. Do not include thinking process or comments

        Example format:
        SELECT column FROM table WHERE condition;
        """
        
        response = ollama.chat(
            model="codellama:7b",
            messages=[
                {
                    "role": "system",
                    "content": """You are a SQL expert. Follow these rules strictly:
                    1. Generate only the SQL query
                    2. No explanations or comments
                    3. No thinking process
                    4. Use exact column names from schema
                    5. Must be valid MySQL syntax"""
                },
                {
                    "role": "user",
                    "content": final_prompt
                }
            ],
        )
        
        return response['message']['content'].strip()