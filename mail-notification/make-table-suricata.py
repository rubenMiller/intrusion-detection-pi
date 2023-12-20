import json
import sys
from tabulate import tabulate
from datetime import datetime, timezone, timedelta


current_time_utc = datetime.utcnow().replace(tzinfo=timezone.utc)
data = []

for line in sys.stdin.readlines():
    data.append(json.loads(line))

print("These are the Alerts of Suricata:\n")

for obj in data:
    if 'event_type' not in obj:
        continue

    if obj['event_type'] != "alert":
        continue
        
        # Does not print files older than 24 h
    timestamp_datetime = datetime.strptime(obj['timestamp'], "%Y-%m-%dT%H:%M:%S.%f%z").replace(tzinfo=timezone.utc)
    time_since_event = current_time_utc - timestamp_datetime
    if time_since_event > timedelta(hours=24):
        continue

    # Convert JSON data to a table
    alertinfo = {}
    alertinfo['timestamp'] = obj['timestamp']
    alertinfo['Interface'] = obj['in_iface']
    alertinfo['Source'] = obj['src_ip'] + ':' + str(obj['src_port'])
    alertinfo['Destination'] = obj['dest_ip'] + ':' + str(obj['dest_port'])
    alertinfo['Protocol'] = obj['proto']
    alertinfo['Action'] = obj['alert']['action']
    alertinfo['Signature'] = obj['alert']['signature']
    alertinfo['Category'] = obj['alert']['category']
    table = tabulate(alertinfo.items(), tablefmt='pipe')
    print(table, "\n")
