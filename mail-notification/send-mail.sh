#!/bin/bash

set -e

cp -f ~/mail-notifications//mail-header ~/mail-notifications/mail-text
cat /ids/aide/output-eve.json | python3 ~/mail-notifications/make-table.py >> ~/mail-notifications/mail-text
ssmtp -t < ~/mail-notifications/mail-text
rm ~/mail-notifications/mail-text