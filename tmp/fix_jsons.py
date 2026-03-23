import json
import os
import glob

def fix_json_files():
    data_dir = 'assets/data'
    json_files = glob.glob(os.path.join(data_dir, '*.json'))
    
    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            modified = False
            
            # 1. Handle List of Topics or Single Topic
            is_list = isinstance(data, list)
            topics = data if is_list else [data]
            
            for topic_obj in topics:
                # 2. Fix missing Topic-level fields (id, topic, etc.)
                if 'id' not in topic_obj or not topic_obj['id']:
                    # Generate ID from filename if missing
                    base = os.path.basename(file_path).replace('.json', '')
                    topic_obj['id'] = f"{base}-topic-0"
                    modified = True
                
                if 'subject' not in topic_obj or not topic_obj['subject']:
                    # Try to guess subject from filename
                    if 'anatomi' in file_path.lower(): topic_obj['subject'] = 'Anatomi'
                    elif 'micro' in file_path.lower() or 'mikro' in file_path.lower(): topic_obj['subject'] = 'Mikrobiyoloji'
                    elif 'path' in file_path.lower() or 'pato' in file_path.lower(): topic_obj['subject'] = 'Patoloji'
                    modified = True
                
                if 'topic' not in topic_obj or not topic_obj['topic']:
                    topic_obj['topic'] = topic_obj.get('chapter', 'Genel')
                    modified = True

                if 'sub_topic' not in topic_obj or not topic_obj['sub_topic']:
                    topic_obj['sub_topic'] = topic_obj.get('topic', 'Genel')
                    modified = True

                if 'content_summary' not in topic_obj:
                    topic_obj['content_summary'] = ""
                    modified = True

                if 'tus_spots' not in topic_obj:
                    topic_obj['tus_spots'] = []
                    modified = True

                # 3. Fix clinical_cases options (Map to List)
                if 'clinical_cases' in topic_obj and isinstance(topic_obj['clinical_cases'], list):
                    for cc in topic_obj['clinical_cases']:
                        opts = cc.get('options')
                        if isinstance(opts, dict):
                            # Convert {"A": "Choice"} to ["A) Choice"]
                            new_opts = []
                            for k in sorted(opts.keys()):
                                val = str(opts[k])
                                if not val.startswith(f"{k})"):
                                    new_opts.append(f"{k}) {val}")
                                else:
                                    new_opts.append(val)
                            cc['options'] = new_opts
                            modified = True
                            print(f"Fixed options map in {file_path}")

            if modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                print(f"SAVED: {file_path}")
                
        except Exception as e:
            print(f"ERROR processing {file_path}: {e}")

if __name__ == "__main__":
    fix_json_files()
