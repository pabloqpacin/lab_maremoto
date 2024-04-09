# Laboratorio Seísmo

## Lab en Virtualbox

<details>
<summary>Diseño del Laboratorio</summary>

```mermaid
    flowchart LR;

subgraph LAN[LAN 192.168.1.0/24]
HOST(HOST Pop!_OS w/ VirtualBox)
end

HOST --. bridge .--- 21_ubuntu


subgraph NAT[NAT 10.0.20.0/24]
10_ubuntu[10_ubuntu - SEISMO]
21_ubuntu[21_ubuntu - DHCP/DNS]
22_ubuntu
41_windows11
42_windows10
end
```
</details>

- [docs/virtualbox_nat.md](/docs/virtualbox_nat.md): creación de red NAT en VirtualBox, instalación de máquinas virtuales, configuración de DHCP y DNS en `21_ubuntu`
- [docs/lab_seismo.md](/docs/lab_seismo.md): documentación de la administración de herramientas subyacentes a Seísmo (Suricata, Elastic Stack, etc.) en `10_ubuntu`


## Componentes Seísmo

- [docs/og_seismo.md](/docs/og_seismo.md): info sobre el producto Seísmo de Trevenque, de cara a su correcta administración

<!-- - Elastic Stack
- netdiscover
- Suricata -->

