from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.extensions.db import db
from app.models.chat import ChatMessage
from app.models.chat_thread import ChatThread
from app.models.chat_turn import ChatTurn
from app.services.ai_logic import generate_lazy_ai_response

chat_bp = Blueprint("chat", __name__, url_prefix="/api/chat")


def _make_thread_title(prompt: str) -> str:
    clean = (prompt or "").strip()
    if not clean:
        return "Chat Baru"
    return clean[:60]


@chat_bp.get("/threads")
@jwt_required()
def get_threads():
    user_id = int(get_jwt_identity())
    query = str(request.args.get("query", "")).strip().lower()

    thread_query = ChatThread.query.filter_by(user_id=user_id)
    if query:
        thread_query = thread_query.filter(db.func.lower(ChatThread.title).contains(query))

    threads = (
        thread_query
        .order_by(ChatThread.updated_at.desc())
        .limit(200)
        .all()
    )

    return jsonify({"threads": [item.to_dict() for item in threads]}), 200


@chat_bp.post("/threads")
@jwt_required()
def create_thread():
    user_id = int(get_jwt_identity())
    payload = request.get_json(silent=True) or {}
    title = str(payload.get("title", "")).strip() or "Chat Baru"

    thread = ChatThread(user_id=user_id, title=title)
    db.session.add(thread)
    db.session.commit()

    return jsonify({"message": "thread dibuat", "thread": thread.to_dict()}), 201


@chat_bp.get("/threads/<int:thread_id>/messages")
@jwt_required()
def get_thread_messages(thread_id: int):
    user_id = int(get_jwt_identity())
    thread = ChatThread.query.filter_by(id=thread_id, user_id=user_id).first()
    if not thread:
        return jsonify({"message": "thread tidak ditemukan"}), 404

    messages = (
        ChatTurn.query
        .filter_by(user_id=user_id, thread_id=thread_id)
        .order_by(ChatTurn.created_at.asc())
        .all()
    )

    return jsonify({"thread": thread.to_dict(), "messages": [item.to_dict() for item in messages]}), 200


@chat_bp.delete("/threads/<int:thread_id>")
@jwt_required()
def delete_thread(thread_id: int):
    user_id = int(get_jwt_identity())
    thread = ChatThread.query.filter_by(id=thread_id, user_id=user_id).first()
    if not thread:
        return jsonify({"message": "thread tidak ditemukan"}), 404

    ChatTurn.query.filter_by(user_id=user_id, thread_id=thread_id).delete()
    db.session.delete(thread)
    db.session.commit()

    return jsonify({"message": "thread dihapus"}), 200


@chat_bp.post("")
@jwt_required()
def create_chat():
    payload = request.get_json(silent=True) or {}
    prompt = str(payload.get("prompt", "")).strip()
    thread_id = payload.get("thread_id")

    if not prompt:
        return jsonify({"message": "prompt wajib diisi"}), 400

    user_id = int(get_jwt_identity())

    thread = None
    if thread_id is not None:
        try:
            thread_id = int(thread_id)
        except (TypeError, ValueError):
            return jsonify({"message": "thread_id tidak valid"}), 400
        thread = ChatThread.query.filter_by(id=thread_id, user_id=user_id).first()
        if not thread:
            return jsonify({"message": "thread tidak ditemukan"}), 404
    else:
        thread = ChatThread(user_id=user_id, title=_make_thread_title(prompt))
        db.session.add(thread)
        db.session.flush()

    ai_response = generate_lazy_ai_response(prompt)

    chat_turn = ChatTurn(
        user_id=user_id,
        thread_id=thread.id,
        prompt=prompt,
        response=ai_response,
    )

    # Keep legacy table populated for backward compatibility.
    chat_message = ChatMessage(
        user_id=user_id,
        prompt=prompt,
        response=ai_response,
    )

    if thread.title == "Chat Baru":
        thread.title = _make_thread_title(prompt)
    thread.updated_at = datetime.now(timezone.utc)

    db.session.add(chat_turn)
    db.session.add(chat_message)
    db.session.commit()

    return jsonify({"message": "chat tersimpan", "chat": chat_turn.to_dict(), "thread": thread.to_dict()}), 201
