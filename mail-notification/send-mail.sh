#!/bin/bash

set -e

cp -f /ids/mail/mail-header /ids/mail/mail-text
cat /ids/aide/output-eve.json | python3 /ids/mail/make-table-aide.py >> /ids/mail/mail-text
cat /var/log/suricata/eve.json | python3 /ids/mail/make-table-suricata.py >> /ids/mail/mail-text
ssmtp -t < /ids/mail/mail-text
rm /ids/mail/mail-text