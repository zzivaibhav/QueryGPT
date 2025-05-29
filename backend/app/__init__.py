from flask import Flask
from flask_cors import CORS
from app.routes.routes import main_bp

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    app.register_blueprint(main_bp, url_prefix='/api')
    
    return app

from app import create_app
app = create_app()

if __name__ == "__main__":
    app.run(debug=True, port = 8080)
