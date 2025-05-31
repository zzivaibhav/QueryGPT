from flask import Flask, request
from flask_cors import CORS
from app.routes.routes import main_bp

def create_app():
    app = Flask(__name__)
    
    # Configure CORS with more explicit settings
    CORS(app, resources={r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "Accept"]
    }})
    
    # Add OPTIONS request handler for all routes
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,Accept')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        return response
    
    app.register_blueprint(main_bp, url_prefix='/api')
    
    return app

from app import create_app
app = create_app()

if __name__ == "__main__":
    app.run(debug=True, port = 8080)
