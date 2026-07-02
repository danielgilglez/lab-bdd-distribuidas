# Laboratorio de Particionamiento Nativo en MariaDB

**Fecha:** 2026-07-01
**Nodos involucrados:** bdd-nodo01 (maestro), bdd-nodo02 (esclavo), bdd-nodo03 (multimaster)

---

## Resumen

Se demostraron las capacidades de particionamiento nativo de MariaDB:
`PARTITION BY LIST COLUMNS` (4 y 2 particiones) y `PARTITION BY RANGE`
por año. Todas las tablas se crearon en el maestro (`bdd-nodo01`) y se
replicaron vía GTID a los esclavos (`bdd-nodo02`, `bdd-nodo03`).

---

## Esquemas creados

### Base `lab_particiones`

| Tabla | Tipo de partición | Particiones | Filas |
|-------|-------------------|-------------|-------|
| `clientes_list4` | LIST COLUMNS (region) | 4 (norte, sur, este, oeste) | 8 |
| `clientes_list2` | LIST COLUMNS (region) | 2 (frag_A, frag_B) | 4 |
| `pedidos` | LIST COLUMNS (region) | 2 (frag_A, frag_B) | 20 |
| `pedidos_rangos` | RANGE (YEAR) | 5 (p_anterior, p_2024..p_2026, p_futuro) | 20 |

### Base `lab_bdd`

| Tabla | Tipo de partición | Particiones | Filas |
|-------|-------------------|-------------|-------|
| `pedidos_part` | LIST COLUMNS (region) | 2 (p_norte_este, p_sur_oeste) | 20 |
| `pedidos_estado` | LIST COLUMNS (estado) | 2 (p_activos, p_finalizados) | 20 |

---

## Conceptos demostrados

- **Fragmentación horizontal por región:** `clientes_list4` (1 región/partición)
  y `clientes_list2` (2 regiones/partición, equivalente a shards).
- **Fragmentación por estado:** `pedidos_estado` agrupa pedidos activos
  vs finalizados.
- **Fragmentación por rango temporal:** `pedidos_rangos` particiona por
  año de `fecha_pedido`.
- **Replicación de tablas particionadas:** GTID replica estructura de
  particiones y datos de forma transparente.
- **Consulta de particiones individuales:** Con `PARTITION (nombre)`.

---

## Archivos

- `sql/05-particionamiento.sql` — Script de creación e inserción de datos
- `sql/check-partitions.sql` — Script de verificación de datos
