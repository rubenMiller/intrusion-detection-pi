# Systemadministration Projekt

Hier sind die Dateien für das Projekt "Systemadministration" enthalten. Sowohl das Projekt an sich, als auch die Dokumentation.

Projektteilnehmher:

- Benedikt Geiger
- Ruben Miller

## Grundidee

Überwachung eines Systems durch IDS, die auf einem Raspberry Pi laufen.

### Genauere Skizze

Auf dem Raspberry Pi sollen IDS laufen, die sowohl die disk als auch das Netzwerk überwachen.
Der Raspberry Pi soll dabei von dem überwachten System nicht kontrolliert werden können. Das sollte so sein, da bei einem erfolgreichen Angriff dieser unmöglich verändert werden kann, noch besser wäre, wenn dieser nicht entdeckbar ist.

Der Raspberry Pi soll dann in regelmäßigen Abstanden die Festplatte kontrollieren, bspw ein cronjob mit aide (dabei werden Hashwerte von Dateien erstellt, gespeichert und dann mit neueren Ständen verglichen)
Eine untersuchung des Network funktioniert nur bei laufendem Betrieb, der Raspberry Pi muss also immer angeschlossen sein.

# Roadmap

- [ ] Installation Skript
  - [ ] Skript für den Server, welches (wenn nicht vorhanden) ein Zertifikat erstellt, auf dem PI hinterlegt und dem PI alle nötigen Informationen über den Server gibt
- [ ] Netzwerk Traffic scannen
  - [ ] Pihole als erste Instanz (Nicht wirklich zum Scannen geeignet, aber zur Intrusion Protection)
  - [ ] Zum Scannen:
    - [The Zeek Network Security Monitor](https://zeek.org/)
    - [Home - Suricata](https://suricata.io/)
- [ ] Disc Scannen
  - [ ] wird mittels des SSH-Zertifikats vom PI aus gestartet
  - [ ] Server macht die Arbeit
  - [ ] Welche Directories brauchen wir?
  - [ ] Zusätzlich: Virenscann?
  - [ ] von welchen Dateien brauchen wir den Hash um ihn auf dem Pi zu speichern? Können wir eine Vorauswall mittels **zuverlässigem** Timestamp treffen?
  - [ ] Wie verarbeitet der PI die Daten?
    - [ ] Datenbank
    - [ ] Abgleichen mittels eigener Software
- [ ] Angriff gefunden, was dann?
  - [ ] Server runterfahren?
  - [ ] Internet blocken?
  - [ ] Prozess(e) beenden?
  - [ ] Admin benachrichtigen?
    - [ ] Wie?

## Quellen zum Nachlesen

- [Pi-hole as a simple IDS? : r/pihole (reddit.com)](https://www.reddit.com/r/pihole/comments/au0za7/pihole_as_a_simple_ids/)

- [Raspberry Pi 4GB as IDS / IPS ? : r/AskNetsec (reddit.com)](https://www.reddit.com/r/AskNetsec/comments/dcmz1h/raspberry_pi_4gb_as_ids_ips/)

- [Pi-hole – Network-wide Ad Blocking](https://pi-hole.net/)
