import os

from dotenv import load_dotenv
from flask import Flask
from flask_cors import CORS
from sqlalchemy import text

from app.extensions.db import db
from app.extensions.jwt import jwt
from app.routes import auth_bp, chat_bp


def _normalize_database_uri(uri: str) -> str:
    # Railway may provide postgres:// and SQLAlchemy expects postgresql://.
    if uri.startswith("postgres://"):
        uri = uri.replace("postgres://", "postgresql://", 1)

    # Force psycopg v3 driver to match current dependency.
    if uri.startswith("postgresql://") and "+" not in uri.split("://", 1)[0]:
        uri = uri.replace("postgresql://", "postgresql+psycopg://", 1)

    return uri


def create_app():
    load_dotenv()

    app = Flask(__name__)
    CORS(app)

    app.config["SQLALCHEMY_DATABASE_URI"] = _normalize_database_uri(
        os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/ai_pemalas_db")
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "dev-jwt-secret-change-me")

    db.init_app(app)
    jwt.init_app(app)
    app.register_blueprint(auth_bp)
    app.register_blueprint(chat_bp)

    with app.app_context():
        # Ensure base tables exist for MVP flow.
        from app.models import ChatMessage, User  # noqa: F401

        db.create_all()

    @app.get("/health")
    def health_check():
        try:
            db.session.execute(text("SELECT 1"))
            return {"status": "ok", "database": "connected"}, 200
        except Exception as exc:
            return {"status": "ok", "database": "disconnected", "detail": str(exc)}, 200

    return app
