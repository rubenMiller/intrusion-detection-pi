import json
import sys
from tabulate import tabulate


data = []

for line in sys.stdin.readlines():
    data.append(json.loads(line))

print("These are the Alerts of Suricata:\n")

for obj in data:
    if 'event_type' not in obj:
        continue

    if obj['event_type'] != "alert":
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
