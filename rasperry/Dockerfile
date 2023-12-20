FROM ubuntu:latest
RUN apt-get update && apt-get install -y apt-transport-https
# see here for information https://blog.doubleslash.de/binary-exploitation-erkennen-mit-aide
RUN apt install aide -y

COPY ./aide.conf /etc/aide/aide.conf