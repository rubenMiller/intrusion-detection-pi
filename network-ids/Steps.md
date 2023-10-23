# Steps

Hint: Server will be configured in [install-script](../install-script/Steps.md)

## Installing Suricata

Using a combination of [2. Quickstart guide — Suricata 7.0.3-dev documentation](https://docs.suricata.io/en/latest/quickstart.html), [3. Installation — Suricata 7.0.3-dev documentation](https://docs.suricata.io/en/latest/install.html#debian), [How-To: Installing Suricata in Ubuntu from PPA - YouTube](https://www.youtube.com/watch?v=zBlYESOSqpY&list=PLFqw30a25lWRIhAnQNb7ZaPpexPYgxhVv&index=2) and [Installing & Configuring Suricata - YouTube](https://www.youtube.com/watch?v=UXKbh0jPPpg)

```bash
sudo su -
# Get Distro
cat /etc/*-release

# Replace <distro> with actual distro
echo "deb http://http.debian.net/debian <distro>-backports main" > \
    /etc/apt/sources.list.d/backports.list
apt-get update
apt-get install suricata -t <distro>-backports

# Autostart
systemctl enable suricata

# Optional: Stop while setting up
systemctl stop suricata
exit

# surica-update sets up directories and fetches some default rules
sudo suricata-update
```

## Setting up sources

```bash
sudo suricata-update list-sources
# select wanted sources
# Commercial do need subscription. MIT or open-source are free. Default will be automatically installed
# mine:
# - malsilo/win-malware
# - oisf/trafficid
# - et/open
sudo suricata-update enable-source <name>
sudo suricata-update
```

## Configuring Suricata

```bash
# Optional: Stop while setting up
sudo systemctl stop suricata

# Get interfaces and addresses
ip address show
```

Edit Config `/etc/suricata/suricata.yaml`

(Hint `:set number` shows line-numbers; With `/` can be searched)

Things to change:

- `HOME_NET` should be as specific as possible. In my case, my Pi has only one network. It's IP and SNM is `192.168.178.84/24`, so here all we have is `"[192.168.178.0/24]"`

- `af-packet` specially `- interface` should be your interface. In my case, it's `eth0`

- `pcap` specially `-interface` same as above

- `community-id` should be `true`. For more information, see [17.1.1. Eve JSON Output — Suricata 7.0.3-dev documentation](https://docs.suricata.io/en/latest/output/eve/eve-json-output.html#community-flow-id)

- `default-rule-path` should be `/var/lib/suricata/rules` because `suricata-update` saves rules in there for some reason

- in `rule-files` can be a path, like `/etc/suricata/rules/local.rules` if needed (new point with `-`)

Testing config:

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

## Testing suricata:

1. `sudo cat /var/log/suricata/fast.log` (should be empty)

2. `curl http://testmynids.org/uid/index.html`

3. Command from 1 should now look like this:
   
   ```text
   10/23/2023-18:08:24.838154  [**] [1:2013028:7] ET POLICY curl User-Agent Outbound [**] [Classification: Attempted Information Leak] [Priority: 2] {TCP} 192.168.178.84:44064 -> 18.66.122.21:80
   10/23/2023-18:08:24.853327  [**] [1:2100498:7] GPL ATTACK_RESPONSE id check returned root [**] [Classification: Potentially Bad Traffic] [Priority: 2] {TCP} 18.66.122.21:80 -> 192.168.178.84:44064
   ```

## Iptables

Important, but complicate. We need to forward anything the servers give us, otherwise they wouldn't have internet (which is pretty secure but also destroys the concept of having a server)

The following is from: [Raspberry Pi Firewall and Intrusion Detection System : 14 Steps - Instructables](https://www.instructables.com/Raspberry-Pi-Firewall-and-Intrusion-Detection-Syst/) the scripts are in `./iptables`

Below, you will find a very restrictive firewall script. You may need to modify it to fit your needs as it will block websites not on standards ports (80/443), and softwares not using HTTP/HTTPS/FTP ports (P2P, Skype, Google Talk, etc...).  

If you do not wish that level of security, there's also a more straightforward firewall script that is basically "set and forget".  

You can chose between firewall.advanced or firewall.simple, and then customise it. Credits go to Guillaume Kaddouch  

### A - Advanced ruleset

This script basically does the following :  

- Blocks inbound/outbound invalid TCP flags (even from established flows)  
- Optimises DNS queries (IP TOS field)  
- Identifies traffic by flow type, and then match it against a ruleset  
- Adds randomness to the NAT process  
- Only allow few outbound standard ports (http, https, ftp)  
- Logs accurately what is dropped and avoid log flood  
- Drops inbound packets with low TTL (could mean a ttl expiry attack or a traceroute)  
- Detect & block outbound malware connections  

```bash
$ sudo touch /etc/firewall.advanced
$ sudo touch /etc/firewall.flows
$ sudo chmod u+x /etc/firewall.*
```

The flows identification is a list of rules directing the traffic into the matching custom chain (e.g FORWARD_OUT, FORWARD_IN, LAN_IN, etc...). This list of rules, once debugged and validated, should not be modified afterwards. Also, as they use some space in the script and could be boring to read, it makes the filtering rules harder to read if they are on the same script. That's why I move them in a separate file, that I just call from the main script :  

```bash
$ sudo vi /etc/firewall.flows
```

*File [firewall.flows.sh](./firewall.flows.sh)*

Now we will create the filtering rules script talked earlier :

```bash
$ sudo vi /etc/firewall.advanced
```

*File [firewall.advanced.sh](./firewall.advanced.sh)*

### B - Basic ruleset

This script basically does the following :  

- Blocks inbound/outbound invalid TCP flags (even from established flows)  
- Optimises DNS queries (IP TOS field)  
- Adds randomness to the NAT process  
- Drops inbound packets with low TTL (could mean a ttl expiry attack or a traceroute)

This ruleset allows everything from your LAN to be forwarded on the Internet, thus theoretically not requiring to be modified afterwards. If you want to add an extra layer of network security for your grandmother or parents for instance, but that you cannot expect them to modify iptables rules(!), I think that this ruleset is more appropriate.

```bash
$ sudo vi /etc/firewall.simple
```

*File [firewall.simple.sh](./firewall.simple.sh)*

These two rulesets are just examples, if you have one ready use your own.  

To load iptables rules at startup, one way is to do as follow :

```bash
$ sudo vi /etc/rc.local
echo "Loading iptables rules"
/etc/firewall.VERSION >> /dev/nul
```

Replace VERSION with either "advanced" or "simple", without quotes, depending on the script you are using.

If you want to display alerts in realtime, type the following :

```bash
$ sudo tail -f /var/log/iptables.log
```
