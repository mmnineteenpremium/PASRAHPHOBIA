# Monetization Decision Record 2026-04-10

## Tujuan

Mengunci keputusan monetization v1 agar tidak drift dan tidak memicu refactor besar setelah publish.

## Keputusan V1 (Locked)

- `DeveloperProduct` dipakai untuk semua currency pack berulang:
  - `pp_pack_small`
  - `pp_pack_standard`
  - `pp_pack_large`
  - `mm_pack_small`
  - `mm_pack_medium`
  - `mm_pack_large`
- `GamePass` dipakai untuk entitlement permanen:
  - `royalpass_premium_track`
  - `class_dukun_unlock`
  - `class_detective_unlock`
  - `lifetime_bonus_pass`
- `Subscription` tidak dipakai pada release v1.

## Alasan

- Menjaga scope publish tetap sempit dan stabil.
- Menghindari migrasi ekonomi di menit akhir.
- Arsitektur server/client yang aktif sekarang sudah align dengan pola `DeveloperProduct + GamePass`.

## Dampak Operasional

- `6` currency product boleh aktif (`enabled=true`) setelah ID resmi terisi.
- `4` game pass tetap disabled sampai fairness/compliance lane mengizinkan.
- Semua perubahan monetization v2 wajib masuk lane terpisah, tidak menahan publish v1.

## Guardrail Anti-Drift

- Jangan mengganti `marketplaceType` item aktif tanpa design decision baru.
- Jangan memindahkan entitlement ke subscription di branch release v1.
- Evaluasi subscription dilakukan hanya di backlog v2 dengan test plan renewal/expiry/revoke.

## Bukti Baseline Saat Keputusan Diambil

- `scripts/audit-marketplace-mapping.ps1`:
  - `Safe items missing marketplaceId: 0`
  - `Safe items still disabled: 0`
  - `Hold items accidentally enabled: 0`
- `scripts/release-preflight.ps1`:
  - `Build ok: True`
  - `Safe items missing ID: 0`
  - `Safe items disabled: 0`
  - `Hold items enabled: 0`
