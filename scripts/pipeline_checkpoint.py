import json, os, pathlib

CHECKPOINT_FILE = "assets/generated/pipeline_checkpoint.json"

def load():
    if pathlib.Path(CHECKPOINT_FILE).exists():
        with open(CHECKPOINT_FILE) as f:
            return json.load(f)
    return {"images_done": [], "images_failed": [], "meshes_done": [], "meshes_failed": []}

def save(state):
    pathlib.Path(CHECKPOINT_FILE).parent.mkdir(parents=True, exist_ok=True)
    with open(CHECKPOINT_FILE, "w") as f:
        json.dump(state, f, indent=2)

def mark_done(state, category, key):
    state[f"{category}_done"].append(key)
    save(state)

def mark_failed(state, category, key, reason):
    state[f"{category}_failed"].append({"key": key, "reason": reason})
    save(state)

def is_done(state, category, key):
    return key in state[f"{category}_done"]
