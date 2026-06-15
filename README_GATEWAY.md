# Menghubungkan Claude/Anthropic-compatible client ke gateway pihak ketiga (Olagon)

Ringkasan singkat
- Buat file `.env` di root repo dan isi `OLOGON_API_KEY_1` dan opsional `OLOGON_API_KEY_2`.
- Untuk Claude Code lokal, gunakan `.claude/settings.local.json` dengan `apiKeyHelper` agar rotasi key berjalan otomatis.
- Untuk chat terminal seperti GPT, pakai `scripts/openrouter-chat.cmd` atau `scripts/openrouter-chat.ps1`.
- Gunakan `scripts/test-gateway.ps1` untuk menguji koneksi.

Langkah langkah

1. Salin file contoh: `.env.example` → `.env` dan isi `OLOGON_API_KEY_1` dengan key aktif dari dashboard Olagon.
2. Jika Anda punya akun/key kedua, isi `OLOGON_API_KEY_2` untuk fallback otomatis.

3. Jalankan tes sederhana (PowerShell):

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\test-gateway.ps1
```

3. Jika berhasil, Anda akan mendapat respons JSON dari gateway.

Di mana menempel API key (pilihan):
- Paling aman: buat file `.env` di root repo (lihat `.env.example`) dan isi `OLOGON_API_KEY_1` serta `OLOGON_API_KEY_2`.
- Untuk Claude Code: simpan config di `C:\Users\<nama-user>\.claude\settings.json` atau `.\claude\settings.local.json` di repo, lalu pakai `apiKeyHelper`.
- Jika Anda hanya mau satu key aktif, isi `OLOGON_API_KEY_1` saja dan biarkan `OLOGON_API_KEY_2` kosong.

Untuk chat OpenRouter yang persisten:
- Jalankan `scripts/openrouter-chat.cmd`
- Session tersimpan di `.codex/openrouter-sessions/<nama>.json`
- Gunakan `/exit` untuk keluar, `/reset` untuk menghapus konteks sesi, dan `/model <slug>` untuk ganti model
- Jika Anda menjalankan lagi dengan nama sesi yang sama, percakapan lama akan dilanjutkan

Untuk chat KoboiLLM yang persisten:
- Isi `KOBOILLM_API_KEY` di `.env` atau User environment.
- Default base URL: `https://api.koboillm.com/v1`
- Jalankan `kochat.cmd` dari root repo, atau `scripts/koboillm-chat.cmd`.
- Session tersimpan di `.codex/koboillm-sessions/<nama>.json`.
- Gunakan `/models` untuk melihat model aktif dari key Anda.
- Gunakan `/model openai/gpt-4o-mini`, `/model anthropic/claude-4-5-sonnet`, `/model gemini/gemini-2.5-flash`, atau model lain sesuai daftar dashboard/API KoboiLLM.

Untuk Claude Code di Windows:
- Simpan config di `.claude/settings.local.json`
- Pakai `apiKeyHelper` untuk membaca `scripts/get-olagon-key.cmd`
- Pakai `ANTHROPIC_BASE_URL=https://gateway.olagon.site/anthropic`
- Gunakan `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` untuk mengatur seberapa sering key di-refresh

Keamanan
- Jangan commit `.env` — `.gitignore` sudah menambahkan pola untuk itu.
- Jika key bocor, revoke/regenerate di dashboard Olagon.
