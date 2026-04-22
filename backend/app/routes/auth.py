from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required
from werkzeug.security import check_password_hash, generate_password_hash

from app.extensions.db import db
from app.models.user import User

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.post("/register")
def register():
    payload = request.get_json(silent=True) or {}

    username = str(payload.get("username", "")).strip()
    email = str(payload.get("email", "")).strip().lower()
    password = str(payload.get("password", "")).strip()

    if not username or not email or not password:
        return jsonify({"message": "username, email, dan password wajib diisi"}), 400

    if len(password) < 6:
        return jsonify({"message": "password minimal 6 karakter"}), 400

    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"message": "email sudah dipakai"}), 409

    user = User(
        username=username,
        email=email,
        password_hash=generate_password_hash(password),
    )
    db.session.add(user)
    db.session.commit()

    return jsonify({"message": "register berhasil", "user": user.to_dict()}), 201


@auth_bp.post("/login")
def login():
    payload = request.get_json(silent=True) or {}

    email = str(payload.get("email", "")).strip().lower()
    password = str(payload.get("password", "")).strip()

    if not email or not password:
        return jsonify({"message": "email dan password wajib diisi"}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({"message": "email atau password salah"}), 401

    access_token = create_access_token(identity=str(user.id))

    return (
        jsonify(
            {
                "message": "login berhasil",
                "access_token": access_token,
                "user": user.to_dict(),
            }
        ),
        200,
    )


@auth_bp.get("/me")
@jwt_required()
def me():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)

    if not user:
        return jsonify({"message": "user tidak ditemukan"}), 404

    return jsonify({"message": "token valid", "user": user.to_dict()}), 200
