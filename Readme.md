# Systemadministration Projekt

Hier sind die Dateien für das Projekt "Systemadministration" enthalten. Sowohl das Projekt an sich, als auch die Dokumentation.

Projektteilnehmher:
 - Bene(dikt?) Geiger
 - Ruben Miller

 
## Grundidee

Überwachung eines Systems durch IDS, die auf einem Raspberry Pi laufen.

### Genauere Skizze

Auf dem Raspberry Pi sollen IDS laufen, die sowohl die disk als auch das Netzwerk überwachen.
Der Raspberry Pi soll dabei von dem überwachten System nicht kontrolliert werden können. Das sollte so sein, da bei einem erfolgreichen Angriff dieser unmöglich verändert werden kann, noch besser wäre, wenn dieser nicht entdeckbar ist.

Der Raspberry Pi soll dann in regelmäßigen Abstanden die Festplatte kontrollieren, bspw ein cronjob mit aide (dabei werden Hashwerte von Dateien erstellt, gespeichert und dann mit neueren Ständen verglichen)
Eine untersuchung des Network funktioniert nur bei laufendem Betrieb, der Raspberry Pi muss also immer angeschlossen sein.
