# Laboratorio de Bases de Datos Distribuidas — MariaDB

Implementación completa de un laboratorio de **Bases de Datos Distribuidas**
usando MariaDB, automatizado con **Vagrant + VirtualBox** (e idealmente
también **Docker** en `lab-bdd-docker/`).

---

## Stack

| Componente | Tecnología |
|------------|-----------|
| Motor BD | MariaDB 10.x |
| Virtualización | VirtualBox 7.x + Vagrant 2.4+ |
| SO huésped | Ubuntu 24.04 LTS (bento/ubuntu-24.04) |
| Replicación | GTID (`MASTER_USE_GTID=slave_pos`) |
| Sharding | Spider Storage Engine |

---

## Estructura del proyecto

```
Fase/
├── lab-bdd-vagrant/          ← Vagrant + VirtualBox (implementación principal)
│   ├── Vagrantfile           → 6 nodos: master, slave, multimaster, shard A/B, spider
│   ├── scripts/
│   │   ├── provision-base.sh → Instalación MariaDB, charset, usuario bddadmin
│   │   ├── provision-role.sh → Configuración según rol (master/slave/etc.)
│   │   ├── create-bddadmin.sh→ Crear usuario bddadmin en VMs existentes
│   │   ├── exportar-ovas.ps1 → Exportación automatizada a OVA (Windows)
│   │   └── exportar-ovas.sh  → Exportación automatizada a OVA (Linux/Mac)
│   ├── sql/                  → Esquemas, datos de prueba, fixes, tests
│   ├── docs/                 → Documentación del proceso y fixes
│   └── exports/              → OVAs exportados (ignorados por git)
├── lab-bdd-docker/           ← Versión alternativa con Docker Compose
├── markdown/                 → 11 fases documentadas del laboratorio (markdown)
├── pdfs/                     → Versiones PDF del mismo contenido
└── pyproject.toml            → Proyecto Python auxiliar (uv)
```

---

## Requisitos

- **VirtualBox 7.x**
- **Vagrant 2.4+**
- ~10 GB libres en disco
- **Host-Only Network**: `192.168.56.0/24`

---

## Inicio rápido (Vagrant)

```bash
cd lab-bdd-vagrant
vagrant up bdd-nodo01                    # Maestro
vagrant up bdd-nodo02                    # Esclavo (replica de nodo01)
vagrant up bdd-nodo03                    # Multimaster (replica de nodo01)
```

### Credenciales

| Recurso | Usuario | Contraseña |
|---------|---------|-----------|
| SSH (vagrant ssh) | `bddadmin` | `bddadmin` |
| MariaDB root | `root` | `LabAdmin_2025!` |
| Replicación | `repl_user` | `ReplUser_2025!` |

---

## Exportar a OVA (VirtualBox sin Vagrant)

Para llevar las VMs a una computadora que solo tenga VirtualBox:

```bash
# Windows
.\scripts\exportar-ovas.ps1

# Linux/Mac
bash scripts/exportar-ovas.sh
```

Los archivos `.ova` se generan en `exports/` (~780 MB c/u).
Incluyen instrucciones de importación en `exports/IMPORTAR-EN-VIRTUALBOX.md`.

---

## Arquitectura de nodos

| Nodo | IP | Rol | Descripción |
|------|----|-----|-------------|
| bdd-nodo01 | 192.168.56.101 | **Master** | server_id=1, binlog ROW + GTID |
| bdd-nodo02 | 192.168.56.102 | **Slave** | server_id=2, read_only, replica de nodo01 |
| bdd-nodo03 | 192.168.56.103 | **Multimaster** | server_id=3, replica de nodo01, puede escribir |
| bdd-nodo04 | 192.168.56.104 | **Shard A** | server_id=4, región norte/este |
| bdd-nodo05 | 192.168.56.105 | **Shard B** | server_id=5, región sur/oeste |
| bdd-nodo06 | 192.168.56.106 | **Spider** | server_id=6, coordinador de shards |

---

## Documentación

Las 11 fases del laboratorio están documentadas en `markdown/` y `pdfs/`,
cubriendo desde la instalación de VirtualBox hasta la configuración de
Spider y replicación multi-maestro.

Los fixes y cambios realizados durante la implementación están en
`lab-bdd-vagrant/docs/`:

| Documento | Contenido |
|-----------|-----------|
| `01-inicio-y-solucion-de-problemas.md` | Configuración manual inicial y troubleshooting |
| `02-cheatsheet-comandos.md` | Comandos útiles de MariaDB y replicación |
| `03-esquema-bd-y-scripts-sql.md` | Diagrama de BD y scripts |
| `04-fix-provision-role-bug.md` | Bug de sincronización GTID (Duplicate entry) |
| `05-sesion2-bddadmin-y-exportacion.md` | Cambio a bddadmin, fix GTID v2, exportación OVA |

---

## Licencia

Uso académico — Universidad.
