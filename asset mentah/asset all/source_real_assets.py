import json
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path
from urllib.parse import quote

import requests
from bs4 import BeautifulSoup


ROOT = Path(__file__).resolve().parent
HEADERS = {"User-Agent": "Mozilla/5.0"}


def ensure_dirs():
    for rel in [
        "SFX/UI",
        "SFX/HUD",
        "SFX/Evidence Tools",
        "SFX/Ghost & Environment",
        "SFX/Player",
        "SFX/Music",
        "VFX/Roblox ParticleEmitter",
        "VFX/Screen Space",
        "VFX/World Space",
        "VFX/Post Processing",
        "sources/cache",
    ]:
        (ROOT / rel).mkdir(parents=True, exist_ok=True)


def ffmpeg_convert(src: Path, dest: Path, extra_args=None):
    extra_args = extra_args or []
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), *extra_args, str(dest)]
    subprocess.run(cmd, check=True)


def download_file(url: str, dest: Path):
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    with requests.get(url, headers=HEADERS, timeout=60, stream=True) as response:
        response.raise_for_status()
        with dest.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=65536):
                if chunk:
                    handle.write(chunk)
    return dest


def fetch_html(url: str) -> str:
    response = requests.get(url, headers=HEADERS, timeout=60)
    response.raise_for_status()
    return response.text


def parse_freesound_page(url: str):
    html = fetch_html(url)
    soup = BeautifulSoup(html, "html.parser")
    title_meta = soup.find("meta", {"property": "og:title"})
    title = title_meta["content"].strip() if title_meta else url
    title = re.sub(r"\s+by\s+[^|]+$", "", title).strip()
    creator_match = re.search(r"/people/([^/]+)/sounds/", url)
    creator = creator_match.group(1) if creator_match else "unknown"

    license_name = None
    for text in soup.stripped_strings:
        if text in {"Creative Commons 0", "Attribution 4.0"}:
            license_name = text
            break
    if not license_name:
        raise RuntimeError(f"Could not parse license for {url}")

    hq_match = re.search(r"https://cdn\.freesound\.org/previews/[^\"']+-hq\.mp3", html)
    if hq_match:
        preview_url = hq_match.group(0)
    else:
        audio_meta = soup.find("meta", {"property": "og:audio"})
        if not audio_meta:
            raise RuntimeError(f"Could not parse preview for {url}")
        preview_url = audio_meta["content"].replace("https://freesound.orghttps://", "https://")
        preview_url = preview_url.replace("-lq.mp3", "-hq.mp3")

    return {
        "page_url": url,
        "preview_url": preview_url,
        "title": title,
        "creator": creator,
        "license": license_name,
    }


def search_freesound(query: str, index: int = 0):
    for license_name in ["Creative Commons 0", "Attribution 4.0"]:
        url = f"https://freesound.org/search/?q={quote(query)}&f=license:%22{quote(license_name)}%22"
        html = fetch_html(url)
        soup = BeautifulSoup(html, "html.parser")
        seen = []
        for anchor in soup.find_all("a", href=True):
            href = anchor["href"]
            if re.fullmatch(r"/people/[^/]+/sounds/\d+/", href):
                full_url = f"https://freesound.org{href}"
                if full_url not in seen:
                    seen.append(full_url)
        if len(seen) > index:
            return parse_freesound_page(seen[index])
    raise RuntimeError(f"No Freesound result for query={query!r} index={index}")


def source_pack(url: str, zip_name: str, extract_dir: str):
    zip_path = ROOT / "sources" / zip_name
    out_dir = ROOT / "sources" / extract_dir
    download_file(url, zip_path)
    if not out_dir.exists():
        out_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(out_dir)
    return out_dir


def copy_local_audio(source_path: str, dest_rel: str, description: str, required: str, page_url: str, pack_name: str):
    dest = ROOT / dest_rel
    ffmpeg_convert(ROOT / source_path, dest)
    return {
        "file_name": dest.name,
        "description": f"CC0. {description} Source: {pack_name} ({page_url}).",
        "required": required,
    }


def copy_local_image(source_path: str, dest_rel: str, description: str, required: str, source_note: str):
    dest = ROOT / dest_rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / source_path, dest)
    return {
        "file_name": dest.name,
        "description": f"CC0. {description} Source: {source_note}.",
        "required": required,
    }


def write_json_asset(dest_rel: str, payload: dict, description: str, required: str):
    dest = ROOT / dest_rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return {
        "file_name": dest.name,
        "description": f"{description} Roblox-native preset, no external media file required.",
        "required": required,
    }


def freesound_audio(query: str, dest_rel: str, description: str, required: str, index: int = 0, extra_args=None):
    meta = search_freesound(query, index=index)
    cache_name = re.sub(r"[^A-Za-z0-9._-]+", "_", Path(dest_rel).stem) + ".mp3"
    cache_path = ROOT / "sources" / "cache" / cache_name
    download_file(meta["preview_url"], cache_path)
    ffmpeg_convert(cache_path, ROOT / dest_rel, extra_args=extra_args)

    if meta["license"] == "Creative Commons 0":
        manifest_desc = (
            f"CC0. {description} Real sourced audio from Freesound: {meta['title']} by {meta['creator']}."
        )
    else:
        manifest_desc = (
            f"CC BY 4.0 by {meta['creator']}. {description} Source: {meta['page_url']}."
        )
    return {
        "file_name": Path(dest_rel).name,
        "description": manifest_desc,
        "required": required,
    }


def build_audio_manifest():
    rows = []

    def add_local(src, dest, desc, req, url, pack):
        rows.append(copy_local_audio(src, dest, desc, req, url, pack))

    def add_search(query, dest, desc, req, index=0, extra_args=None):
        rows.append(freesound_audio(query, dest, desc, req, index=index, extra_args=extra_args))

    interface_url = "https://kenney.nl/assets/interface-sounds"
    ui_url = "https://kenney.nl/assets/ui-audio"
    impact_url = "https://kenney.nl/assets/impact-sounds"
    rpg_url = "https://kenney.nl/assets/rpg-audio"
    digital_url = "https://kenney.nl/assets/digital-audio"
    jingles_url = "https://kenney.nl/assets/music-jingles"

    add_local("sources/kenney_ui-audio/Audio/rollover3.ogg", "SFX/UI/ui_button_hover.wav", "Soft UI hover rollover.", "y", ui_url, "Kenney UI Audio")
    add_local("sources/kenney_interface-sounds/Audio/click_004.ogg", "SFX/UI/ui_button_press.wav", "Heavier button press click.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_interface-sounds/Audio/open_002.ogg", "SFX/UI/ui_panel_open.wav", "Panel open sweep for menus and journals.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_interface-sounds/Audio/close_003.ogg", "SFX/UI/ui_panel_close.wav", "Panel close thud for UI dismissal.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_interface-sounds/Audio/bong_001.ogg", "SFX/UI/ui_notification.wav", "Short notification bell.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_music-jingles/Audio/Steel jingles/jingles_STEEL11.ogg", "SFX/UI/ui_rank_up.wav", "Progression sting for rank up or unlocks.", "n", jingles_url, "Kenney Music Jingles")
    add_local("sources/kenney_digital-audio/Audio/highDown.ogg", "SFX/UI/ui_rank_down.wav", "Descending fail tone for rank down.", "n", digital_url, "Kenney Digital Audio")
    add_local("sources/kenney_rpg-audio/Audio/handleCoins2.ogg", "SFX/UI/ui_reward_claim.wav", "Coin handling cue for claiming rewards.", "n", rpg_url, "Kenney RPG Audio")
    add_local("sources/kenney_digital-audio/Audio/powerUp12.ogg", "SFX/UI/ui_royal_pass_level.wav", "Premium-style level-up cue.", "n", digital_url, "Kenney Digital Audio")
    add_local("sources/kenney_interface-sounds/Audio/error_006.ogg", "SFX/UI/ui_error.wav", "Static-like UI error burst.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_interface-sounds/Audio/confirmation_002.ogg", "SFX/UI/ui_confirm.wav", "Confirmation bell for accepted actions.", "y", interface_url, "Kenney Interface Sounds")
    add_local("sources/kenney_interface-sounds/Audio/toggle_002.ogg", "SFX/UI/ui_toggle.wav", "Switch toggle for settings.", "y", interface_url, "Kenney Interface Sounds")

    add_search("heartbeat", "SFX/HUD/sanity_drop_low.wav", "Low-sanity heartbeat warning.", "y", 0)
    add_search("labored breathing", "SFX/HUD/sanity_drop_critical.wav", "Critical-sanity strained breathing.", "y", 0)
    add_search("exhale", "SFX/HUD/sanity_restore.wav", "Calm exhale for sanity recovery.", "y", 0)
    add_search("gasp", "SFX/HUD/stamina_depleted.wav", "Gasp for stamina depletion.", "y", 1)
    add_search("deep breathing", "SFX/HUD/stamina_recover.wav", "Breath recovery loop for stamina returning.", "y", 0)
    add_search("typewriter ding", "SFX/HUD/objective_update.wav", "Typewriter-like update cue for objectives.", "y", 0)
    add_local("sources/kenney_interface-sounds/Audio/select_006.ogg", "SFX/HUD/interact_prompt.wav", "Subtle highlight tone for interact prompts.", "y", interface_url, "Kenney Interface Sounds")

    add_local("sources/kenney_ui-audio/Audio/switch11.ogg", "SFX/Evidence Tools/tool_flashlight_on.wav", "Flashlight power switch.", "y", ui_url, "Kenney UI Audio")
    add_search("electric flicker", "SFX/Evidence Tools/tool_flashlight_flicker.wav", "Flickering flashlight electrical instability.", "y", 0)
    add_local("sources/kenney_digital-audio/Audio/tone1.ogg", "SFX/Evidence Tools/emf_beep_low.wav", "Low EMF detector beep.", "y", digital_url, "Kenney Digital Audio")
    add_local("sources/kenney_digital-audio/Audio/highUp.ogg", "SFX/Evidence Tools/emf_beep_high.wav", "High EMF detector alert beep.", "y", digital_url, "Kenney Digital Audio")
    add_search("ice crackle", "SFX/Evidence Tools/thermometer_reading.wav", "Freezing-temperature crackle cue.", "y", 0)
    add_search("radio static", "SFX/Evidence Tools/spirit_box_static.wav", "Radio static bed for spirit box idle.", "y", 0)
    add_search("ghost whisper", "SFX/Evidence Tools/spirit_box_response.wav", "Distorted whisper for spirit box response.", "y", 0)
    add_search("pencil scratch paper", "SFX/Evidence Tools/ghost_writing_scratch.wav", "Writing scratch for ghost-writing evidence.", "y", 0)
    add_search("sensor beep", "SFX/Evidence Tools/motion_sensor_trigger.wav", "Motion sensor activation beep.", "y", 0)
    add_search("camera shutter", "SFX/Evidence Tools/orb_camera_click.wav", "Camera shutter for orb snapshots.", "y", 0)

    add_search("footsteps concrete", "SFX/Ghost & Environment/ghost_footstep_1.wav", "Ghost footstep variation 1; use with reverb in Roblox.", "y", 0)
    add_search("footsteps concrete", "SFX/Ghost & Environment/ghost_footstep_2.wav", "Ghost footstep variation 2; use with reverb in Roblox.", "y", 1)
    add_search("footsteps concrete", "SFX/Ghost & Environment/ghost_footstep_3.wav", "Ghost footstep variation 3; use with reverb in Roblox.", "y", 2)
    add_search("footsteps concrete", "SFX/Ghost & Environment/ghost_footstep_4.wav", "Ghost footstep variation 4; use with reverb in Roblox.", "y", 3)
    add_search("ghost whisper", "SFX/Ghost & Environment/ghost_whisper_1.wav", "Ghost whisper variation 1.", "y", 0)
    add_search("ghost whisper", "SFX/Ghost & Environment/ghost_whisper_2.wav", "Ghost whisper variation 2.", "y", 1)
    add_search("ghost whisper", "SFX/Ghost & Environment/ghost_whisper_3.wav", "Ghost whisper variation 3.", "y", 2)
    add_search("creepy breathing", "SFX/Ghost & Environment/ghost_breathing.wav", "Close ghost breathing loop.", "y", 0)
    add_search("ethereal whoosh", "SFX/Ghost & Environment/ghost_manifestation.wav", "Manifestation swell for ghost appearance.", "y", 1)
    add_search("horror hit", "SFX/Ghost & Environment/hunt_start.wav", "Hunt start impact cue.", "y", 0)
    add_search("horror chase loop", "SFX/Ghost & Environment/hunt_chase_loop.wav", "Looping chase tension bed.", "y", 0)
    add_search("dark ambient loop", "SFX/Ghost & Environment/hunt_end.wav", "Hunt end de-escalation bed.", "y", 1)
    add_search("door slam", "SFX/Ghost & Environment/door_slam.wav", "Heavy door slam.", "y", 0)
    add_search("door creak", "SFX/Ghost & Environment/door_creak_1.wav", "Door creak variation 1.", "y", 0)
    add_search("door creak", "SFX/Ghost & Environment/door_creak_2.wav", "Door creak variation 2.", "y", 1)
    add_search("door creak", "SFX/Ghost & Environment/door_creak_3.wav", "Door creak variation 3.", "y", 2)
    add_local("sources/kenney_impact-sounds/Audio/impactWood_heavy_002.ogg", "SFX/Ghost & Environment/object_fall.wav", "Heavy wood impact for thrown or dropped objects.", "y", impact_url, "Kenney Impact Sounds")
    add_search("electric flicker", "SFX/Ghost & Environment/light_flicker.wav", "Electrical flicker and hum.", "y", 1)
    add_search("glass break", "SFX/Ghost & Environment/glass_break.wav", "Glass break one-shot.", "y", 0)
    add_local("sources/kenney_rpg-audio/Audio/creak1.ogg", "SFX/Ghost & Environment/floor_creak_1.wav", "Wood floor creak variation 1.", "y", rpg_url, "Kenney RPG Audio")
    add_local("sources/kenney_rpg-audio/Audio/creak2.ogg", "SFX/Ghost & Environment/floor_creak_2.wav", "Wood floor creak variation 2.", "y", rpg_url, "Kenney RPG Audio")
    add_local("sources/kenney_rpg-audio/Audio/creak3.ogg", "SFX/Ghost & Environment/floor_creak_3.wav", "Wood floor creak variation 3.", "y", rpg_url, "Kenney RPG Audio")
    add_search("wind howl", "SFX/Ghost & Environment/wind_howl_loop.wav", "Looping wind howl ambience.", "y", 0)

    add_local("sources/kenney_impact-sounds/Audio/footstep_wood_000.ogg", "SFX/Player/player_footstep_wood_1.wav", "Player wood footstep variation 1.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_wood_001.ogg", "SFX/Player/player_footstep_wood_2.wav", "Player wood footstep variation 2.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_wood_002.ogg", "SFX/Player/player_footstep_wood_3.wav", "Player wood footstep variation 3.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_wood_003.ogg", "SFX/Player/player_footstep_wood_4.wav", "Player wood footstep variation 4.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_concrete_000.ogg", "SFX/Player/player_footstep_concrete_1.wav", "Player concrete footstep variation 1.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_concrete_001.ogg", "SFX/Player/player_footstep_concrete_2.wav", "Player concrete footstep variation 2.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_concrete_002.ogg", "SFX/Player/player_footstep_concrete_3.wav", "Player concrete footstep variation 3.", "y", impact_url, "Kenney Impact Sounds")
    add_local("sources/kenney_impact-sounds/Audio/footstep_concrete_003.ogg", "SFX/Player/player_footstep_concrete_4.wav", "Player concrete footstep variation 4.", "y", impact_url, "Kenney Impact Sounds")
    add_search("labored breathing", "SFX/Player/player_sprint_breath.wav", "Heavy sprint breathing loop.", "y", 2)
    add_search("holding breath", "SFX/Player/player_hide.wav", "Breath-hold cue while hiding.", "y", 0)
    add_search("death gasp", "SFX/Player/player_death.wav", "Final breath for player death.", "y", 0)
    add_search("heartbeat", "SFX/Player/player_heartbeat_slow.wav", "Slow heartbeat loop.", "y", 0)
    add_search("heartbeat", "SFX/Player/player_heartbeat_fast.wav", "Fast heartbeat loop.", "y", 0, extra_args=["-filter:a", "atempo=1.35"])

    add_search("menu ambient horror", "SFX/Music/bgm_lobby_ambient.wav", "Lobby ambient loop with distant dread.", "y", 0)
    add_search("horror ambient loop", "SFX/Music/bgm_investigation_calm.wav", "Calm investigation ambience loop.", "y", 0)
    add_search("tense ambient loop", "SFX/Music/bgm_investigation_tense.wav", "Medium-tension investigation loop.", "y", 0)
    add_search("dark ambient loop", "SFX/Music/bgm_investigation_danger.wav", "Danger-state investigation loop.", "y", 0)
    add_search("chase music loop", "SFX/Music/bgm_hunt_chase.wav", "Intense hunt chase loop.", "y", 0)
    add_search("tense ambient loop", "SFX/Music/bgm_hunt_escape.wav", "Escape-and-hide tension variation.", "n", 3)
    add_search("melancholic ambient", "SFX/Music/bgm_results_win.wav", "Melancholic victory results cue.", "y", 0)
    add_search("somber ambient loop", "SFX/Music/bgm_results_lose.wav", "Somber defeat results loop.", "y", 0)
    add_search("single piano note", "SFX/Music/bgm_gameover.wav", "Sparse game-over piano note bed.", "y", 0)
    add_search("menu ambient horror", "SFX/Music/bgm_mainmenu.wav", "Atmospheric horror main menu loop.", "y", 0)

    return rows


def prepare_sources():
    source_pack(
        "https://opengameart.org/sites/default/files/smokeParticleAssets.zip",
        "smokeParticleAssets.zip",
        "smokeParticleAssets",
    )
    source_pack(
        "https://ambientcg.com/get?file=Scratches001_1K-JPG.zip",
        "Scratches001_1K-JPG.zip",
        "Scratches001_1K-JPG",
    )
    download_file("https://opengameart.org/sites/default/files/mudpaint.png", ROOT / "sources" / "mudpaint.png")
    download_file("https://opengameart.org/sites/default/files/bishie_sparkle_1.png", ROOT / "sources" / "bishie_sparkle_1.png")
    download_file("https://opengameart.org/sites/default/files/9_pointed_star.png", ROOT / "sources" / "9_pointed_star.png")
    download_file("https://opengameart.org/sites/default/files/blood_splat.png", ROOT / "sources" / "blood_splat.png")
    download_file("https://opengameart.org/sites/default/files/BloodOverlay.png", ROOT / "sources" / "BloodOverlay.png")


def build_vfx_manifest():
    rows = []
    smoke_src = "sources/smokeParticleAssets/PNG"
    scratches_note = "ambientCG Scratches001 (https://ambientcg.com/view?id=Scratches001)"
    particle_note = "OpenGameArt Particle textures by Starry Skydancer (https://opengameart.org/content/particle-textures)"
    smoke_note = "OpenGameArt Smoke particle assets (https://opengameart.org/content/smoke-particle-assets)"
    blood_note = "OpenGameArt Blood splat by TobiasM (https://opengameart.org/content/blood-splat)"
    blood_overlay_note = "OpenGameArt Blood overlay by 1up Indie (https://opengameart.org/content/blood-overlay)"

    rows.append(copy_local_image(f"{smoke_src}/White puff/whitePuff10.png", "VFX/Roblox ParticleEmitter/ghost_manifest_particles.png", "Soft white smoke puff for ghost manifestation.", "y", smoke_note))
    rows.append(copy_local_image(f"{smoke_src}/Black smoke/blackSmoke09.png", "VFX/Roblox ParticleEmitter/ghost_trail_particles.png", "Dark smoke trail texture for moving ghosts.", "y", smoke_note))
    rows.append(copy_local_image("sources/9_pointed_star.png", "VFX/Roblox ParticleEmitter/ghost_orb_glow.png", "Glow/star particle for ghost orb core.", "y", particle_note))
    rows.append(copy_local_image(f"{smoke_src}/White puff/whitePuff18.png", "VFX/Roblox ParticleEmitter/ghost_dissipate.png", "Dissipating puff texture for ghost exit.", "y", smoke_note))
    rows.append(copy_local_image("sources/bishie_sparkle_1.png", "VFX/Roblox ParticleEmitter/evidence_highlight_glow.png", "Sparkle highlight for evidence locations.", "y", particle_note))
    rows.append(copy_local_image("sources/mudpaint.png", "VFX/Roblox ParticleEmitter/footprint_energy_trail.png", "Smear texture for paranormal footprint trail.", "y", particle_note))
    rows.append(copy_local_image(f"{smoke_src}/White puff/whitePuff06.png", "VFX/Roblox ParticleEmitter/freezing_breath_vapor.png", "Cold vapor particle for freezing breath.", "y", smoke_note))
    rows.append(copy_local_image(f"{smoke_src}/White puff/whitePuff02.png", "VFX/Roblox ParticleEmitter/dust_disturbed.png", "Dust puff texture for disturbed objects.", "y", smoke_note))
    rows.append(copy_local_image(f"{smoke_src}/Flash/flash05.png", "VFX/Roblox ParticleEmitter/candle_flame.png", "Flash/flame sprite for candle flicker.", "y", smoke_note))
    rows.append(copy_local_image("sources/blood_splat.png", "VFX/Roblox ParticleEmitter/blood_seep.png", "Blood seep particle sprite.", "y", blood_note))
    rows.append(copy_local_image(f"{smoke_src}/Black smoke/blackSmoke16.png", "VFX/Roblox ParticleEmitter/shadow_creep.png", "Shadowy smoke texture for corner movement.", "y", smoke_note))

    rows.append(write_json_asset("VFX/Screen Space/chromatic_aberration.json", {"type": "screen_effect", "mode": "chromatic_aberration", "intensity": 0.18, "sanityScaled": True}, "RGB split config that intensifies as sanity drops.", "y"))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Color.jpg", "VFX/Screen Space/film_grain_overlay.jpg", "Real grunge/grain overlay adapted from scratches texture.", "y", scratches_note))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Opacity.jpg", "VFX/Screen Space/vignette_fear.jpg", "Dark imperfect mask suitable for fear vignette overlay.", "y", scratches_note))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001.png", "VFX/Screen Space/scanline_overlay.png", "Imperfection mask usable as subtle scanline/grit overlay.", "n", scratches_note))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Color.jpg", "VFX/Screen Space/glitch_frame_1.jpg", "Real texture frame for glitch overlay variation 1.", "y", scratches_note))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Opacity.jpg", "VFX/Screen Space/glitch_frame_2.jpg", "Real texture frame for glitch overlay variation 2.", "y", scratches_note))
    rows.append(copy_local_image("sources/bishie_sparkle_1.png", "VFX/Screen Space/glitch_frame_3.png", "Sparkle/noise frame for glitch overlay variation 3.", "y", particle_note))
    rows.append(copy_local_image("sources/9_pointed_star.png", "VFX/Screen Space/glitch_frame_4.png", "Star/noise frame for glitch overlay variation 4.", "y", particle_note))
    rows.append(copy_local_image(f"{smoke_src}/Black smoke/blackSmoke03.png", "VFX/Screen Space/glitch_frame_5.png", "Smoke-based frame for glitch overlay variation 5.", "y", smoke_note))
    rows.append(copy_local_image("sources/BloodOverlay.png", "VFX/Screen Space/blood_splatter_screen.png", "First-person blood screen overlay.", "y", blood_overlay_note))
    rows.append(write_json_asset("VFX/Screen Space/fog_of_war.json", {"type": "screen_mask", "mode": "fog_of_war", "defaultAlpha": 1.0, "revealRadius": 0.18}, "Minimap fog-of-war mask config.", "y"))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Opacity.jpg", "VFX/Screen Space/rain_on_lens.jpg", "Imperfection map that can be repurposed as rain-on-lens distortion.", "n", scratches_note))

    rows.append(write_json_asset("VFX/World Space/room_atmosphere_fog.json", {"type": "world_effect", "class": "ParticleEmitter", "texture": "ghost_manifest_particles.png", "rate": 8, "speed": 0.4}, "Room haze preset using real smoke texture.", "y"))
    rows.append(write_json_asset("VFX/World Space/ghost_room_cold_mist.json", {"type": "world_effect", "class": "ParticleEmitter", "texture": "freezing_breath_vapor.png", "rate": 12, "speed": 0.25}, "Dense cold mist preset for ghost room.", "y"))
    rows.append(write_json_asset("VFX/World Space/light_flicker_beam.json", {"type": "world_effect", "class": "BeamPointLight", "brightness": 2.4, "flickerHz": 9}, "Beam and PointLight flicker setup.", "y"))
    rows.append(write_json_asset("VFX/World Space/window_moonlight_shaft.json", {"type": "world_effect", "class": "Beam", "brightness": 1.1, "color": "180,205,255"}, "Moonlight shaft beam preset.", "y"))
    rows.append(copy_local_image(f"{smoke_src}/White puff/whitePuff01.png", "VFX/World Space/dust_mote_particles.png", "Dust mote particle texture.", "y", smoke_note))
    rows.append(copy_local_image("sources/blood_splat.png", "VFX/World Space/blood_pool_decal.png", "Blood decal for floors and event scenes.", "y", blood_note))
    rows.append(copy_local_image("sources/Scratches001_1K-JPG/Scratches001_1K-JPG_Color.jpg", "VFX/World Space/scratch_mark_decal.jpg", "Real scratches texture for claw marks and wall damage.", "y", scratches_note))
    rows.append(write_json_asset("VFX/World Space/candle_light_cast.json", {"type": "world_effect", "class": "PointLight", "brightness": 1.4, "range": 14, "color": "255,188,104"}, "Warm candle PointLight preset.", "y"))
    rows.append(write_json_asset("VFX/World Space/flashlight_beam.json", {"type": "world_effect", "class": "SpotLight", "brightness": 3.5, "angle": 70, "shadows": True}, "Flashlight SpotLight preset with shadows.", "y"))
    rows.append(write_json_asset("VFX/World Space/ghost_apparition_blur.json", {"type": "world_effect", "class": "Highlight", "fillTransparency": 0.75, "outlineTransparency": 1.0}, "Apparition highlight/blur preset.", "y"))

    rows.append(write_json_asset("VFX/Post Processing/ColorCorrectionEffect.json", {"class": "ColorCorrectionEffect", "saturation": -0.2, "tintColor": "185,205,225"}, "Cold desaturated color correction.", "y"))
    rows.append(write_json_asset("VFX/Post Processing/BloomEffect.json", {"class": "BloomEffect", "intensity": 0.28, "size": 18}, "Subtle bloom preset.", "y"))
    rows.append(write_json_asset("VFX/Post Processing/BlurEffect.json", {"class": "BlurEffect", "size": 6, "sanityScaled": True}, "Low-sanity blur preset.", "y"))
    rows.append(write_json_asset("VFX/Post Processing/SunRaysEffect.json", {"class": "SunRaysEffect", "enabled": False}, "Sun rays disabled for horror map lighting.", "n"))
    rows.append(write_json_asset("VFX/Post Processing/DepthOfFieldEffect.json", {"class": "DepthOfFieldEffect", "focusDistance": 18, "inFocusRadius": 8}, "Background depth-of-field preset.", "y"))

    return rows


def write_manifest(rows):
    lines = [
        "|File Name | Description | Required (y/n) |",
        "|---|---|---|",
    ]
    for row in rows:
        desc = row["description"].replace("|", "/")
        lines.append(f"|{row['file_name']} | {desc} | {row['required']} |")
    (ROOT / "asset_finder.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    ensure_dirs()
    prepare_sources()
    rows = build_audio_manifest() + build_vfx_manifest()
    write_manifest(rows)


if __name__ == "__main__":
    main()
