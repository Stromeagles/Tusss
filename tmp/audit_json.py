import json
import os
import re

REGISTRY_PATH = 'lib/models/subject_registry.dart'
DATA_DIR = 'assets/data'

def audit():
    print("Starting Audit...")
    
    # 1. Read Registry
    if not os.path.exists(REGISTRY_PATH):
        print(f"ERROR: Registry not found at {REGISTRY_PATH}")
        return
        
    with open(REGISTRY_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple regex to extract paths matched in SubjectModule
    registered_paths = re.findall(r"'assets/data/(.*?\.json)'", content)
    registered_paths = [os.path.join(DATA_DIR, p) for p in registered_paths]
    print(f"Found {len(registered_paths)} paths in registry.")

    # 2. Check existence and JSON validity
    broken_files = []
    missing_files = []
    
    for p in registered_paths:
        if not os.path.exists(p):
            missing_files.append(p)
            continue
            
        try:
            with open(p, 'r', encoding='utf-8') as f:
                json.load(f)
        except Exception as e:
            broken_files.append((p, str(e)))

    # 3. Find unregistered files on disk
    files_on_disk = [os.path.join(DATA_DIR, f) for f in os.listdir(DATA_DIR) if f.endswith('.json')]
    unregistered = [f for f in files_on_disk if f.replace('\\', '/') not in [p.replace('\\', '/') for p in registered_paths]]

    # RESULTS
    if missing_files:
        print("\n--- MISSING FILES (Registered but not on disk) ---")
        for m in missing_files: print(m)

    if broken_files:
        print("\n--- BROKEN JSON FILES (Syntax Error) ---")
        for f, err in broken_files: print(f"{f}: {err}")

    if unregistered:
        print("\n--- UNREGISTERED FILES (On disk but not in registry) ---")
        for u in unregistered: print(u)
        
    if not missing_files and not broken_files:
        print("\nSUCCESS: All registered files exist and are valid JSON.")
    else:
        print("\nFAILED: Issues found in data integrity.")

if __name__ == "__main__":
    audit()
