# Google Sign-In — Panduan Implementasi (Pixel Pocket Mobile)

> Dokumen ini berisi **tahapan pembuatan** fitur login Google.
> Tanggal: 2026-06-17 · Status: **sudah diimplementasi** (kecuali Tahap 0 + isi client ID asli)
>
> Sisa yang WAJIB Anda lakukan agar berjalan:
> 1. Isi `serverClientId` asli di `lib/features/auth/auth_config.dart`.
> 2. Isi `GIDClientID` + URL scheme (REVERSED_CLIENT_ID) asli di `ios/Runner/Info.plist`.

---

## 1. Keputusan desain

| Topik | Keputusan |
|---|---|
| Provider | **Google saja**, tanpa Firebase |
| Kredensial ke API | **Google ID Token** dikirim sebagai `Authorization: Bearer <id_token>` |
| Verifikasi | **Backend sudah** verifikasi signature + `aud` ke Google, balas `401` jika invalid |
| Routing | **Gate penuh** — wajib login; silent sign-in saat launch + `go_router` redirect guard |
| Penyimpanan token | **Tidak menyimpan token sendiri** — ID token diambil fresh dari SDK tiap dibutuhkan; sesi disimpan SDK di Keychain/Keystore |
| Refresh token | Tidak ada store sendiri — SDK yang urus; basi → ambil ulang / logout |

## 2. Alur runtime

```
App launch
  └─ silent sign-in (SDK, tanpa UI)
       ├─ ada sesi  → ambil ID token → /transactions
       └─ tdk ada   → /login

Login screen → "Sign in with Google"
  → SDK buka UI akun → balik dengan ID Token
  → authState = signedIn → redirect /transactions

Tiap request API
  → interceptor tempel: Authorization: Bearer <ID token segar>
  → backend verifikasi signature + audience

Token kedaluwarsa / 401
  → interceptor ambil ID token baru → retry 1x
  → tetap gagal → logout → /login
```

**Catatan kunci:** ID token Google hidup **±60 menit**. Jangan perlakukan sebagai nilai persisten — selalu ambil fresh dari SDK; yang persisten adalah sesi SDK.

## 3. Peta file (mengikuti konvensi arsitektur)

```
core/
├── api/
│   ├── api_client.dart        ← (ubah) pasang AuthInterceptor
│   └── auth_interceptor.dart  ← (baru) inject Bearer + retry 401
└── router/
    └── app_router.dart        ← (ubah) redirect guard + /login + /splash

features/auth/
├── repositories/
│   └── auth_repository.dart   ← bungkus SDK google_sign_in
├── providers/
│   └── auth_provider.dart     ← authState + authController
└── screens/
    ├── splash_screen.dart     ← loader saat silent sign-in
    └── login_screen.dart      ← tombol "Sign in with Google" (UI only)
```

Aturan tetap berlaku: repository & provider **tidak** import widget; screen **tanpa** logic/Dio/parsing.

---

## 4. Tahapan pembuatan

### Tahap 0 — Google Cloud Console *(di luar koding, kerjakan paling awal)*
- [ ] OAuth Client **tipe Web** → jadi `serverClientId`; `aud`-nya harus sama dengan yang backend verifikasi.
- [ ] OAuth Client **tipe Android** → daftarkan **SHA-1 debug & release** (release dari keystore di `android/key.properties`).
- [ ] OAuth Client **tipe iOS** → catat `iOS client ID` + `REVERSED_CLIENT_ID`.
- **DoD:** punya 3 client ID + tahu pasti `aud` mana yang backend cek.

### Tahap 1 — Dependency
- [ ] `google_sign_in: ^7.x` di `pubspec.yaml` → `flutter pub get`.
- **Gotcha:** API v7 beda dari tutorial lama (`GoogleSignIn.instance`, `initialize()`, `authenticate()`).

### Tahap 2 — Konfigurasi native
- [ ] **Android:** cukup `serverClientId` lewat kode (tanpa Firebase = tanpa `google-services.json`); pastikan SHA-1 terdaftar.
- [ ] **iOS:** `REVERSED_CLIENT_ID` sebagai URL scheme di `Info.plist`, set `GIDClientID`.
- **DoD:** build OK di kedua platform.

### Tahap 3 — `features/auth/repositories/auth_repository.dart`
Method (tanpa widget):
- [ ] `initialize()` → `GoogleSignIn.instance.initialize(serverClientId: ...)` sekali.
- [ ] `silentSignIn()` → `attemptLightweightAuthentication()`; return akun/null.
- [ ] `signIn()` → `authenticate()` (interaktif); return akun.
- [ ] `signOut()`.
- [ ] `getIdToken()` → `authentication.idToken` **fresh**; null bila tak ada sesi.
- **Gotcha:** selalu ambil token terbaru, jangan cache manual.

### Tahap 4 — `features/auth/providers/auth_provider.dart`
- [ ] `authRepositoryProvider`.
- [ ] `authStateProvider` → `unknown | signedOut | signedIn(user)`; diisi via `silentSignIn()` saat launch.
- [ ] `authControllerProvider` → `login()` & `logout()`; logout meng-`invalidate` provider data (mis. `transactionsProvider`).

### Tahap 5 — `core/api/auth_interceptor.dart`
- [ ] `onRequest`: `getIdToken()` → set `Authorization: Bearer <token>` bila ada.
- [ ] `onError`: bila **401 & belum retry** → token baru → ulang request **sekali**; gagal lagi → trigger logout, teruskan error.
- **Gotcha:** tandai `request.extra` agar retry tidak loop.

### Tahap 6 — `core/api/api_client.dart`
- [ ] Sisipkan `AuthInterceptor` ke `dio.interceptors` **sebelum** `LogInterceptor`.
- **Gotcha:** interceptor butuh `ref` → konstruksi `ApiClient`/`dio` via provider yang punya `ref`.

### Tahap 7 — `features/auth/screens/login_screen.dart`
- [ ] UI only: branding + tombol "Sign in with Google" → `authController.login()`.
- [ ] Loading/error via `authState` / `.when`.

### Tahap 8 — Router guard `core/router/app_router.dart`
- [ ] Tambah route `/login` & `/splash`.
- [ ] `redirect`:
  - `unknown` → `/splash`
  - `signedOut` & bukan `/login` → `/login`
  - `signedIn` & di `/login`/`/splash` → `/transactions`
- [ ] `refreshListenable` mendengar `authStateProvider`.
- **Gotcha:** jangan redirect saat `unknown` (hindari flicker ke login).

### Tahap 9 — Splash / bootstrap
- [ ] Saat start: `initialize()` → `silentSignIn()` → set `authState`; splash tampil loader.

### Tahap 10 — Logout
- [ ] Tombol logout (mis. AppBar Transaksi) → `authController.logout()` → `signOut()` + `authState=signedOut` → guard lempar ke `/login`.

---

## 5. Urutan & prioritas
1. **Tahap 0 → 1 → 2** dulu — kalau client ID/SHA-1 salah, kode sebagus apa pun tetap ditolak backend.
2. Logika inti: **Tahap 3, 5, 8**.

## 6. Checklist verifikasi
- [ ] `flutter analyze` bersih.
- [ ] Launch → silent sign-in jalan (tidak flicker ke login bila ada sesi).
- [ ] Login interaktif → masuk ke `/transactions`.
- [ ] Request API membawa header `Bearer`.
- [ ] Paksa 401 (token dummy) → auto-logout ke `/login`.
- [ ] Logout normal → kembali ke `/login`.
- [ ] Backend benar-benar verifikasi & `aud` cocok.

## 7. Yang TIDAK dilakukan (YAGNI)
- Tanpa Firebase, tanpa session/JWT lokal, tanpa refresh-token store sendiri.
- Tanpa multi-provider (Apple/email).
- Tanpa profile screen (cukup avatar/email + logout).

## 8. Pertanyaan terbuka
- [ ] Client ID & SHA-1 sudah disiapkan di Google Cloud Console?
- [ ] `aud` yang backend verifikasi = **Web client ID** yang mana?
