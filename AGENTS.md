## Learned User Preferences

* Prefers interacting and documenting in Spanish.
* Uses `uv` as the Python package and environment manager.
* Prefers using CodeGraph for workspace-wide indexation and code/query intelligence.

## Learned Workspace Facts

* The repository implements a Distributed Database Lab using MariaDB 10.x, automated with Vagrant/VirtualBox (under `lab-bdd-vagrant`) and alternatively with Docker Compose (under `lab-bdd-docker`).
* The architecture consists of 6 distinct database nodes with static IPs in the range `192.168.56.101` to `192.168.56.106`: bdd-nodo01 (Master), bdd-nodo02 (Slave), bdd-nodo03 (Multimaster), bdd-nodo04 (Shard A), bdd-nodo05 (Shard B), and bdd-nodo06 (Spider coordinator).
* **Nuance on Replication**: While the original laboratory guide (`markdown/Fase 11`) describes configuring a synchronous **MariaDB Galera Cluster** for `bdd-nodo01`, `bdd-nodo02`, and `bdd-nodo03`, the automated Vagrant and Docker implementations simplify this by using standard asynchronous/semi-synchronous replication with GTID (`MASTER_USE_GTID=slave_pos`) to reduce system overhead and simplify automation.
* Includes a Python script (`main.py`) powered by `uv` and `MarkItDown` to convert 13 PDF-based laboratory phases into Markdown.
* Converted Markdown files and the combined `FASE_COMPLETA.md` reside in the `markdown/` folder.
* The Vagrant VMs are configured with the `bddadmin` user and default credentials for MariaDB root and replication users.
