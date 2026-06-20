# Menghubungkan Claude/Anthropic-compatible client ke gateway pihak ketiga (Olagon)

Ringkasan singkat
- Buat file `.env` di root repo dan isi `OLOGON_API_KEY_1`, `OLOGON_API_KEY_2`, dan opsional `OLOGON_API_KEY_3`.
- Untuk Claude Code lokal, gunakan `.claude/settings.local.json` dengan `apiKeyHelper` agar key aktif diambil dari state file `.claude/olagon-key-state.txt`.
- Untuk chat terminal seperti GPT, pakai `scripts/openrouter-chat.cmd` atau `scripts/openrouter-chat.ps1`.
- Gunakan `scripts/test-gateway.ps1` untuk menguji koneksi.

Langkah langkah

1. Salin file contoh: `.env.example` → `.env` dan isi `OLOGON_API_KEY_1` dengan key aktif dari dashboard Olagon.
2. Jika Anda punya akun/key kedua atau ketiga, isi `OLOGON_API_KEY_2` dan `OLOGON_API_KEY_3` untuk opsi failover.

3. Jalankan tes sederhana (PowerShell):

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\test-gateway.ps1
```

3. Jika berhasil, Anda akan mendapat respons JSON dari gateway.

Di mana menempel API key (pilihan):
- Paling aman: buat file `.env` di root repo (lihat `.env.example`) dan isi `OLOGON_API_KEY_1`, `OLOGON_API_KEY_2`, serta `OLOGON_API_KEY_3` jika tersedia.
- Untuk Claude Code: simpan config di `C:\Users\<nama-user>\.claude\settings.json` atau `.\claude\settings.local.json` di repo, lalu pakai `apiKeyHelper`.
- Key aktif dipilih dari `.claude\olagon-key-state.txt`. Isi `1`, `2`, atau `3` untuk memilih key yang dipakai helper berikutnya.
- Jika Anda hanya mau satu key aktif, isi hanya key yang dipakai dan set state file ke nomor key itu.

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

Untuk Codex CLI lokal dengan KoboiLLM:
- Jalankan `codex-koboillm.cmd` dari root repo, atau panggil full path file itu dari luar project.
- Wrapper ini membaca `KOBOILLM_API_KEY` dari `.env` atau User environment.
- Model aktif default: `gemini-2.5-flash`
- Base URL aktif: `https://api.koboillm.com/v1`
- Working root terkunci ke worktree ini: `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final`
- Jika Anda mau prompt langsung, tambahkan setelah command; kalau tidak, Codex akan masuk ke sesi interaktif.

Untuk Claude Code di Windows:
- Simpan config di `.claude/settings.local.json`
- Pakai `apiKeyHelper` untuk membaca `scripts/get-olagon-key.cmd`
- Pakai `ANTHROPIC_BASE_URL=https://gateway.olagon.site/anthropic`
- Gunakan `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` untuk mengatur seberapa sering key di-refresh
- Untuk pindah key secara manual, ubah `.claude\olagon-key-state.txt` ke `1`, `2`, atau `3`

Keamanan
- Jangan commit `.env` — `.gitignore` sudah menambahkan pola untuk itu.
- Jika key bocor, revoke/regenerate di dashboard Olagon.
