FROM ubuntu:latest
RUN apt-get update && apt-get install -y apt-transport-https
# see here for information https://blog.doubleslash.de/binary-exploitation-erkennen-mit-aide
RUN apt install aide -y

COPY ./aide.conf /etc/aide/aide.conf

RUN aide --config=/etc/aide/aide.conf --init
RUN mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

ENTRYPOINT ["aide", "--config=/etc/aide/aide.conf", "--check"]