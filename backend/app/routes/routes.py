from flask import Blueprint, request, jsonify
from app.services.services import get_hello_world, process_upload, QueryService

# this is the blueprint for storing the views.
main_bp = Blueprint('main', __name__)
query_service = QueryService()

@main_bp.route('/')
def hello_world():
    return get_hello_world()


@main_bp.route('/upload', methods=['POST'])
def upload():
    return process_upload()

@main_bp.route('/health')
def health_check():
    return {"status": "healthy"}, 200

@main_bp.route('/query', methods=['POST'])
def process_query():
    try:
        data = request.get_json()
        if not data or 'query' not in data:
            return jsonify({"error": "Missing query in request"}), 400
            
        query_text = data['query']
        result = query_service.process_query(query_text)
        return jsonify({"result": result}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

