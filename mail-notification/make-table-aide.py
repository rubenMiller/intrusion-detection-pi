import json
import sys
from tabulate import tabulate
from datetime import datetime, timezone, timedelta


current_time_utc = datetime.utcnow().replace(tzinfo=timezone.utc)
data = []

for line in sys.stdin.readlines():
    data.append(json.loads(line))

print("These files were changed in the last 24h on your server:\n")

for obj in data:
    
    if 'event_type' not in obj:
        continue

    if obj['event_type'] != "file_integrity":
        continue

    # Does not print files older than 24 h
    timestamp_datetime = datetime.strptime(obj['timestamp'], "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc)
    time_since_event = current_time_utc - timestamp_datetime
    if time_since_event > timedelta(hours=24):
        continue

    # Convert JSON data to a table
    fileinfo = obj['file']
    fileinfo['timestamp'] = obj['timestamp']
    table = tabulate(fileinfo.items(),  tablefmt='pipe')
    print(table, "\n")
