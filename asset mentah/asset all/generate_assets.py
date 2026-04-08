import math
import os
import random
import struct
import wave
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def ensure_dirs():
    dirs = [
        ROOT / "SFX" / "UI",
        ROOT / "SFX" / "HUD",
        ROOT / "SFX" / "Evidence Tools",
        ROOT / "SFX" / "Ghost & Environment",
        ROOT / "SFX" / "Player",
        ROOT / "SFX" / "Music",
        ROOT / "VFX" / "Roblox ParticleEmitter",
        ROOT / "VFX" / "Screen Space",
        ROOT / "VFX" / "World Space",
        ROOT / "VFX" / "Post Processing",
    ]
    for directory in dirs:
        directory.mkdir(parents=True, exist_ok=True)


def clamp(value, lo=-1.0, hi=1.0):
    return max(lo, min(hi, value))


def envelope(t, duration, attack=0.01, release=0.08):
    if t < attack:
        return t / max(attack, 1e-6)
    if t > duration - release:
        return max((duration - t) / max(release, 1e-6), 0.0)
    return 1.0


def sine(freq, t):
    return math.sin(2.0 * math.pi * freq * t)


def saw(freq, t):
    return 2.0 * ((freq * t) % 1.0) - 1.0


def noise(rng):
    return rng.uniform(-1.0, 1.0)


def write_wav(path: Path, duration: float, generator, sample_rate: int = 22050):
    frames = bytearray()
    total = int(duration * sample_rate)
    for i in range(total):
        t = i / sample_rate
        sample = clamp(generator(t))
        frames.extend(struct.pack("<h", int(sample * 32767)))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(bytes(frames))


def write_png(path: Path, width: int, height: int, pixel_fn):
    def chunk(tag: bytes, data: bytes):
        return (
            struct.pack("!I", len(data))
            + tag
            + data
            + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            r, g, b, a = pixel_fn(x, y)
            raw.extend(bytes((r, g, b, a)))

    header = struct.pack("!IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(chunk(b"IHDR", header))
    png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), level=9)))
    png.extend(chunk(b"IEND", b""))
    path.write_bytes(bytes(png))


def json_escape(value: str):
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def write_json(path: Path, content: dict):
    lines = ["{"]
    items = list(content.items())
    for idx, (key, value) in enumerate(items):
        comma = "," if idx < len(items) - 1 else ""
        if isinstance(value, str):
            lines.append(f'  "{key}": "{json_escape(value)}"{comma}')
        elif isinstance(value, bool):
            lines.append(f'  "{key}": {"true" if value else "false"}{comma}')
        elif isinstance(value, (int, float)):
            lines.append(f'  "{key}": {value}{comma}')
        elif isinstance(value, list):
            rendered = ", ".join(
                f'"{json_escape(v)}"' if isinstance(v, str) else str(v) for v in value
            )
            lines.append(f'  "{key}": [{rendered}]{comma}')
        elif isinstance(value, dict):
            lines.append(f'  "{key}": {{{comma}')
            nested = list(value.items())
            for jdx, (n_key, n_value) in enumerate(nested):
                n_comma = "," if jdx < len(nested) - 1 else ""
                if isinstance(n_value, str):
                    lines.append(
                        f'    "{n_key}": "{json_escape(n_value)}"{n_comma}'
                    )
                elif isinstance(n_value, bool):
                    lines.append(
                        f'    "{n_key}": {"true" if n_value else "false"}{n_comma}'
                    )
                else:
                    lines.append(f'    "{n_key}": {n_value}{n_comma}')
            lines.append(f"  }}{comma}")
        else:
            lines.append(f'  "{key}": null{comma}')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_click(seed, freq, duration=0.18, body=0.25):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.003, 0.05)
        tone = 0.6 * sine(freq, t) + 0.25 * sine(freq * 1.8, t)
        transient = 0.35 * noise(rng) * math.exp(-t * 28.0)
        return env * (body * tone + transient)

    return duration, generator


def make_whoosh(seed, base=180.0, duration=0.6, noisy=0.28):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.01, 0.15)
        freq = base + 220.0 * (1.0 - t / duration)
        return env * (0.33 * saw(freq, t) + noisy * noise(rng) * 0.4)

    return duration, generator


def make_bell(seed, freq=880.0, duration=1.1):
    rng = random.Random(seed)

    def generator(t):
        env = math.exp(-t * 2.6)
        tone = sine(freq, t) + 0.4 * sine(freq * 2.01, t) + 0.2 * sine(freq * 3.1, t)
        return 0.28 * env * tone + 0.03 * noise(rng) * env

    return duration, generator


def make_alarm(seed, low=120.0, high=240.0, duration=2.0):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.02, 0.2)
        pulse = 0.5 + 0.5 * math.sin(2 * math.pi * 2.2 * t)
        tone = sine(low, t) + 0.45 * sine(high + 40 * pulse, t)
        return 0.24 * env * pulse * tone + 0.05 * noise(rng) * env

    return duration, generator


def make_breath(seed, pace=1.0, duration=3.0, intensity=0.22):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.05, 0.3)
        cycle = 0.5 + 0.5 * math.sin(2 * math.pi * pace * t - math.pi / 2)
        air = noise(rng) * (0.4 + 0.6 * cycle)
        throat = 0.25 * sine(110 + 15 * cycle, t)
        return env * intensity * (air * 0.7 + throat)

    return duration, generator


def make_beep(seed, freq=720.0, duration=0.35, repeats=2):
    rng = random.Random(seed)

    def generator(t):
        slot = duration / repeats
        local = t % slot
        gate = 1.0 if local < slot * 0.55 else 0.0
        env = envelope(local, slot, 0.01, 0.03)
        return gate * env * (0.32 * sine(freq, t) + 0.02 * noise(rng))

    return duration, generator


def make_static(seed, duration=1.2, intensity=0.22):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.01, 0.08)
        return intensity * env * noise(rng)

    return duration, generator


def make_scratch(seed, duration=1.0):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.01, 0.1)
        chitter = math.sin(2 * math.pi * (60 + 90 * t) * t)
        return env * (0.18 * chitter + 0.22 * noise(rng) * (0.4 + 0.6 * math.sin(30 * t) ** 2))

    return duration, generator


def make_step(seed, material="wood", duration=0.42):
    rng = random.Random(seed)
    base = 105 if material == "wood" else 80

    def generator(t):
        env = envelope(t, duration, 0.002, 0.14)
        thump = math.exp(-t * 16.0) * sine(base, t)
        grit = math.exp(-t * 10.0) * noise(rng) * (0.25 if material == "wood" else 0.18)
        creak = 0.12 * saw(180 + 25 * math.sin(t * 8), t) if material == "wood" else 0.0
        return env * (0.48 * thump + grit + creak)

    return duration, generator


def make_whisper(seed, duration=2.2):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.03, 0.2)
        shape = 0.35 + 0.65 * math.sin(2 * math.pi * 0.8 * t) ** 2
        return env * (0.17 * noise(rng) * shape + 0.04 * sine(250, t))

    return duration, generator


def make_ethereal(seed, duration=2.6, base=320.0):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.08, 0.25)
        sweep = base + 60 * math.sin(2 * math.pi * 0.3 * t)
        tone = sine(sweep, t) + 0.4 * sine(sweep * 0.5, t) + 0.25 * sine(sweep * 1.7, t)
        return env * (0.22 * tone + 0.03 * noise(rng))

    return duration, generator


def make_slam(seed, duration=1.0):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.001, 0.25)
        burst = math.exp(-t * 18.0) * (0.7 * noise(rng) + 0.4 * sine(65, t))
        tail = 0.18 * math.exp(-t * 4.0) * sine(140, t)
        return env * (burst + tail)

    return duration, generator


def make_flicker(seed, duration=1.3):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.005, 0.05)
        gate = 1.0 if int(t * 17) % 3 != 0 else 0.2
        buzz = sine(60, t) + 0.3 * sine(120, t)
        return env * gate * (0.14 * buzz + 0.16 * noise(rng))

    return duration, generator


def make_glass(seed, duration=1.1):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.001, 0.25)
        high = 0.16 * sine(2400, t) + 0.12 * sine(1800, t)
        burst = math.exp(-t * 12.0) * (0.55 * noise(rng) + high)
        return env * burst

    return duration, generator


def make_wind(seed, duration=6.0):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.2, 0.4)
        swell = 0.35 + 0.65 * math.sin(2 * math.pi * 0.12 * t) ** 2
        tone = 0.06 * sine(180 + 30 * math.sin(t * 0.8), t)
        return env * (0.18 * noise(rng) * swell + tone)

    return duration, generator


def make_loop_music(seed, bpm=60, duration=12.0, danger=0.2):
    rng = random.Random(seed)

    def generator(t):
        env = envelope(t, duration, 0.3, 0.5)
        beat = 60.0 / bpm
        pulse = 0.45 + 0.55 * math.sin(2 * math.pi * (1.0 / beat) * t - math.pi / 2)
        drone = 0.12 * sine(55, t) + 0.07 * sine(82.5, t)
        pad = 0.1 * sine(220 + 20 * math.sin(t * 0.17), t)
        hiss = 0.04 * noise(rng) * (0.2 + danger)
        return env * (drone + pad * pulse + hiss + 0.06 * danger * sine(330, t))

    return duration, generator


def category_for_audio(name: str) -> str:
    if name.startswith("ui_"):
        return "UI"
    if name.startswith("sanity_") or name.startswith("stamina_") or name.startswith("objective_") or name.startswith("interact_"):
        return "HUD"
    if (
        name.startswith("tool_")
        or name.startswith("emf_")
        or name.startswith("thermometer_")
        or name.startswith("spirit_box_")
        or name.startswith("ghost_writing_")
        or name.startswith("motion_sensor_")
        or name.startswith("orb_camera_")
    ):
        return "Evidence Tools"
    if name.startswith("player_"):
        return "Player"
    if name.startswith("bgm_"):
        return "Music"
    return "Ghost & Environment"


def build_audio_specs():
    specs = []

    def add(name, desc, required, builder):
        specs.append(
            {
                "name": name,
                "description": desc,
                "required": required,
                "builder": builder,
                "folder": ROOT / "SFX" / category_for_audio(name),
            }
        )

    add("ui_button_hover.wav", "CC0 subtle creak-click hover tick.", "y", make_click(1, 650))
    add("ui_button_press.wav", "CC0 heavier click with short noisy tail.", "y", make_click(2, 420, 0.22, 0.35))
    add("ui_panel_open.wav", "CC0 airy whoosh with paper-like rustle.", "y", make_whoosh(3, 240, 0.7))
    add("ui_panel_close.wav", "CC0 short thud with static decay.", "y", make_slam(4, 0.8))
    add("ui_notification.wav", "CC0 distant bell notification with soft decay.", "y", make_bell(5, 740, 1.4))
    add("ui_rank_up.wav", "CC0 dramatic rising sting for progression.", "n", make_ethereal(6, 1.9, 520))
    add("ui_rank_down.wav", "CC0 descending failure sting with brittle edge.", "n", make_alarm(7, 210, 150, 1.5))
    add("ui_reward_claim.wav", "CC0 coin-like claim sparkle.", "n", make_bell(8, 980, 0.9))
    add("ui_royal_pass_level.wav", "CC0 premium level-up chime with dark undertone.", "n", make_ethereal(9, 2.0, 480))
    add("ui_error.wav", "CC0 static burst error cue.", "y", make_static(10, 0.45, 0.34))
    add("ui_confirm.wav", "CC0 soft confirmation bell.", "y", make_bell(11, 880, 0.7))
    add("ui_toggle.wav", "CC0 compact switch click.", "y", make_click(12, 560, 0.12, 0.2))

    add("sanity_drop_low.wav", "CC0 low heartbeat tension cue for 40 percent sanity.", "y", make_alarm(13, 68, 92, 2.4))
    add("sanity_drop_critical.wav", "CC0 strained breathing cue for critical sanity.", "y", make_breath(14, 0.9, 3.4, 0.3))
    add("sanity_restore.wav", "CC0 calm exhale recovery cue.", "y", make_breath(15, 0.45, 2.2, 0.16))
    add("stamina_depleted.wav", "CC0 sharp gasp for empty stamina.", "y", make_breath(16, 1.8, 1.6, 0.28))
    add("stamina_recover.wav", "CC0 breath recovery loop for stamina return.", "y", make_breath(17, 1.1, 2.0, 0.2))
    add("objective_update.wav", "CC0 typewriter-like ding for new objectives.", "y", make_bell(18, 1040, 0.6))
    add("interact_prompt.wav", "CC0 subtle HUD highlight tone.", "y", make_bell(19, 690, 0.45))

    add("tool_flashlight_on.wav", "CC0 flashlight switch click.", "y", make_click(20, 500, 0.14, 0.24))
    add("tool_flashlight_flicker.wav", "CC0 unstable flashlight buzz and sputter.", "y", make_flicker(21, 1.0))
    add("emf_beep_low.wav", "CC0 low-level EMF detector beep.", "y", make_beep(22, 520, 0.5, 2))
    add("emf_beep_high.wav", "CC0 urgent high-level EMF detector beep.", "y", make_beep(23, 970, 0.6, 3))
    add("thermometer_reading.wav", "CC0 icy crackle for freezing temperature reads.", "y", make_static(24, 1.0, 0.16))
    add("spirit_box_static.wav", "CC0 radio static loop for spirit box idle.", "y", make_static(25, 2.8, 0.18))
    add("spirit_box_response.wav", "CC0 distorted ethereal response cue.", "y", make_ethereal(26, 2.1, 280))
    add("ghost_writing_scratch.wav", "CC0 scratch pattern for ghost writing evidence.", "y", make_scratch(27, 1.6))
    add("motion_sensor_trigger.wav", "CC0 crisp sensor activation ping.", "y", make_beep(28, 820, 0.28, 1))
    add("orb_camera_click.wav", "CC0 compact camera shutter snap.", "y", make_click(29, 390, 0.16, 0.3))

    for idx in range(1, 5):
        add(
            f"ghost_footstep_{idx}.wav",
            f"CC0 ghost footstep variation {idx} with soft transient.",
            "y",
            make_step(30 + idx, "concrete", 0.5),
        )
    for idx in range(1, 4):
        add(
            f"ghost_whisper_{idx}.wav",
            f"CC0 whisper variation {idx} for nearby ghost presence.",
            "y",
            make_whisper(40 + idx, 2.1 + idx * 0.15),
        )
    add("ghost_breathing.wav", "CC0 labored ghost breathing loop.", "y", make_breath(50, 0.7, 3.6, 0.24))
    add("ghost_manifestation.wav", "CC0 ethereal materialization tone.", "y", make_ethereal(51, 2.8, 260))
    add("hunt_start.wav", "CC0 hunt start impact with panic pulse.", "y", make_alarm(52, 80, 140, 2.0))
    add("hunt_chase_loop.wav", "CC0 looping chase ambience with rising pressure.", "y", make_loop_music(53, 104, 10.0, 0.8))
    add("hunt_end.wav", "CC0 de-escalation tone after hunt ends.", "y", make_ethereal(54, 1.8, 200))
    add("door_slam.wav", "CC0 heavy door slam impact.", "y", make_slam(55, 1.0))
    for idx in range(1, 4):
        add(
            f"door_creak_{idx}.wav",
            f"CC0 door creak variation {idx}.",
            "y",
            make_scratch(60 + idx, 1.2 + idx * 0.2),
        )
    add("object_fall.wav", "CC0 object tumble and hit.", "y", make_slam(64, 1.15))
    add("light_flicker.wav", "CC0 electrical flicker and buzz.", "y", make_flicker(65, 1.4))
    add("glass_break.wav", "CC0 brittle glass shatter.", "y", make_glass(66, 1.1))
    for idx in range(1, 4):
        add(
            f"floor_creak_{idx}.wav",
            f"CC0 floor creak variation {idx}.",
            "y",
            make_step(70 + idx, "wood", 0.65),
        )
    add("wind_howl_loop.wav", "CC0 looping wind howl ambience.", "y", make_wind(74, 8.0))

    for idx in range(1, 5):
        add(
            f"player_footstep_wood_{idx}.wav",
            f"CC0 player wood footstep variation {idx}.",
            "y",
            make_step(80 + idx, "wood", 0.42),
        )
    for idx in range(1, 5):
        add(
            f"player_footstep_concrete_{idx}.wav",
            f"CC0 player concrete footstep variation {idx}.",
            "y",
            make_step(90 + idx, "concrete", 0.38),
        )
    add("player_sprint_breath.wav", "CC0 sprint breathing loop.", "y", make_breath(100, 1.5, 3.0, 0.26))
    add("player_hide.wav", "CC0 tense held-breath hide cue.", "y", make_breath(101, 0.25, 2.4, 0.14))
    add("player_death.wav", "CC0 final gasp with fading tail.", "y", make_breath(102, 1.2, 2.0, 0.3))
    add("player_heartbeat_slow.wav", "CC0 slow heartbeat loop.", "y", make_alarm(103, 62, 78, 3.0))
    add("player_heartbeat_fast.wav", "CC0 rapid heartbeat loop.", "y", make_alarm(104, 95, 125, 2.8))

    add("bgm_lobby_ambient.wav", "CC0 looping lobby ambient horror bed.", "y", make_loop_music(110, 56, 12.0, 0.2))
    add("bgm_investigation_calm.wav", "CC0 calm investigation loop with low tension.", "y", make_loop_music(111, 60, 12.0, 0.3))
    add("bgm_investigation_tense.wav", "CC0 medium-tension investigation loop.", "y", make_loop_music(112, 72, 12.0, 0.45))
    add("bgm_investigation_danger.wav", "CC0 high-tension investigation loop.", "y", make_loop_music(113, 84, 12.0, 0.65))
    add("bgm_hunt_chase.wav", "CC0 intense hunt chase loop.", "y", make_loop_music(114, 110, 10.0, 0.9))
    add("bgm_hunt_escape.wav", "CC0 hide-and-escape variation with residual tension.", "n", make_loop_music(115, 88, 10.0, 0.55))
    add("bgm_results_win.wav", "CC0 melancholic victory cue.", "y", make_loop_music(116, 58, 8.0, 0.18))
    add("bgm_results_lose.wav", "CC0 somber defeat cue.", "y", make_loop_music(117, 50, 8.0, 0.25))
    add("bgm_gameover.wav", "CC0 sparse game-over tone bed.", "y", make_loop_music(118, 42, 8.0, 0.12))
    add("bgm_mainmenu.wav", "CC0 atmospheric main menu horror loop.", "y", make_loop_music(119, 54, 12.0, 0.22))

    return specs


def radial_alpha(x, y, width, height, scale=1.0):
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0
    dx = (x - cx) / max(cx, 1.0)
    dy = (y - cy) / max(cy, 1.0)
    dist = math.sqrt(dx * dx + dy * dy)
    return max(0.0, min(1.0, 1.0 - dist * scale))


def build_vfx_specs():
    specs = []

    def add_png(category, name, description, required, pixel_fn, width=256, height=256):
        specs.append(
            {
                "name": f"{name}.png",
                "description": description,
                "required": required,
                "kind": "png",
                "path": ROOT / "VFX" / category / f"{name}.png",
                "pixel_fn": pixel_fn,
                "width": width,
                "height": height,
            }
        )

    def add_json(category, name, description, required, payload):
        specs.append(
            {
                "name": f"{name}.json",
                "description": description,
                "required": required,
                "kind": "json",
                "path": ROOT / "VFX" / category / f"{name}.json",
                "payload": payload,
            }
        )

    def make_soft_particle(seed, tint):
        rng = random.Random(seed)

        def pixel_fn(x, y):
            base = radial_alpha(x, y, 256, 256, 1.5)
            speck = 0.65 + 0.35 * rng.random()
            a = int(255 * (base ** 2.2) * speck)
            return (*tint, a)

        return pixel_fn

    add_png("Roblox ParticleEmitter", "ghost_manifest_particles", "CC0 wispy particle texture for wall emergence.", "y", make_soft_particle(200, (210, 235, 255)))
    add_png("Roblox ParticleEmitter", "ghost_trail_particles", "CC0 smoky trail particle texture for moving ghosts.", "y", make_soft_particle(201, (180, 220, 255)))
    add_png("Roblox ParticleEmitter", "ghost_orb_glow", "CC0 soft orb glow texture.", "y", make_soft_particle(202, (150, 220, 255)))
    add_png("Roblox ParticleEmitter", "ghost_dissipate", "CC0 dissipating mist particle texture.", "y", make_soft_particle(203, (220, 220, 220)))
    add_png("Roblox ParticleEmitter", "evidence_highlight_glow", "CC0 subtle highlight glow texture for evidence spots.", "y", make_soft_particle(204, (255, 244, 180)))
    add_png("Roblox ParticleEmitter", "footprint_energy_trail", "CC0 footprint energy smear texture.", "y", make_soft_particle(205, (140, 210, 255)))
    add_png("Roblox ParticleEmitter", "freezing_breath_vapor", "CC0 cold vapor particle texture.", "y", make_soft_particle(206, (225, 240, 255)))
    add_png("Roblox ParticleEmitter", "dust_disturbed", "CC0 disturbed dust mote particle texture.", "y", make_soft_particle(207, (200, 190, 170)))
    add_png("Roblox ParticleEmitter", "candle_flame", "CC0 candle flame sprite texture.", "y", make_soft_particle(208, (255, 170, 70)))
    add_png("Roblox ParticleEmitter", "blood_seep", "CC0 blood seep particle texture.", "y", make_soft_particle(209, (130, 10, 20)))
    add_png("Roblox ParticleEmitter", "shadow_creep", "CC0 shadow creep particle texture.", "y", make_soft_particle(210, (20, 20, 20)))

    add_json(
        "Screen Space",
        "chromatic_aberration",
        "CC0 screen-space config for RGB split intensity tied to sanity.",
        "y",
        {"type": "screen_effect", "mode": "chromatic_aberration", "intensity": 0.18, "sanityScaled": True},
    )
    add_png(
        "Screen Space",
        "film_grain_overlay",
        "CC0 animated-ready film grain overlay texture.",
        "y",
        lambda x, y: (255, 255, 255, int((random.Random(x * 4099 + y).random() ** 5) * 110)),
    )
    add_png(
        "Screen Space",
        "vignette_fear",
        "CC0 fear vignette overlay texture.",
        "y",
        lambda x, y: (0, 0, 0, int(255 * ((1.0 - radial_alpha(x, y, 256, 256, 0.95)) ** 1.6))),
    )
    add_png(
        "Screen Space",
        "scanline_overlay",
        "CC0 subtle scanline overlay texture.",
        "n",
        lambda x, y: (255, 255, 255, 24 if y % 4 == 0 else 0),
    )
    for idx in range(1, 6):
        add_png(
            "Screen Space",
            f"glitch_frame_{idx}",
            f"CC0 glitch frame overlay {idx}.",
            "y",
            lambda x, y, idx=idx: (
                255,
                max(0, 255 - idx * 20),
                max(0, 255 - idx * 30),
                180 if (x * idx + y * 3) % (17 - idx) < 2 else 0,
            ),
        )
    add_png(
        "Screen Space",
        "blood_splatter_screen",
        "CC0 blood splatter screen overlay.",
        "y",
        lambda x, y: (110, 0, 0, 180 if radial_alpha(x, y, 256, 256, 2.2) < 0.32 and (x * y) % 37 < 8 else 0),
    )
    add_png(
        "Screen Space",
        "fog_of_war",
        "CC0 minimap fog mask texture.",
        "y",
        lambda x, y: (0, 0, 0, 255 if radial_alpha(x, y, 256, 256, 1.3) < 0.2 else 120),
    )
    add_png(
        "Screen Space",
        "rain_on_lens",
        "CC0 rain-on-lens overlay texture for wet maps.",
        "n",
        lambda x, y: (200, 220, 255, 130 if ((x * 13 + y * 7) % 211 == 0 or (x * 5 + y * 11) % 173 == 0) else 0),
    )

    add_json(
        "World Space",
        "room_atmosphere_fog",
        "CC0 room fog preset for ambient haze.", "y",
        {"type": "world_effect", "class": "ParticleEmitter", "density": 0.2, "speed": 0.4, "texture": "dust_disturbed.png"},
    )
    add_json(
        "World Space",
        "ghost_room_cold_mist",
        "CC0 dense cold mist preset for ghost rooms.", "y",
        {"type": "world_effect", "class": "ParticleEmitter", "density": 0.45, "speed": 0.25, "texture": "freezing_breath_vapor.png"},
    )
    add_json(
        "World Space",
        "light_flicker_beam",
        "CC0 beam and point-light flicker preset.", "y",
        {"type": "world_effect", "class": "BeamPointLight", "brightness": 2.5, "flickerHz": 9},
    )
    add_json(
        "World Space",
        "window_moonlight_shaft",
        "CC0 moonlight shaft beam preset.", "y",
        {"type": "world_effect", "class": "Beam", "brightness": 1.1, "color": "180,205,255"},
    )
    add_png(
        "World Space",
        "dust_mote_particles",
        "CC0 ambient dust mote texture.",
        "y",
        make_soft_particle(211, (210, 200, 180)),
    )
    add_png(
        "World Space",
        "blood_pool_decal",
        "CC0 blood pool decal texture.",
        "y",
        lambda x, y: (95, 0, 0, int(255 * max(0.0, radial_alpha(x, y, 256, 256, 1.8) - 0.15))),
    )
    add_png(
        "World Space",
        "scratch_mark_decal",
        "CC0 claw scratch decal texture.",
        "y",
        lambda x, y: (30, 30, 30, 220 if abs((x - 50) - y * 0.35) < 2 or abs((x - 120) - y * 0.3) < 2 or abs((x - 190) - y * 0.32) < 2 else 0),
    )
    add_json(
        "World Space",
        "candle_light_cast",
        "CC0 warm candle PointLight preset.", "y",
        {"type": "world_effect", "class": "PointLight", "brightness": 1.4, "range": 14, "color": "255,188,104"},
    )
    add_json(
        "World Space",
        "flashlight_beam",
        "CC0 flashlight SpotLight preset with shadow casting.", "y",
        {"type": "world_effect", "class": "SpotLight", "brightness": 3.5, "angle": 70, "shadows": True},
    )
    add_json(
        "World Space",
        "ghost_apparition_blur",
        "CC0 highlight-based apparition blur preset.", "y",
        {"type": "world_effect", "class": "Highlight", "fillTransparency": 0.75, "outlineTransparency": 1.0},
    )

    add_json(
        "Post Processing",
        "ColorCorrectionEffect",
        "CC0 desaturated cold color correction preset.", "y",
        {"type": "lighting_effect", "class": "ColorCorrectionEffect", "saturation": -0.2, "tintColor": "185,205,225"},
    )
    add_json(
        "Post Processing",
        "BloomEffect",
        "CC0 subtle bloom preset for ghost-room peaks.", "y",
        {"type": "lighting_effect", "class": "BloomEffect", "intensity": 0.28, "size": 18},
    )
    add_json(
        "Post Processing",
        "BlurEffect",
        "CC0 low-sanity edge blur preset.", "y",
        {"type": "lighting_effect", "class": "BlurEffect", "size": 6, "sanityScaled": True},
    )
    add_json(
        "Post Processing",
        "SunRaysEffect",
        "CC0 disabled sunlight rays preset for horror maps.", "n",
        {"type": "lighting_effect", "class": "SunRaysEffect", "enabled": False},
    )
    add_json(
        "Post Processing",
        "DepthOfFieldEffect",
        "CC0 mild background depth-of-field preset.", "y",
        {"type": "lighting_effect", "class": "DepthOfFieldEffect", "focusDistance": 18, "inFocusRadius": 8},
    )

    return specs


def generate_audio(specs):
    for spec in specs:
        duration, builder = spec["builder"]
        write_wav(spec["folder"] / spec["name"], duration, builder)


def generate_vfx(specs):
    for spec in specs:
        if spec["kind"] == "png":
            write_png(spec["path"], spec["width"], spec["height"], spec["pixel_fn"])
        else:
            write_json(spec["path"], spec["payload"])


def build_manifest(audio_specs, vfx_specs):
    rows = []
    for spec in audio_specs:
        rows.append((spec["name"], spec["description"], spec["required"]))
    for spec in vfx_specs:
        rows.append((spec["name"], spec["description"], spec["required"]))

    header = "|File Name | Description | Required (y/n) |"
    divider = "|---|---|---|"
    lines = [header, divider]
    for name, description, required in rows:
        safe_desc = description.replace("|", "/")
        lines.append(f"|{name} | {safe_desc} | {required} |")
    (ROOT / "asset_finder.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    ensure_dirs()
    audio_specs = build_audio_specs()
    vfx_specs = build_vfx_specs()
    generate_audio(audio_specs)
    generate_vfx(vfx_specs)
    build_manifest(audio_specs, vfx_specs)


if __name__ == "__main__":
    main()
