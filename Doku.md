# Dokumentation

## Einleitung

### Motivation

Unser Ziel war es, ein Gerät zu entwerfen, welches einen oder mehrere Server auf Angriffe untersucht und diese eventuell sogar schon vorbeugt. Das Gerät sollte dabei möglichst einfach einzubauen sein, ohne große Änderungen am bestehenden System vornehmen zu müssen.



## Anforderungen

Im folgenden sind die Anforderungen beschrieben, die wir uns für unser Projekt gesetzt haben

### unabdingliche Anforderungen

#### File Based Intrusion Detection

Ein erfolgreicher Angriff hinterlässt spuren im System. Diese können sehr gut versteckt werden, etwa im Code von bestehenden Anwendungen. Das Tool "aide" kann solche Angriffe jedoch aufdecken. Da dies einen sehr großen Teil von ausgeführten Angriffen erkennen kann, war dies uns sehr wichtig.

#### Network Intrusion Detection

Bevor ein Angriff lokale Dateien verändern kann, muss der Angreifer (meistens) erst über das Netzwerk gehen. Wird der Angriff schon dort erkannt, kann dieser schon schneller verhindert werden, und so etwa der Raub von Daten oder anderem verwendet werden. Aus diesem Grund war es uns sehr wichtig, auch diesen Teil mit unserem Projekt abzudecken.

#### Benachrichtigungen

Wurde ein Angriff entdeckt, sollte gehandelt werden. Was genau zu tun ist, ist oft äußerst komplex und individuell, dazu braucht es einen erfahrenenen Systemadministrator. Damit dieser aber von dem Problem erfährt, ist es wichtig, dass dieser über verdächtige Aktionen benachrichtigt wird.


### optionale Anforderungen

#### Oberflächen

#### PiHole

Viele Website, über die schädliche Handlungen geschehen sind bekannt. Mit PiHole kann verhindert werden, dass der server überhaupt auf diese zugreift. Sei es durch manipulation oder sozial engineering.


## verwendete Technologien

### ssh

ssh bietet eine einfache und sichere Verbindung. Deswegen nutzen wir diese, um Befehle auf den server von unserem Gerät auszuführen.

### Raspberry

Ein raspberry ist klein und weit verbreitet, deswegen bietet er sich sehr gut an, um die Basis für unser Projekt zu sein. Auch Technologien wie PiHole waren darauf einfach umzusetzen.

### File Based Intrusion Detection, aide

Aide kann Veränderungen in Dateien und Ordnern entdecken, die sonst untergehen könnten. Dies geschieht, indem Hashwerte für ausgeählte Ordner (und ihre Inhalte) erstellt werden und in einer Datenbank abgespeichert werden. Zu einem späteren Zeitpunkt kann dann mit dieser verglichen werden und Veränderungen können entdeckt werden.

Da aide diese Änderungen nicht sortiert, ist eine gute Auswahl dieser sehr wichtig. Werden etwa log-files beachtet, wird die Ausgabe sehr schnell zugemüllt. Dateien die sich seltener ändern, wie etwa Programme, sind dafür ideal. Außer nach einem Update sollten dort keine Änderungen auftreten.