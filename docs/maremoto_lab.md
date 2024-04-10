# VirtualBox Lab: Maremoto ~~Réplica Seismo~~

- [VirtualBox Lab: Maremoto ~~Réplica Seismo~~](#virtualbox-lab-maremoto-réplica-seismo)
  - [0. Info hardware y sistemas](#0-info-hardware-y-sistemas)
  - [1. Creación de red NAT en VirtualBox](#1-creación-de-red-nat-en-virtualbox)
  - [2. Configuración de DHCP y DNS en `10_dhcp_dns`](#2-configuración-de-dhcp-y-dns-en-10_dhcp_dns)
  - [3. Despliegue en `20_maremoto` de software tipo SEISMO (ELK Stack, Suricata)](#3-despliegue-en-20_maremoto-de-software-tipo-seismo-elk-stack-suricata)
    - [Uso de Netdiscover](#uso-de-netdiscover)
    - [Configuración y uso de ELK Stack](#configuración-y-uso-de-elk-stack)
    - [Configuración y uso de Suricata](#configuración-y-uso-de-suricata)
  - [4. Clientes potencialmente vulnerables](#4-clientes-potencialmente-vulnerables)
    - [Cliente `4N_ubuntu`](#cliente-4n_ubuntu)
    - [Cliente `4N_win11_pro`](#cliente-4n_win11_pro)
    - [Cliente `4N_win11_home`](#cliente-4n_win11_home)
    - [Cliente `4N_win10_home`](#cliente-4n_win10_home)
    - [Cliente `4N_win10_pro`](#cliente-4n_win10_pro)


## 0. Info hardware y sistemas

Mi sistema operativo anfitrión es Pop!_OS 22.04 LTS, y uso la versión 7.0.10 de VirtualBox. Almacenamos las máquinas virtuales en la partición `k8s-cluster` de 420GB (`/dev/nvme0n1p1`) en mi máquina MSI GL76. Nuestra red local es la 192.168.1.0/24.

En este laboratorio vamos a virtualizar varias máquinas clientes con los sistemas: Windows 11, Windows 10, ~~Windows Server~~ y Ubuntu de cara a familiarizarnos con las tecnologías de SEISMO (ELK Stack, Suricata, etc.).



## 1. Creación de red NAT en VirtualBox

<!-- > https://en.wikipedia.org/wiki/Reserved_IP_addresses -->

- VirtualBox > Tools > Network > NAT Networks > Create > 
  - Name: maremoto
  - IPv4 Prefix: 10.0.20.0/24
  - Enable DHCP: on
  <!-- - Port Forwarding: no -->

<!-- ```bash
# vboxmanage list dhcpservers
``` -->

## 2. Configuración de DHCP y DNS en `10_dhcp_dns`


<details>
<summary>Pasos de Instalación y Configuración en Ubuntu Server</summary>

<br>

> Plantilla: [ASIR/Redes/Entregas/T3.md](https://github.com/pabloqpacin/ASIR/blob/main/Redes/Entregas/T3.md) 

Instalar paquetes necesarios

```bash
sudo apt-get update && sudo apt-get install \
  openvswitch-switch isc-dhcp-server bind9 bind9-utils
```

Asignar dirección IP estática

<!-- Quizá la propia config DHCP/DNS sería suficiente? -->

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

host 20_maremoto {
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



## 3. Despliegue en `20_maremoto` de software tipo SEISMO (ELK Stack, Suricata)

- [scripts/maremoto.sh](scripts/maremoto.sh): instalación de `netdiscover`, Elastic Stack, Suricata...


### Uso de Netdiscover

<details>

```txt
$ sudo netdiscover -r 10.0.20.0/24 -i <enp0sX>

 Currently scanning: Finished!   |   Screen View: Unique Hosts

 10 Captured ARP Req/Rep packets, from 5 hosts.   Total size: 600
 _____________________________________________________________________________
   IP            At MAC Address     Count     Len  MAC Vendor / Hostname
 -----------------------------------------------------------------------------
 10.0.20.1       52:54:00:12:35:00      1      60  Unknown vendor
 10.0.20.2       52:54:00:12:35:00      2     120  Unknown vendor
 10.0.20.10      08:00:27:9c:18:cc      2     120  PCS Systemtechnik GmbH
 10.0.20.40      08:00:27:7a:91:4f      3     180  PCS Systemtechnik GmbH
 10.0.20.41      08:00:27:50:41:8f      2     120  PCS Systemtechnik GmbH
```

NOTAS:
- "no se detecta" el propio equipo que hace el escaneo, no aparece su IP
- cuidado desde `10_dhcp_dns`, aunque se especifique la subred 10.x, solo pilla la 192.x salvo que se indique interfaz de red con `-i`

</details>

### Configuración y uso de ELK Stack
### Configuración y uso de Suricata

## 4. Clientes potencialmente vulnerables

### Cliente `4N_ubuntu`

### Cliente `4N_win11_pro`
### Cliente `4N_win11_home`
### Cliente `4N_win10_home`
### Cliente `4N_win10_pro`


