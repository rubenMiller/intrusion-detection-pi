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

## Traffic forwarding

That the clients have internet, the Raspberry needs to be configurated to forward the Traffic.

1. Install IPTables:
   
   ```bash
   sudo apt instal iptables
   ```

2. **Accept incoming Connections**:  Make sure, that incoming connections for already made connections and for local access to the Raspberry are accepted. Usually, this is already configurated. To test use `iptables -L INPUT`

3. **Activate forwarding**: To use the Raspberry as Gateway, we need to activate IP-Forwarding:
   
   Edit `/etc/sysctl.conf`
   
   Search for `#net.ipv4.ip_forward=1` and uncomment it
   
   Save

4. Apply changes: 
   
   ```bash
   sudo sysctl -p /etc/sysctl.conf
   ```

5. **NAT-Konfiguration (Network Address Translation)**: Add a NAT-Rule in IPTABLES, to route outgoing connections over the pi.
   
   ```bash
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   ```
   
   *Hint: Make sure `eth0` is the correct Networkinterface*

6. **Firewall Rules for Suricata**: Be sure to create IPTables rules for Suricata to monitor and/or block traffic from your internal network. These rules should be included in your existing IPTables rules configuration. You can add specific rules for Suricata in the FORWARD chain.
