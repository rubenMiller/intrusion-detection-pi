import json
from datetime import datetime
import sys
import hashlib

def convert_aide_to_eve(aide_json):
    eve_events = []
    flow_id_counter = 1  # Startwert für die flow_id

    start_time = aide_json["start_time"]
    aide_version = aide_json["aide_version"]
    end_time = aide_json["end_time"]
    host_ip = aide_json["host_ip"]

    # Iteriere über hinzugefügte Dateien
    for path, attributes in aide_json.get("added", {}).items():
        eve_event = create_eve_event(path, "added", attributes, flow_id_counter, host_ip)
        eve_events.append(eve_event)
        flow_id_counter += 1

    # Iteriere über entfernte Dateien
    for path, attributes in aide_json.get("removed", {}).items():
        eve_event = create_eve_event(path, "removed", attributes, flow_id_counter)
        eve_events.append(eve_event)
        flow_id_counter += 1

    # Iteriere über geänderte Dateien
    for path, attributes in aide_json.get("changed", {}).items():
        eve_event = create_eve_event(path, "changed", attributes, flow_id_counter)
        eve_events.append(eve_event)
        flow_id_counter += 1

    return eve_events

def create_eve_event(path, status, attributes, flow_id, host_ip):
    # Erstelle eine eindeutige community_id mit Hilfe des Dateipfads und der Statusaktion
    community_id = hashlib.md5(f"{path}-{status}".encode()).hexdigest()


    eve_event = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "flow_id": flow_id,
        "event_type": "file_integrity",
        "community_id": community_id,
        "src_ip":host_ip,
        "dest_ip":host_ip,
        "file": {
            "name": path,
            "status": status,
            "attributes": attributes
        }
    }
    return eve_event

def main(aide_json_path, eve_json_path):
    with open(aide_json_path, 'r') as aide_file:
        aide_json = json.load(aide_file)

    # AIDE-JSON in EVE-Format umwandeln
    eve_events = convert_aide_to_eve(aide_json)

    # EVE-Ereignisse in die Ausgabedatei schreiben
    with open(eve_json_path, 'w') as eve_file:
        for event in eve_events:
            eve_file.write(json.dumps(event, separators=(',', ':')) + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Verwendung: python script.py aide.json eve.json")
    else:
        main(sys.argv[1], sys.argv[2])
