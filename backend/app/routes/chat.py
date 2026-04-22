from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.extensions.db import db
from app.models.chat import ChatMessage
from app.services.ai_logic import generate_lazy_ai_response

chat_bp = Blueprint("chat", __name__, url_prefix="/api/chat")


@chat_bp.get("/history")
@jwt_required()
def get_chat_history():
    user_id = int(get_jwt_identity())
    query = str(request.args.get("query", "")).strip().lower()

    history_query = ChatMessage.query.filter_by(user_id=user_id)
    if query:
        history_query = history_query.filter(
            db.or_(
                db.func.lower(ChatMessage.prompt).contains(query),
                db.func.lower(ChatMessage.response).contains(query),
            )
        )

    history = (
        history_query
        .order_by(ChatMessage.created_at.asc())
        .limit(100)
        .all()
    )

    return jsonify({"history": [item.to_dict() for item in history]}), 200


@chat_bp.post("")
@jwt_required()
def create_chat():
    payload = request.get_json(silent=True) or {}
    prompt = str(payload.get("prompt", "")).strip()

    if not prompt:
        return jsonify({"message": "prompt wajib diisi"}), 400

    user_id = int(get_jwt_identity())
    ai_response = generate_lazy_ai_response(prompt)

    chat_message = ChatMessage(
        user_id=user_id,
        prompt=prompt,
        response=ai_response,
    )
    db.session.add(chat_message)
    db.session.commit()

    return jsonify({"message": "chat tersimpan", "chat": chat_message.to_dict()}), 201
