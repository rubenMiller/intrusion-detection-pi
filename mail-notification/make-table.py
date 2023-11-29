import json
import sys
from tabulate import tabulate


data = []

for line in sys.stdin.readlines():
    data.append(json.loads(line))

print("These files were changed on your server:\n")

for obj in data:
    if 'event_type' not in obj:
        print("not")
        continue

    if obj['event_type'] != "file_integrity":
        print("ohoho")
        continue

    # Convert JSON data to a table
    fileinfo = obj['file']
    fileinfo['timestamp'] = obj['timestamp']
    table = tabulate(fileinfo.items(),  tablefmt='pipe')
    print(table, "\n")
