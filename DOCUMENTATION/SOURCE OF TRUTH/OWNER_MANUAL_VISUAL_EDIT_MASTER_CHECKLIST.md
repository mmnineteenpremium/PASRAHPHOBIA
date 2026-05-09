# Owner Manual Visual Edit Master Checklist

Tanggal: 2026-05-03  
File Studio wajib: `PASRAHPHOBIA.rbxlx`  
Status: siap untuk owner visual edit pass

Checklist ini adalah pegangan utama owner untuk mengecek dan mengedit visual manual di Roblox Studio. Tujuannya agar owner bisa mengubah tampilan dengan mata langsung tanpa merusak wiring logic game.

## Prinsip Utama

- Edit visual di `StarterGui` dan `ReplicatedStorage > Assets > VisualTemplates`.
- Jangan edit `PlayerGui` saat Play Test karena itu hasil runtime dan tidak persist.
- Jangan rename object yang sudah ada, karena script runtime mencari nama tersebut.
- Jangan memindahkan object keluar dari parent aslinya kecuali memang diminta.
- Script tetap menjadi pemilik logic visibility, flow match, reward, room, shop, quest, spectator, dan result.
- Owner hanya mengatur visual: posisi, ukuran, warna, image, font Roblox yang tersedia, stroke, corner, gradient, transparency, z-index, padding, layout, spacing, dan asset image.

## Cara Pakai Checklist

- Buka `PASRAHPHOBIA.rbxlx`.
- Pastikan yang diedit adalah Edit Mode, bukan Play Mode.
- Lighting Edit Mode sudah diset ke preset `BrightNoFog`: terang, fog jauh, `GlobalAtmosphere` density/haze/glare 0, dan shadow global off agar viewport mudah diedit.
- Jika Play Test membuat suasana kembali gelap/horror, itu runtime gameplay effect; setelah Stop Play, edit-mode lighting harus kembali mengikuti preset terang di file.
- Untuk preview layout, boleh centang `Enabled` pada `ScreenGui` atau `Visible` pada `Frame` sementara.
- Setelah selesai preview, tidak wajib mengembalikan semua `Visible`; runtime akan mengontrol visibility saat Play Test.
- Untuk visual first-person/FPV, gunakan preview Edit Mode di `Workspace > Checklist Visualtemplates`, bukan `PlayerGui` atau hasil Play Test.
- Setelah satu bagian selesai, Play Test satu client dan cek flow yang relevan.
- Jika ada panel terbuka bersamaan saat Play Test, itu bug runtime, bukan kesalahan edit visual owner.

## Checklist StarterGui

Centang setelah setiap surface sudah dicek visual, ukuran, text readability, dan tidak ada object penting yang terhapus.

- [x] `FlashlightToggleUI`
- [x] `FPVCursorToggleUI`
- [x] `JournalUI`
- [x] `LeaderboardUI`
- [x] `LobbyUI`
- [x] `LobbyUXGui`
- [x] `MainMenuUI`
- [x] `MatchLoadingUI`
- [x] `MatchUI`
- [x] `MatchUXGui`
- [x] `PASRAHPHOBIA_BottomNavbar_Static`
- [x] `PASRA_UI`
- [x] `ProfileUI`
- [x] `QuestJournalGui`
- [x] `QuestPopupGui`
- [x] `QuestTrackerGui`
- [x] `RoomBrowserFloatUI`
- [x] `RoomBrowserUI`
- [x] `RoyalPassUI`
- [x] `SanityHUDGui`
- [x] `SensoryHorrorHUD`
- [x] `ShopUI`
- [x] `SpectatorUI`
- [x] `TeleportScreen`

## Checklist VisualTemplates

Edit template ini untuk visual yang diclone runtime ke UI child, world marker, tool, ghost, dan world effects.

- [ ] `ReplicatedStorage > Assets > VisualTemplates > UI`
- [ ] `ReplicatedStorage > Assets > VisualTemplates > WorldMarkers`
- [ ] `ReplicatedStorage > Assets > VisualTemplates > WorldSurfaces`
- [ ] `ReplicatedStorage > Assets > VisualTemplates > ToolVisuals`
- [ ] `ReplicatedStorage > Assets > VisualTemplates > GhostVisuals`
- [ ] `ReplicatedStorage > Assets > VisualTemplates > WorldEffects`

Template UI penting:

- [ ] `UI.ButtonPolishChildrenTemplate`
- [ ] `UI.FloatingButtonChildrenTemplate`
- [ ] `UI.PricePillChildrenTemplate`
- [ ] `UI.SummaryRowTemplate`
- [ ] `UI.FieldKitButtonTemplate`
- [ ] `UI.LobbyTrainingSupportCardTemplate`
- [ ] `UI.FlatPreviewFallbackTemplate`

Template world/tool/ghost penting:

- [ ] `WorldMarkers.SafeZoneMarkerBillboardTemplate`
- [ ] `WorldMarkers.HideSpotMarkerBillboardTemplate`
- [ ] `WorldMarkers.DoorRouteGuideBillboardTemplate`
- [ ] `WorldMarkers.InteractionGuideBillboardTemplate`
- [ ] `WorldMarkers.TraversalGuideBillboardTemplate`
- [ ] `WorldMarkers.LobbyCosmeticBillboardTemplate`
- [ ] `WorldMarkers.LobbyZoneGuideBillboardTemplate`
- [ ] `WorldMarkers.LobbyZoneEntryGuideBillboardTemplate`
- [ ] `WorldSurfaces.LobbyGuideBoardSurfaceTemplate`
- [ ] `WorldSurfaces.MapBoardSurfaceTemplate`
- [ ] `ToolVisuals.EMFScreenBillboardTemplate`
- [ ] `ToolVisuals.ThermoScreenBillboardTemplate`
- [ ] `ToolVisuals.CameraScreenSurfaceTemplate`
- [ ] `ToolVisuals.FlashlightLocalSpotLightTemplate`
- [ ] `ToolVisuals.ToolUseBurstEmitterTemplate`
- [ ] `ToolVisuals.ToolUseSmokePlumeEmitterTemplate`
- [ ] `ToolVisuals.ToolUseHolyHaloEmitterTemplate`
- [ ] `ToolVisuals.ToolUseScanPulseEmitterTemplate`
- [ ] `ToolVisuals.ToolUsePulseLightTemplate`
- [ ] `GhostVisuals.StudioGhostPreviewLabelTemplate`
- [ ] `WorldEffects.WorldHighlightTemplate`
- [ ] `WorldEffects.WorldPointLightTemplate`
- [ ] `WorldEffects.WorldSpotLightTemplate`
- [ ] `WorldEffects.WorldBeamTemplate`
- [ ] `WorldEffects.WorldParticleEmitterTemplate`
- [ ] `WorldEffects.WorldBoxOutlineTemplate`
- [ ] `WorldEffects.WorldFireTemplate`

## FPV/FVP Hand And Investigation Tools Visual Edit

Bagian ini untuk visual first-person view: posisi tangan, posisi alat saat dipegang, jarak alat dari kamera, rotasi grip, beam/screen alignment, dan feel visual saat player memakai Investigation Tools. Targetnya owner bisa melihat dan mengedit visual awal langsung di Edit Mode tanpa perlu Play Test.

Lokasi preview wajib:

- `Workspace > Checklist Visualtemplates > FPVHandAndToolPreview`
- `Workspace > Checklist Visualtemplates > FPVHandAndToolPreview > CameraReference`
- `Workspace > Checklist Visualtemplates > FPVHandAndToolPreview > HandRigPreview`
- `Workspace > Checklist Visualtemplates > FPVHandAndToolPreview > ToolHoldPreviews`

Task agent sebelum owner edit:

- [ ] Buat/refresh `FPVHandAndToolPreview` di `Workspace > Checklist Visualtemplates` dari template/source terbaru.
- [ ] Tampilkan preview tangan kiri/kanan dan arms first-person di Edit Mode.
- [ ] Tampilkan setiap Investigation Tool sebagai preview hold terpisah di `ToolHoldPreviews`.
- [ ] Set `CameraReference` sebagai frame acuan kamera first-person agar jarak alat dari layar bisa dinilai di Edit Mode.
- [ ] Pastikan preview tidak membutuhkan Play Test, tidak memakai `PlayerGui`, dan tidak spawn dari runtime live character.
- [ ] Pastikan preview hanya staging visual dan tidak dipakai langsung sebagai runtime gameplay object.
- [ ] Setelah owner approve, sinkronkan nilai visual yang disetujui ke source runtime yang benar, misalnya `ToolVisualConfig.lua`, `ToolVisualController`, atau template terkait.

Task owner visual:

- [ ] Posisi tangan kanan terlihat natural saat memegang alat.
- [ ] Posisi tangan kiri tidak menembus tool, torso, atau area kamera.
- [ ] Jarak tool dari kamera tidak terlalu dekat sampai menutup tengah layar.
- [ ] Jarak tool dari kamera tidak terlalu jauh sampai terasa tidak sedang dipegang.
- [ ] Rotasi tool mengikuti arah tangan dan tidak miring aneh pada view first-person.
- [ ] Scale tool konsisten antar alat dan tidak raksasa/kekecilan.
- [ ] Grip/handle sejajar dengan telapak tangan.
- [ ] Tool tidak menutup crosshair, objective utama, atau indikator interaksi.
- [ ] Animasi idle/hold yang nanti dipakai runtime masih masuk akal dengan pose preview.
- [ ] Beam flashlight keluar dari ujung flashlight, bukan dari tangan atau tengah badan.
- [ ] Screen/sensor tool seperti EMF/thermo/camera masih terbaca dari sudut first-person.
- [ ] Efek use seperti burst, smoke, halo, scan pulse, dan pulse light muncul dari posisi alat yang benar.
- [ ] Tool tidak clip ke dinding saat kamera dekat permukaan pada jarak normal.
- [ ] Tampilan masih nyaman di desktop 16:9.
- [ ] Tampilan masih nyaman di mobile landscape.

Investigation Tool hold preview yang wajib ada:

- [ ] `Flashlight`
- [ ] `BolaArwah`
- [ ] `BukuTerkutuk`
- [ ] `Dupa`
- [ ] `Garam`
- [ ] `GerakanGaib`
- [ ] `JejakEnergi`
- [ ] `KotakArwah`
- [ ] `PilSanity`
- [ ] `Salib`
- [ ] `SuhuMembeku`

Yang boleh owner edit di FPV preview:

- `Position`
- `Orientation`
- `Rotation`
- `Size`
- `Scale`
- `Pivot`
- `Attachment.Position`
- `Attachment.Orientation`
- `Beam.Attachment0` / `Beam.Attachment1` hanya jika sudah jelas attachment visualnya.
- `PointLight` / `SpotLight` visual properties.
- `ParticleEmitter` visual properties yang hanya mengubah tampilan.

Larangan khusus FPV preview:

- Jangan edit tool runtime di `Backpack`, `StarterPack`, atau character live Play Test.
- Jangan rename `Handle`, `Grip`, `CameraReference`, `HandRigPreview`, atau nama tool preview.
- Jangan edit script untuk mengubah hold offset manual.
- Jangan memakai hasil runtime `PlayerGui` atau `Workspace.CurrentCamera` sebagai sumber permanen.
- Jangan publish sebelum agent menyinkronkan preview yang disetujui ke source runtime.

## Asset Dan Placeholder Yang Wajib Dicek Owner

Scan source terakhir tidak menemukan placeholder eksplisit seperti `TODO`, `PLACEHOLDER`, atau `rbxassetid://0` di area `StarterGui` dan `Assets`. Namun bagian berikut tetap wajib dicek manual karena kualitasnya bergantung asset final.

- [ ] Semua `ImageLabel` dan `ImageButton` punya gambar final, bukan gambar sementara.
- [ ] Semua icon close/back/leave/join/menu/shop/profile/royal pass/quest punya asset final.
- [ ] Semua image text PNG dari font eksternal sudah terpasang pada tempat yang benar.
- [ ] Semua button state memakai asset final idle/hover/active jika memang ada.
- [ ] Semua backdrop panel penting punya gambar final atau warna final.
- [ ] Semua rarity frame, reward frame, shop card, catalog card, dan currency icon memakai asset final.
- [ ] Semua `BrandTextImage` dicek apakah perlu diganti dari text Roblox ke PNG custom.
- [ ] Semua `TextLabel` yang masih text Roblox dicek apakah memang boleh tetap text Roblox.
- [ ] Semua template world marker terbaca saat kamera jauh/dekat.
- [ ] Semua SurfaceGui board di lobby/map tidak terlalu kecil atau terlalu terang.
- [ ] Semua effect visual seperti fire, beam, particle, highlight, point light, dan spot light tidak berlebihan.
- [ ] Semua icon mobile tidak terlalu kecil untuk disentuh.
- [ ] Semua icon desktop tidak terlalu besar saat resolusi 1920x1080.
- [ ] Semua panel fullscreen tetap fit pada 1280x720, 1920x1080, dan ultrawide.

## Ghost Behavior Scope

Ghost behavior tidak termasuk area edit manual owner.

Yang termasuk ghost behavior dan tidak boleh disentuh owner:

- `GhostSystem`
- `GhostDirector`
- `GhostChaseSystem`
- `GhostPathingSystem`
- `GhostPersonalitySystem`
- `GhostStrategySystem`
- `GhostModifierSystem`
- `GhostDatabaseSystem`
- `GhostAbilityRegistry`
- `GhostAbilityEngine`
- `MapEventSystem`
- `DynamicInvestigationEventSystem`
- `HorrorDirector`

Yang boleh disiapkan/dicek owner adalah asset yang dipakai oleh behavior tersebut:

- ghost model
- ghost rig
- ghost texture/material
- ghost animation
- ghost preview visual
- ghost SFX
- ghost VFX
- event prop 3D
- HUD/sensory overlay visual
- fallback visual/audio yang muncul jika asset utama tidak valid

## Ghost Model Dan Rig Asset Checklist

Asset ghost yang sudah terdeteksi di source:

- [ ] `Banaspati.rbxm`
- [ ] `BanaspatiAggressive.rbxm`
- [ ] `Genderuwo.rbxm`
- [ ] `GenderuwoAggressive.rbxm`
- [ ] `HantuTanah.rbxm`
- [ ] `Jerangkong.rbxm`
- [ ] `Kuntilanak.rbxm`
- [ ] `KuntilanakAggressive.rbxm`
- [ ] `Leak.rbxm`
- [ ] `LeakAggressive.rbxm`
- [ ] `Palasik.rbxm`
- [ ] `PalasikAngry.rbxm`
- [ ] `Pocong.model.json`
- [ ] `SilumanUlar.rbxm`
- [ ] `SundelBolong.rbxm`
- [ ] `SundelBolongAggressive.rbxm`
- [ ] `Tuyul.rbxm`
- [ ] `WeweGombel.rbxm`

Lokasi edit/import:

- `ReplicatedStorage > Assets > Models > Ghosts`
- source path: `src/ReplicatedStorage/Assets/Models/Ghosts`

Kualitas PASS ghost model/rig:

- [ ] Model punya `HumanoidRootPart` atau minimal `PrimaryPart` yang jelas.
- [ ] Model punya visual `MeshPart` utama yang tidak terlalu besar.
- [ ] Model tidak collidable untuk runtime ghost visual.
- [ ] Ghost terlihat jelas pada jarak dekat dan sedang.
- [ ] Silhouette ghost terbaca di map gelap.
- [ ] Texture/material tidak terlalu gelap sampai hilang di lighting horror.
- [ ] Scale masuk target gameplay dan tidak raksasa.
- [ ] Root/control part tidak terlihat ke player.
- [ ] CastShadow sesuai style; jangan membuat bayangan aneh jika ghost seharusnya ethereal.
- [ ] Jika memakai rig animasi, tulang/part tidak pecah saat idle/hunt/manifest/jumpscare.
- [ ] Nama asset/model tidak diubah sembarangan setelah sudah dipakai contract.

Catatan inventory/preview asset:

- `GhostVisualTuning.lua` saat ini hanya punya `inventoryModelAssetId` eksplisit untuk sebagian ghost: `Genderuwo`, `Kuntilanak`, `KuntilanakAggressive`, dan `Pocong`.
- [ ] Jika semua ghost harus tampil rapi di inventory/shop/preview, siapkan asset id preview untuk semua ghost lain juga.
- [ ] Jika preview tidak perlu per ghost, minimal pastikan model runtime di `Models.Ghosts` tetap benar.

## Ghost Animation Checklist

Asset animasi ghost yang terdeteksi:

- [ ] `GhostIdle`
- [ ] `GhostHunt`
- [ ] `GhostAttack`
- [ ] `GhostJumpscare`
- [ ] `GhostManifest`

Lokasi:

- `ReplicatedStorage > Assets > Animations > Ghosts`

Kualitas PASS animasi:

- [ ] Idle tidak sliding atau patah.
- [ ] Hunt terbaca lebih agresif dari idle.
- [ ] Attack punya anticipation/impact yang terlihat.
- [ ] Jumpscare punya timing cepat dan jelas.
- [ ] Manifest cocok dengan VFX/sound manifest.
- [ ] Animasi kompatibel dengan rig ghost yang dipakai.

## Event Prop Asset Checklist

Event behavior seperti poltergeist/object throw tetap logic-owned oleh script. Owner menyiapkan asset prop 3D yang aman dipakai event.

Event yang terdeteksi dari runtime:

- `ObjectThrow`
- `DoorSlam`
- `LightFlicker`
- `WindowKnock`
- `RadioStatic`
- `ShadowApparition`
- `FootstepSound`
- `SuddenWhisper`
- `TemperatureDrop`

Asset prop yang sebaiknya disiapkan:

- [ ] kursi ringan untuk event poltergeist/object throw
- [ ] meja kecil
- [ ] buku
- [ ] piring/gelas/botol
- [ ] frame/foto dinding
- [ ] boneka/haunted doll
- [ ] kotak/crate
- [ ] pintu/lemari kecil yang bisa slam
- [ ] jendela/daun jendela untuk knock
- [ ] radio/TV untuk static
- [ ] lampu meja/lampu gantung untuk flicker
- [ ] kain/tirai kecil untuk gerakan visual

Kualitas PASS prop event:

- [ ] Mesh ringan dan tidak terlalu banyak part.
- [ ] Pivot/PrimaryPart berada di posisi masuk akal.
- [ ] Ukuran prop sesuai player scale.
- [ ] Prop punya collision yang aman jika dipakai di map.
- [ ] Prop tidak menutup jalan utama.
- [ ] Prop masih terbaca saat digerakkan cepat oleh VFX/event.
- [ ] Prop tidak punya sound asset 403.
- [ ] Jika prop hanya dekorasi, jangan diberi nama mirip object contract event kecuali sudah dikonfirmasi.

## Ghost SFX Dan Audio Checklist

Audio folder aktif:

- `ReplicatedStorage > Assets > Audio > Ghost`
- `ReplicatedStorage > Assets > Audio > Environment`
- `ReplicatedStorage > Assets > Audio > Jumpscare`
- `ReplicatedStorage > Assets > Audio > Sensory`
- `ReplicatedStorage > Assets > Audio > Footsteps`
- `ReplicatedStorage > Assets > Audio > UI`

Cue audio penting yang dipakai behavior:

- [ ] `ghost_whisper`
- [ ] `ghost_manifest`
- [ ] `ghost_fake_footsteps`
- [ ] `ghost_object_throw`
- [ ] `hunt_start`
- [ ] `hunt_phase_loop`
- [ ] `jumpscare_stinger`
- [ ] `env_doorslam`
- [ ] `env_objectthrow`
- [ ] `env_windowknock`
- [ ] `env_lightflicker`
- [ ] `env_radiostatic`
- [ ] `env_shadowapparition`
- [ ] `env_footstepsound`
- [ ] `env_suddenwhisper`
- [ ] `env_temperaturedrop`
- [ ] `heartbeat_rise`
- [ ] `fear_critical`

Kualitas PASS audio:

- [ ] Asset dimiliki/diizinkan oleh experience owner sehingga tidak HTTP 403.
- [ ] Volume tidak clipping.
- [ ] Ghost whisper terdengar tetapi tidak menutup objective/HUD feedback.
- [ ] Hunt audio terasa berbeda dari ambient biasa.
- [ ] Jumpscare pendek, tajam, dan tidak looping.
- [ ] Object throw/door slam punya impact jelas.
- [ ] Footstep ghost tidak terlalu mirip footstep player jika membingungkan.
- [ ] Semua SFX penting punya varian cukup agar tidak repetitif.

## Audio Asset Error 403 Yang Wajib Diganti

Log Studio aktif masih menunjukkan `Failed to load sound ... HTTP 403` untuk asset berikut:

- [ ] `rbxassetid://412892754`
- [ ] `rbxassetid://188608071`
- [ ] `rbxassetid://3225480278`
- [ ] `rbxassetid://510111269`
- [ ] `rbxassetid://1013366831`

Lokasi object yang memakai asset 403:

- `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Agitation.Motor.Sound`
- `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Tubset.Motor.Sound`
- `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Wetset.Water.DrainPump`
- `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.MoterSet.FakeMotor.MotorSet.Motor.HighSound`
- `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.MoterSet.FakeMotor.MotorSet.Motor.LowSound`
- `ReplicatedStorage.Maps.StudioMMNineteen.StudioMMNineteen.Living Room.CurvedTV.Model.Screen.Sound`
- `ServerStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Agitation.Motor.Sound`
- `ServerStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Tubset.Motor.Sound`
- `ServerStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.Wetset.Water.DrainPump`
- `ServerStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.MoterSet.FakeMotor.MotorSet.Motor.HighSound`
- `ServerStorage.Maps.HauntedHouse.HauntedHouse.Model.Model.WasherSet.MoterSet.FakeMotor.MotorSet.Motor.LowSound`
- `ServerStorage.Maps.StudioMMNineteen.StudioMMNineteen.Living Room.CurvedTV.Model.Screen.Sound`

Yang perlu owner siapkan:

- [ ] pengganti sound mesin cuci agitation
- [ ] pengganti sound mesin cuci tub/motor
- [ ] pengganti sound drain pump/water
- [ ] pengganti sound motor high/low loop
- [ ] pengganti sound TV/static/room media

Aturan asset audio:

- Upload ulang asset ke akun/group owner experience.
- Pastikan permission asset bisa dipakai experience.
- Setelah asset id baru ada, agent yang mengganti wiring `SoundId` di source/Studio.

## Ghost VFX Dan HUD Checklist

VFX/sensory yang terkait ghost:

- [ ] `SensoryHorrorHUD`
- [ ] `SpectatorUI.StaticFlickerOverlay`
- [ ] `SpectatorUI.ColorDesaturationOverlay`
- [ ] `WorldEffects.WorldHighlightTemplate`
- [ ] `WorldEffects.WorldPointLightTemplate`
- [ ] `WorldEffects.WorldSpotLightTemplate`
- [ ] `WorldEffects.WorldBeamTemplate`
- [ ] `WorldEffects.WorldParticleEmitterTemplate`
- [ ] `WorldEffects.WorldBoxOutlineTemplate`
- [ ] `WorldEffects.WorldFireTemplate`
- [ ] runtime post-process `BlurEffect` / `ColorCorrectionEffect`
- [ ] runtime `ShadowApparitionRuntime`

Kualitas PASS ghost VFX/HUD:

- [ ] Vignette horror terlihat tetapi tidak membuat UI tidak terbaca.
- [ ] Flicker spectator tidak menyakitkan mata.
- [ ] Desaturation/blur tidak membuat player kehilangan orientasi terlalu lama.
- [ ] Highlight ghost tidak terlalu gamey jika targetnya horror.
- [ ] Particle tidak terlalu berat untuk mobile.
- [ ] Beam/light/fire tidak overexposed.
- [ ] Shadow apparition punya bentuk/silhouette jelas.
- [ ] VFX shock punya timing pendek dan kembali normal.

## Fallback Yang Harus Diperhatikan

Fallback bukan target visual final. Fallback hanya pengaman agar game tidak crash jika asset hilang.

- [ ] Jika ghost model final belum valid, runtime bisa memakai placeholder/fallback ghost visual.
- [ ] Jika audio asset kosong/403, sound bisa diam atau di-sanitize oleh guard.
- [ ] Jika VisualTemplate hilang, runtime sekarang harus warn/skip, bukan membuat duplicate legacy.
- [ ] Jika prop event tidak tersedia, event masih boleh berjalan dengan feedback audio/VFX minimal.
- [ ] Fallback tidak boleh menjadi tampilan final release jika owner sudah punya asset final.

## Yang Boleh Owner Sentuh

- `Position`
- `Size`
- `AnchorPoint`
- `BackgroundColor3`
- `BackgroundTransparency`
- `Image`
- `ImageColor3`
- `ImageTransparency`
- `Text`
- `TextColor3`
- `TextTransparency`
- `TextScaled`
- `TextSize`
- `FontFace` atau font Roblox yang tersedia
- `ZIndex`
- `LayoutOrder`
- `Rotation`
- `UICorner.CornerRadius`
- `UIStroke.Color`
- `UIStroke.Thickness`
- `UIStroke.Transparency`
- `UIGradient.Color`
- `UIGradient.Rotation`
- `UIPadding`
- `UIListLayout`
- `UIGridLayout`
- `UIScale`
- `CanvasGroup.GroupTransparency`
- `BillboardGui.Size`
- `BillboardGui.StudsOffset`
- `SurfaceGui.SizingMode` dan ukuran panel visual di dalamnya
- `Highlight.FillColor`
- `Highlight.OutlineColor`
- `PointLight` / `SpotLight` visual properties
- `ParticleEmitter` visual properties jika hanya mengubah tampilan, bukan timing gameplay

## Larangan Owner

- Jangan rename `ScreenGui`, `Frame`, `Button`, template, atau child yang sudah ada.
- Jangan delete object yang belum pasti tidak dipakai.
- Jangan edit script.
- Jangan edit `RemoteEvent`, `RemoteFunction`, `BindableEvent`, atau module logic.
- Jangan edit `ServerScriptService`.
- Jangan edit `StarterPlayerScripts` kecuali diminta agent.
- Jangan edit runtime `PlayerGui` saat Play Test.
- Jangan pindahkan template keluar dari `ReplicatedStorage > Assets > VisualTemplates`.
- Jangan membuat duplicate UI baru dengan nama mirip untuk mengganti UI lama.
- Jangan menyalakan semua `ScreenGui.Enabled=true` sebagai default permanen untuk runtime.
- Jangan mengubah `Name` child contract seperti `Backdrop`, `Panel`, `CloseButton`, `BrandBorder`, `BrandTextImage`, `Vignette`, `ProgressFill`, atau nama template.
- Jangan menghapus `ViewportFrame`, `WorldModel`, atau `Camera` runtime-live content; bagian ini bukan target edit owner langsung.
- Jangan mengubah logic ekonomi, room, match, quest, reward, save data, teleport, dan networking.

## Kualitas Pass Visual

Satu surface dianggap PASS jika memenuhi semua poin ini.

- [ ] Tidak ada text yang sulit dibaca di background gelap/terang.
- [ ] Text punya contrast cukup, terutama tombol, title, subtitle, price, reward, dan status.
- [ ] Button terlihat punya state jelas: idle, hover, active/selected, disabled jika ada.
- [ ] Button tidak terlalu kecil untuk mobile.
- [ ] Panel tidak keluar layar pada 1280x720.
- [ ] Panel tidak terlihat terlalu kecil atau terlalu melebar pada 1920x1080.
- [ ] Panel tidak gepeng pada ultrawide.
- [ ] Tidak ada elemen utama yang saling menimpa.
- [ ] Close/back/leave button mudah ditemukan.
- [ ] Hierarchy visual jelas: title, content, action utama, action sekunder.
- [ ] Glow/VFX tidak menutupi text.
- [ ] Backdrop tidak membuat text hilang.
- [ ] Scroll area tidak membuat layout glitch saat mouse wheel.
- [ ] Cursor keluar-masuk jendela Roblox tidak membuat hover/active state nyangkut.
- [ ] Semua icon final terlihat tajam, tidak blur, tidak salah crop.
- [ ] Semua image text PNG tidak terpotong.
- [ ] Semua currency icon, rarity icon, dan reward icon konsisten.
- [ ] Tidak ada panel yang terbuka bersamaan saat flow normal kecuali memang overlay.
- [ ] Tidak ada object legacy terlihat di belakang panel baru.
- [ ] Di Play Test, panel yang diedit tetap dipanggil runtime sesuai flow game.

## Kualitas Pass Flow Game

Flow dianggap PASS jika semua poin berikut benar dalam Play Test satu client.

- [ ] Masuk game hanya menampilkan lobby/menu yang seharusnya.
- [ ] Room Browser hanya muncul saat dibuka.
- [ ] Create Room window hanya muncul setelah action create room.
- [ ] Join/Leave/Close button bekerja sesuai flow.
- [ ] Shop/RoyalPass/Profile/Leaderboard/Quest tidak terbuka bersamaan tanpa alasan.
- [ ] Match loading tampil saat transisi match.
- [ ] Match HUD tampil saat match.
- [ ] Result summary tampil setelah match selesai.
- [ ] Spectator UI hanya tampil saat mode spectator.
- [ ] Sanity/Horror HUD tidak mengganggu lobby normal.
- [ ] Bottom navbar tidak menutup action utama.
- [ ] Tidak ada error merah di Output terkait UI contract atau missing template.

## Kualitas Pass Multi-Device

Minimal cek manual visual:

- [ ] PC 1920x1080.
- [ ] PC 1280x720.
- [ ] Ultrawide jika tersedia.
- [ ] Mobile portrait jika surface memang dipakai mobile.
- [ ] Mobile landscape jika surface bisa muncul landscape.

PASS multi-device berarti:

- [ ] Semua panel utama tetap berada di layar.
- [ ] Button utama tetap bisa disentuh/diklik.
- [ ] Text utama tetap terbaca.
- [ ] Scroll masih bisa dipakai.
- [ ] Tidak ada UI penting tertutup notch/safe area/mobile controls.
- [ ] Tidak ada panel yang berubah hanya di desktop atau hanya di mobile karena ada duplicate owner berbeda.

## Bagian Yang Sengaja Runtime-Only

Bagian ini bukan gagal migrasi. Ini sengaja tidak dijadikan canvas manual penuh karena isinya data live atau transient.

- `PlayerGui` runtime result saat Play Test.
- Isi live `ViewportFrame`, termasuk `WorldModel` dan `Camera`.
- Preview avatar/tool/player cards yang dirender dari data runtime.
- Runtime sounds.
- Invisible `Part` dan `Attachment` host untuk VFX.
- Prompt dan map/runtime model assembly.
- Post-process `BlurEffect` dan `ColorCorrectionEffect`.
- Spawned enemy/ghost live behavior.
- Match state, room state, save data, reward state, quest state, dan economy state.

## Jika Menemukan Masalah

Catat dengan format ini agar bisa diperbaiki cepat:

- Nama surface:
- Lokasi Explorer:
- Mode saat terlihat: Edit Mode / Play Test
- Device/resolusi:
- Yang salah:
- Yang diharapkan:
- Screenshot/video jika ada:

Contoh:

`RoomBrowserUI > Backdrop > Panel`, Play Test PC 1920x1080, scroll mouse membuat button offset dan text map tidak terbaca.

## Keputusan Akhir

Owner boleh mulai edit visual manual setelah checklist ini dibuat. Agent tetap harus menangani wiring logic, bug runtime, template contract mismatch, Play Test, publish, dan cleanup legacy bila ditemukan.
