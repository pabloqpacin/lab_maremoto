# Replica Seismo - Lab Pablo

- [Replica Seismo - Lab Pablo](#replica-seismo---lab-pablo)
  - [Hardware](#hardware)
  - [Red NAT en VirtualBox](#red-nat-en-virtualbox)
    - [`10_ubuntu_server` DHCP/DNS server (no GUI)](#10_ubuntu_server-dhcpdns-server-no-gui)
    - [`20_ubuntu_seismo` Réplica Seísmo](#20_ubuntu_seismo-réplica-seísmo)
    - [`4n_ubuntu` cliente (DHCP)](#4n_ubuntu-cliente-dhcp)
    - [`4n_windows_11` cliente](#4n_windows_11-cliente)
    - [`4n_windows_10` cliente](#4n_windows_10-cliente)


## Hardware

Partición `k8s-cluster` de 420GB (`/dev/nvme0n1p1`) en mi máquina MSI GL76 bajo el sistema operativo Pop!_OS 22.04 LTS en la LAN 192.168.1.0/24

---

## Red NAT en VirtualBox

<!-- > https://en.wikipedia.org/wiki/Reserved_IP_addresses -->

- VirtualBox > Tools > Network > NAT Networks > Create > 
  - Name: maremoto
  - IPv4 Prefix: 10.0.20.0/24
  - Enable DHCP: on
  <!-- - Port Forwarding: no -->

<!-- ```bash
# vboxmanage list dhcpservers
``` -->


### `10_ubuntu_server` DHCP/DNS server (no GUI)

<details>
<summary> DHCP/DNS</summary>

> Plantilla: [ASIR/Redes/Entregas/T3.md](https://github.com/pabloqpacin/ASIR/blob/main/Redes/Entregas/T3.md) 

Instalar paquetes necesarios

```bash
sudo apt-get update && sudo apt-get install \
  openvswitch-switch isc-dhcp-server bind9 bind9-utils
```

Asignar dirección IP estática

```bash
sudo mv /etc/netplan/00-installer-config.yaml{,.bak}

cat<<EOF | sudo tee /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    # Bridged Network (LAN)
    enp0s3:
      dhcp4: true
    # NAT Network
    enp0s8:
      dhcp4: false
      addresses: [10.0.20.10/24]
      nameservers:
        addresses: [10.0.20.10]
  version: 2
EOF

sudo netplan try
```

Definir interfaz para servicio DHCP

```bash
sudo sed -i 's/INTERFACESv4=.*/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server
```

Configuración servicio DHCP

```bash
sudo cp /etc/dhcp/dhcpd.conf{,.bak}

sudo sed -i 's/^option domain-name "example.org";/option domain-name "maremoto.net";/' /etc/dhcp/dhcpd.conf
sudo sed -i 's/^option domain-name-servers .*/option domain-name-servers ns.maremoto.net;/' /etc/dhcp/dhcpd.conf
sudo sed -i '/#authoritative;/s/^#//' /etc/dhcp/dhcpd.conf

cat<<EOF | sudo tee -a /etc/dhcp/dhcpd.conf

subnet 10.0.20.0 netmask 255.255.255.0 {
  range 10.0.20.40 10.0.20.199;
  option subnet-mask 255.255.255.0;
  option routers 10.0.20.1;
  option domain-name-servers 10.0.20.10;
  option domain-name "maremoto.net";
}

host 20_ubuntu_seismo {
  hardware ethernet 08:00:27:e7:c3:d9;
  fixed-address 10.0.20.20;
}

EOF
```

Configuración servicio DNS

```bash
cat<<EOF | sudo tee -a /etc/bind/named.conf.local

// Resolución Directa
zone "maremoto.net" {
        type master;
        file "/etc/bind/db.maremoto.net";
};

// Resolución Inversa
zone "2.0.10.in-addr.arpa" {
       type master;
       file "/etc/bind/db.10";
};

EOF
```
```bash
# Zona Directa
cat<<EOF | sudo tee /etc/bind/db.maremoto.net

\$TTL    604800
@       IN      SOA     maremoto.net.   root.maremoto.net. (
                              2        ; Serial
                         604800        ; Refresh
                          86400        ; Retry
                        2419200        ; Expire
                         604800 )      ; Negative Cache TTL
;     
@       IN      NS        maremoto.net.
@       IN      A         10.0.20.10
@       IN      AAAA      ::1

ns      IN      A         10.0.20.10
seismo  IN      A         10.0.20.20

EOF
```
```bash
# Zona Inversa
cat<<EOF | sudo tee /etc/bind/db.10

\$TTL    604800
@       IN      SOA  maremoto.net.     root.maremoto.net. (
                          1          ; Serial
                     604800          ; Refresh
                      86400          ; Retry
                    2419200          ; Expire
                     604800 )        ; Negative Cache TTL
;

@       IN     NS      maremoto.net.

10      IN     PTR     ns.maremoto.net.
20      IN     PTR     seismo.maremoto.net.

EOF
```

```bash
# Verificar sintaxis configuración
named-checkconf
named-checkzone maremoto.net /etc/bind/db.maremoto.net
named-checkzone 2.0.10.in-addr.arpa. /etc/bind/db.10
```


Aplicar configuración

```bash
sudo systemctl restart isc-dhcp-server named
```

</details>



### `20_ubuntu_seismo` Réplica Seísmo

<!-- - [scripts/install_stack.sh](scripts/install_stack.sh): instalación de `netdiscover`, Elastic Stack, Suricata... -->

```bash
sudo apt install \
  netdiscover
```


### `4n_ubuntu` cliente (DHCP)


### `4n_windows_11` cliente

Windows 11 Pro ES (compil. X)


### `4n_windows_10` cliente

  TODO