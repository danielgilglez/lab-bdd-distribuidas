## Learned User Preferences

* Prefers interacting and documenting in Spanish.
* Uses `uv` as the Python package and environment manager.
* Prefers using CodeGraph for workspace-wide indexation and code/query intelligence.

## Learned Workspace Facts

* The repository implements a Distributed Database Lab using MariaDB 10.x, automated with Vagrant/VirtualBox (under `lab-bdd-vagrant`) and alternatively with Docker Compose (under `lab-bdd-docker`).
* The architecture consists of 6 database nodes + 1 client-only node with static IPs in the range `192.168.56.101` to `192.168.56.107`: bdd-nodo01 (Master), bdd-nodo02 (Slave), bdd-nodo03 (Multimaster), bdd-nodo04 (Shard A), bdd-nodo05 (Shard B), bdd-nodo06 (Spider coordinator), and bdd-nodo07 (bdd-cliente, client-only with `mariadb-client`).
* **Nuance on Replication**: While the original laboratory guide (`markdown/Fase 11`) describes configuring a synchronous **MariaDB Galera Cluster** for `bdd-nodo01`, `bdd-nodo02`, and `bdd-nodo03`, the automated Vagrant and Docker implementations simplify this by using standard asynchronous/semi-synchronous replication with GTID (`MASTER_USE_GTID=slave_pos`) to reduce system overhead and simplify automation.
* Includes a Python script (`main.py`) powered by `uv` and `MarkItDown` to convert PDF-based laboratory phases into Markdown.
* Converted Markdown files and the combined `FASE_COMPLETA.md` reside in the `markdown/` folder.
* The Vagrant VMs are configured with the `bddadmin` user and default credentials for MariaDB root and replication users.
* Root MariaDB password: `LabAdmin_2025!`; Replication user: `repl_user` / `ReplUser_2025!`
* SSH user in Vagrantfile is now hardcoded to `"vagrant"` (dynamic detection was buggy)
* `vb.gui = false` globally in Vagrantfile to avoid slow boot SSH timeouts
* `mariadb-plugin-spider` package installed separately via `provision-role.sh` for the spider role
* Spider uses `CREATE SERVER` + `srv "name"` syntax (not inline host/port/user/password in COMMENT)
* Partitioned Spider tables require PK to include partition column; UNIQUE constraints must be replaced with INDEX
* Shard provisioning skips `02-data.sql`; uses `04-data-shard-a.sql` / `04-data-shard-b.sql` per node
* Demo/fix/test SQL scripts are skipped for non-master roles (provision-role.sh filtering)
* All 6 VMs (bdd-nodo01 through bdd-nodo06) exist and are currently provisioned and running
* See `docs/08-spider-setup.md` for Spider architecture and troubleshooting

## Resumen de Fases 12–16

* **Fase 12 — Particionamiento de Tablas en MariaDB**: Crea el esquema `lab_particiones` con los 4 tipos de particionamiento nativo (RANGE, LIST, HASH, KEY) en `bdd-nodo01`. Sienta la base conceptual de la fragmentación distribuida. Incluye poda de particiones, mantenimiento y auditoría vía `INFORMATION_SCHEMA.PARTITIONS`.
* **⚠️ ENUM vs VARCHAR en particionamiento**: MariaDB NO permite columnas `ENUM` como clave de particionamiento en `LIST COLUMNS` ni `RANGE COLUMNS` (error 1659). Todas las columnas usadas como partitioning key deben ser `VARCHAR`, `CHAR`, `DATE`, `DATETIME` o enteros. **No uses `ENUM` para columnas de particionamiento; reemplázalas siempre por `VARCHAR`.**

* **Fase 13 — Fragmentación Horizontal**: Crea `bdd-nodo04` (Shard A: Norte/Este) y `bdd-nodo05` (Shard B: Sur/Oeste) como clones enlazados. Distribuye `clientes`, `pedidos` y `detalle_pedidos` por región usando `mysqldump --where`. Verifica completitud, disjunción y reconstrucción vía `UNION ALL`.

* **Fase 14 — Fragmentación Vertical**: Distribuye `productos` verticalmente entre `nodo04` (columnas básicas) y `nodo05` (columnas de detalle). Provisiona `bdd-nodo06` con Spider como coordinador. Registra nodos remotos con `CREATE SERVER` y crea tablas Spider particionadas por `LIST COLUMNS (region)` con poda automática.

* **Fase 15 — Fragmentación Híbrida**: Optimiza consultas distribuidas con índices compuestos, empuje de predicados (predicate pushdown) y proyección de columnas. Crea la vista `reporte_pedidos_detallado` y el procedimiento `consulta_regional()` que encapsulan la distribución. Demuestra transparencia completa ante el cliente final.

* **Fase 16 — Consultas Distribuidas**: Formaliza el algoritmo de 4 fases (descomposición, localización, optimización global, ejecución). Implementa semijoin distribuida (Bernstein-Chiu). Crea `analizar_consulta()` que estima plan de descomposición. Provisiona `bdd-nodo07` como estación cliente ligera que prueba la transparencia total.
