# Roadmap: AI Pemalas

## Gambaran Project
Aplikasi full-stack sederhana: Flutter mobile app sebagai frontend, Flask REST API sebagai backend, PostgreSQL sebagai database online, dan logika AI Pemalas dengan mode hybrid (Groq API + fallback rule-based) untuk jawaban singkat, santai, dan sedikit sarkas.

## Arsitektur Sistem
Flutter App <-> Flask API <-> PostgreSQL
                      |
                      +-> AI Service (Groq API)
                      |
                      +-> Fallback AI Logic (rule-based lokal)

## Flow Login & JWT
1. User register via Flutter.
2. Flutter kirim data ke endpoint register.
3. User login via Flutter.
4. Flask validasi, generate JWT.
5. Flutter simpan token di shared_preferences.
6. Request berikutnya kirim Authorization: Bearer <token>.

## Flow Chat AI
1. User kirim prompt.
2. Flutter kirim ke endpoint chat.
3. Flask cek JWT.
4. Flask panggil Groq API untuk jawaban AI Pemalas.
5. Jika Groq gagal / key kosong, fallback ke rule-based lokal.
6. Simpan chat ke database.
7. Kirim response ke Flutter.

## Struktur Folder
### Backend (Flask)
backend/
- app/
  - __init__.py
  - main.py
  - routes/
    - auth.py
    - chat.py
    - tasks.py
  - models/
    - user.py
    - chat.py
    - task.py
  - services/
    - ai_logic.py
  - extensions/
    - db.py
    - jwt.py
- requirements.txt
- Procfile

### Frontend (Flutter)
lib/
- main.dart
- screens/
  - login_screen.dart
  - chat_screen.dart
  - tasks_screen.dart
- services/
  - api_service.dart
  - auth_service.dart
- models/
  - chat_message.dart
  - task.dart
- widgets/
  - chat_bubble.dart

## Step-by-Step Development Plan
1. Setup Flask backend.
2. Setup database PostgreSQL.
3. Implementasi register API.
4. Implementasi login API (JWT).
5. Middleware auth.
6. AI response logic (Groq + fallback rule-based).
7. Chat API endpoint.
8. Deploy backend ke Railway.
9. Setup Flutter project.
10. Login UI Flutter.
11. Simpan token.
12. Chat UI Flutter.
13. Integrasi API.
14. History chat.
15. Finishing UI.

## Checklist Progress
- [x] 1. Setup Flask backend
- [x] 2. Setup database PostgreSQL
- [x] 3. Implementasi register API
- [x] 4. Implementasi login API (JWT)
- [x] 5. Middleware auth
- [x] 6. AI response logic (Groq + fallback rule-based)
- [x] 7. Chat API endpoint
- [ ] 8. Deploy backend ke Railway
- [ ] 9. Setup Flutter project
- [ ] 10. Login UI Flutter
- [ ] 11. Simpan token
- [ ] 12. Chat UI Flutter
- [ ] 13. Integrasi API
- [ ] 14. History chat
- [ ] 15. Finishing UI

## Output Tiap Tahap
1. Backend Flask bisa jalan lokal.
2. Database PostgreSQL terkoneksi.
3. Endpoint register berfungsi.
4. Endpoint login mengembalikan JWT.
5. Endpoint terproteksi JWT.
6. AI logic menghasilkan jawaban singkat via Groq, dengan fallback lokal.

## Konfigurasi Groq
1. Isi GROQ_API_KEY di file backend/.env.
2. (Opsional) ganti GROQ_MODEL sesuai kebutuhan.
3. Jika GROQ_API_KEY kosong, sistem otomatis pakai fallback rule-based.

## Deploy Railway
1. Buat project baru di Railway dan pilih source repo ini.
2. Set root directory ke backend.
3. Tambahkan environment variables: DATABASE_URL, JWT_SECRET_KEY, GROQ_API_KEY (opsional), GROQ_MODEL (opsional).
4. Railway akan pakai start command dari railway.json/Procfile.
5. Setelah deploy sukses, cek endpoint /health.
7. Endpoint chat menyimpan history.
8. Backend online di Railway.
9. Flutter app siap jalan.
10. UI login tampil.
11. Token tersimpan.
12. UI chat tampil.
13. Integrasi API sukses.
14. History chat tampil.
15. UI final rapi.
