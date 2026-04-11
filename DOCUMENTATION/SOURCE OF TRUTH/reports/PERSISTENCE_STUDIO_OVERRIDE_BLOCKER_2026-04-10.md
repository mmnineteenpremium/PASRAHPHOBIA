# PERSISTENCE_STUDIO_OVERRIDE_BLOCKER_2026-04-10

## Tujuan

Mencatat hasil percobaan persistence non-mock dari sesi `rbxlx` lokal aktif pada `2026-04-10`.

## Environment

- source: `PASRAHPHOBIA.rbxlx` lokal
- runtime: Roblox Studio Play Solo
- `PlaceId = 0`
- `GameId = 0`
- override dicoba dengan `ReplicatedStorage:SetAttribute("PasrahUseStudioDataStore", true)`

## Hasil

- `DataPersistenceService` memang mendukung jalur override Studio ke real DataStore.
- Override berhasil terbaca oleh code path.
- Namun saat boot server, registry gagal instantiate `DataPersistenceService` dengan error:
  - `You must publish this place to the web to access DataStore.`

Console proof:

- `[DataPersistenceService] Studio runtime detected. Using real DataStore because studio override is enabled.`
- `[Registry] Failed instantiating DataPersistenceService: You must publish this place to the web to access DataStore.`

## Interpretasi

Ini membuktikan bahwa `rbxlx` lokal aktif bukan target yang valid untuk menutup gate persistence non-mock.

Masalahnya bukan pada logic override persistence, tetapi pada environment:
- place belum terikat ke web runtime publish
- `PlaceId/GameId` masih `0/0`

## Implikasi Operasional

Gate persistence non-mock hanya bisa ditutup di salah satu environment berikut:

1. place cloud yang sudah publish dan benar-benar dibuka di Studio
2. runtime target lain yang memiliki DataStore nyata dan bukan session `rbxlx` lokal `PlaceId=0`

## Status

- `STUDIO LOCAL NON-MOCK ATTEMPT: BLOCKED BY ENVIRONMENT`
- `PERSISTENCE PUBLISH GATE: STILL PENDING`
