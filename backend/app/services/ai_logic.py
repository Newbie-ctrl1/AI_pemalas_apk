import os
from hashlib import md5

import requests


def _pick(text: str, options: list[str]) -> str:
    # Stable choice per prompt to keep responses predictable.
    if not options:
        return ""
    index = int(md5(text.encode("utf-8")).hexdigest(), 16) % len(options)
    return options[index]


def _local_lazy_response(prompt: str) -> str:
    text = (prompt or "").strip().lower()

    if not text:
        return "Nanya dulu yang jelas, gue lagi mode hemat energi."

    if "apa itu ai" in text or text == "ai":
        return "AI itu komputer yang sok pinter. Udah gitu aja."

    if "to-do" in text or "todo" in text or "to do" in text:
        return "Ini ya, singkat: belajar, makan, beresin kerjaan, tidur."

    if "ringkas" in text or "singkat" in text or "summary" in text:
        return "Versi malas: ambil poin inti, buang drama, selesai."

    if "motivasi" in text or "semangat" in text:
        return "Semangat dikit. Kerjain 10 menit dulu, nanti lanjut lagi."

    if "terima kasih" in text or "makasih" in text or "thanks" in text:
        return "Iya iya, sama-sama."

    intros = [
        "Oke, gini aja:",
        "Yaudah, singkatnya:",
        "Nih versi hemat tenaga:",
        "Biar cepet ya:",
    ]
    closers = [
        "Udah, jangan dipanjangin.",
        "Cukup segitu dulu.",
        "Sisanya improvisasi dikit.",
        "Kalau mau detail, bilang aja.",
    ]

    intro = _pick(text + "-intro", intros)
    closer = _pick(text + "-closer", closers)

    return f"{intro} fokus ke 1 hal dulu, pecah kecil-kecil, kerjain sekarang. {closer}"


def _groq_lazy_response(prompt: str) -> str | None:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        return None

    model = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant").strip() or "llama-3.1-8b-instant"
    base_url = os.getenv("GROQ_BASE_URL", "https://api.groq.com/openai/v1").rstrip("/")

    style_prompt = (
        "Kamu adalah AI Pemalas. Aturan: jawaban harus singkat, santai, sedikit sarkas tapi tidak kasar, "
        "hindari penjelasan panjang kecuali diminta, kadang terdengar ogah-ogahan. "
        "Jawab dalam bahasa Indonesia. Maks 2 kalimat pendek."
    )

    try:
        response = requests.post(
            f"{base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "temperature": 0.7,
                "max_tokens": 120,
                "messages": [
                    {"role": "system", "content": style_prompt},
                    {"role": "user", "content": prompt},
                ],
            },
            timeout=12,
        )
        response.raise_for_status()
        payload = response.json()
        content = payload.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        return content or None
    except Exception:
        return None


def generate_lazy_ai_response(prompt: str) -> str:
    groq_answer = _groq_lazy_response(prompt)
    if groq_answer:
        return groq_answer

    return _local_lazy_response(prompt)
