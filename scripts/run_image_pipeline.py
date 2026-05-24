import subprocess, time, json, sys, os
sys.path.insert(0, "scripts")
from pipeline_checkpoint import load, mark_done, mark_failed, is_done

RATE_LIMIT_SLEEP = 8  # detik antar request - aman untuk free tier
RETRY_ON_429_SLEEP = 60  # tunggu 60 detik jika kena 429 sebelum stop

PENDING = []  # diisi dari registry

def load_pending():
    with open("assets/manifest/ASSET_ID_REGISTRY.json") as f:
        registry = json.load(f)
    images = registry.get("images", {})
    return [(k, v) for k, v in images.items()
            if isinstance(v, dict) and v.get("asset_id") in [None, "null", ""] and v.get("status") != "CONFIRMED"]

TYPE_MAP = {
    "border_": "ui", "title_": "ui", "badge_": "ui",
    "royal_": "icon", "outfit_": "reference", "emote_": "reference",
    "season_": "ui"
}

def get_type(key):
    for prefix, t in TYPE_MAP.items():
        if key.startswith(prefix):
            return t
    return "icon"

def run():
    state = load()
    pending = load_pending()
    print(f"Pending images: {len(pending)}")

    for key, meta in pending:
        if is_done(state, "images", key):
            print(f"SKIP (already done): {key}")
            continue

        img_type = get_type(key)
        prompt = f"PASRAHPHOBIA Indonesian horror mystery game {key.replace('_', ' ')} cosmetic asset, dark atmospheric, transparent background, game UI quality"
        out_dir = "assets/generated/images"
        os.makedirs(out_dir, exist_ok=True)

        cmd = [
            "python", "scripts/generate_visual.py",
            "--prompt", prompt,
            "--type", img_type,
            "--name", key,
            "--out-dir", out_dir
        ]

        print(f"Generating: {key} ({img_type})")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

        if result.returncode == 0:
            print(f"  OK: {key}")
            mark_done(state, "images", key)
            time.sleep(RATE_LIMIT_SLEEP)
        elif "429" in result.stderr or "RESOURCE_EXHAUSTED" in result.stderr or "quota" in result.stderr.lower():
            print(f"  429 QUOTA EXHAUSTED at: {key}")
            print(f"  Progress saved. Update GEMINI_API_KEY in .env then rerun.")
            mark_failed(state, "images", key, "429_quota")
            sys.exit(42)  # exit code 42 = quota exhausted
        else:
            print(f"  FAIL: {key} - {result.stderr[:200]}")
            mark_failed(state, "images", key, result.stderr[:200])
            time.sleep(2)

    done_count = len(state["images_done"])
    print(f"\nDone: {done_count}/{len(pending)+done_count} images generated")
    return done_count

if __name__ == "__main__":
    run()
