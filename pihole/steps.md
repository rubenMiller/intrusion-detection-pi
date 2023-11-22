# SetUp PiHole

## Instalation

```bash
sudo apt update
sudo apt upgrade -y
sudo apt clean
curl -sSL https://install.pi-hole.net | bash
```

Click through the Installtion process.
The Ip of the Pi needs now to be set as the DNS server of the servers it should filter the traffic.

```bash
sudo pihole -a -p
```

This removes the passwort to edit pihole.

```bash
pihole -b -f rwu.de
```

This adds the domain to the blacklist.

```bash
pihole tail
```

Use this to see waht is going on.

## Change nameserver on host

```bash
sudo vim /etc/resolv.conf
```

in this file delete the other entries and add this line:

```bash
nameserver $IP_ADDR_PI
```

This changes the system only temporary.

```bash
sudo vim /etc/systemd/resolved.conf
```

```bash
[Resolve]
DNS=141.69.102.202
FallbackDNS=141.69.102.202
```
