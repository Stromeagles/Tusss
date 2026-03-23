import json
import os
import re

REGISTRY_PATH = 'lib/models/subject_registry.dart'
DATA_DIR = 'assets/data'

def strict_audit():
    print("Starting Strict Schema Audit...")
    
    with open(REGISTRY_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    registered_paths = re.findall(r"'assets/data/(.*?\.json)'", content)
    registered_paths = [os.path.join(DATA_DIR, p) for p in registered_paths]

    errors = []
    
    for p in registered_paths:
        if not os.path.exists(p):
            errors.append(f"MISSING FILE: {p}")
            continue
            
        try:
            with open(p, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Data can be a List of Topics or a single Topic
            topics = data if isinstance(data, list) else [data]
            
            for i, topic in enumerate(topics):
                # Check for critical Topic fields
                # Topic expects: id, subject, chapter, topic, sub_topic, content_summary, flashcards, tus_spots, clinical_cases
                for field in ['id', 'subject', 'chapter', 'topic', 'sub_topic']:
                    if field not in topic:
                        errors.append(f"SCHEMA ERROR: {p} [Topic {i}] is missing '{field}'")
                
                # Check Flashcards
                fcs = topic.get('flashcards', [])
                if not isinstance(fcs, list):
                    errors.append(f"SCHEMA ERROR: {p} [Topic {i}] 'flashcards' is not a list")
                else:
                    for j, fc in enumerate(fcs):
                        for field in ['id', 'question', 'answer']:
                            if field not in fc:
                                errors.append(f"SCHEMA ERROR: {p} [Topic {i}, FC {j}] is missing '{field}'")

                # Check Clinical Cases
                ccs = topic.get('clinical_cases', [])
                if not isinstance(ccs, list):
                    errors.append(f"SCHEMA ERROR: {p} [Topic {i}] 'clinical_cases' is not a list")
                else:
                    for j, cc in enumerate(ccs):
                        # Model uses 'case' for text
                        if 'case' not in cc:
                            errors.append(f"SCHEMA ERROR: {p} [Topic {i}, Case {j}] is missing 'case' field")
                        if 'options' not in cc:
                            errors.append(f"SCHEMA ERROR: {p} [Topic {i}, Case {j}] is missing 'options' field")
                        elif not isinstance(cc['options'], list):
                             errors.append(f"SCHEMA ERROR: {p} [Topic {i}, Case {j}] 'options' is not a list")

        except Exception as e:
            errors.append(f"READ ERROR: {p} -> {e}")

    if errors:
        print("\n--- SCHEMA AUDIT FAILED ---")
        for err in errors: print(err)
    else:
        print("\nSUCCESS: All registered files match the expected schema.")

if __name__ == "__main__":
    strict_audit()
