# Laboratorio Seísmo

## Lab en Virtualbox

```mermaid
    flowchart LR;

subgraph LAN[LAN 192.168.1.0/24]
HOST(HOST Pop!_OS w/ VirtualBox)
end

HOST --. bridge .--- 10_ubuntu_server


subgraph NAT[NAT 10.0.20.0/24]
20_ubuntu[20_ubuntu_seismo]
10_ubuntu_server[10_ubuntu_server - DHCP/DNS] --- 20_ubuntu
10_ubuntu_server[10_ubuntu_server - DHCP/DNS] --- dhcp
subgraph dhcp
4n_ubuntu
4n_windows10
4n_windows11
end
end
```

- [docs/virtualbox_nat.md](/docs/virtualbox_nat.md): creación de red NAT en VirtualBox, instalación de máquinas virtuales, configuración de DHCP y DNS en `21_ubuntu`
<!-- - [docs/lab_seismo.md](/docs/lab_seismo.md): documentación de la administración de herramientas subyacentes a Seísmo (Suricata, Elastic Stack, etc.) en `10_ubuntu` -->


<!-- ## Componentes Seísmo

- [docs/og_seismo.md](/docs/og_seismo.md): info sobre el producto Seísmo de Trevenque, de cara a su correcta administración -->

<!-- - Elastic Stack
- netdiscover
- Suricata -->

