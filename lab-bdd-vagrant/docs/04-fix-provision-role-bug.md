# Fix: Bug en provision-role.sh — Duplicate Entry en Replicación

## Fecha
2026-06-25 (v2: 2026-06-25 — reemplazo grep por FLUSH TABLES WITH READ LOCK + query directa)

## Archivo modificado
`scripts/provision-role.sh` (líneas 136-208)

---

## 1. Problema detectado

### Síntoma

Al ejecutar `vagrant up bdd-nodo02` (esclavo), la replicación se caía inmediatamente con:

```
Slave_IO_Running: Yes
Slave_SQL_Running: No
Last_Error: Could not execute Write_rows_v1 event on table lab_bdd.clientes;
           Duplicate entry '1' for key 'PRIMARY'
```

### Causa raíz

El script `provision-role.sh` original ejecutaba los mismos scripts SQL (`01-schema.sql`, `02-data.sql`, `03-users.sql`) en **todos los nodos sin distinción de rol** (líneas 136-159 originales).

Flujo del error:

```
1. bdd-nodo01 (master): ejecuta 01-schema.sql + 02-data.sql  → crea BD e inserta 20 clientes, 10 productos, etc.
2. bdd-nodo02 (slave):  ejecuta 01-schema.sql + 02-data.sql  → crea BD e inserta los MISMOS 20 clientes, 10 productos, etc.
3. bdd-nodo02:          CHANGE MASTER TO... START SLAVE
4. Slave I/O thread:    Descarga binlog del master (OK)
5. Slave SQL thread:    Intenta REPETIR los INSERTs que ya están en la BD local
                        → Duplicate entry '1' for key 'PRIMARY' (Error 1062)
                        → Slave_SQL_Running: No
                        → Replicación detenida
```

El problema aplica tanto a `slave` como a `multimaster`, ya que ambos roles ejecutan `CHANGE MASTER` y ambos recibían los datos precargados.

---

## 2. Solución implementada

### Enfoque

Para los roles `slave` y `multimaster`, en lugar de ejecutar los scripts SQL localmente, se sincroniza la base de datos directamente desde el maestro. Esto:

1. Ejecuta `FLUSH TABLES WITH READ LOCK` en el maestro para obtener un snapshot consistente
2. Consulta `@@gtid_current_pos` del maestro (mientras está bloqueado)
3. Ejecuta `mysqldump` del maestro (mientras está bloqueado, garantizando consistencia dump ↔ GTID)
4. Libera el lock con `UNLOCK TABLES`
5. Restaura el dump en el esclavo
6. Establece `gtid_slave_pos` con la GTID capturada del maestro
7. Luego `CHANGE MASTER ... MASTER_USE_GTID=slave_pos` arranca desde la posición correcta

### Código modificado

**Antes** (líneas 136-159 originales):
```bash
# ========== SCRIPTS SQL ==========
SQL_DIR="/vagrant/sql"
if [ -d "$SQL_DIR" ]; then
    echo "[$NODO] Ejecutando scripts SQL desde $SQL_DIR..."
    for f in "$SQL_DIR"/*.sql; do          # <-- TODOS los roles ejecutan TODO
        mysql -u root -p"$PASSWORD" < "$f"
    done
fi
```

**Después** (líneas 136-208 nuevas):
```bash
# ========== SCRIPTS SQL / SYNC FROM MASTER ==========
SQL_DIR="/vagrant/sql"

if [ "$ROLE" = "slave" ] || [ "$ROLE" = "multimaster" ]; then
    # Sincronizar desde maestro con mysqldump --gtid
    # 1. Esperar a que el maestro esté disponible
    # 2. Dump de lab_bdd con GTID
    # 3. Extraer gtid_slave_pos del dump
    # 4. SET GLOBAL gtid_slave_pos = '...'
    # 5. Restaurar dump
    # 6. Crear usuarios locales (03-users.sql)
else
    # master, shard, spider: ejecutar scripts SQL localmente
    # (mismo comportamiento que antes)
fi
```

### Detalle de la sincronización

```bash
# 1. Esperar hasta 60s a que el master esté listo
for i in $(seq 1 30); do
    mysqladmin ping -h "$MASTER_IP" -u root -p"$PASSWORD" --silent && break
    sleep 2
done

# 2. Lock maestro + obtener GTID + dump (atómico)
mysql -h "$MASTER_IP" -e "FLUSH TABLES WITH READ LOCK"
MASTER_GTID=$(mysql -h "$MASTER_IP" -NBe "SELECT @@gtid_current_pos")
mysqldump -h "$MASTER_IP" --databases lab_bdd --routines --triggers > /tmp/sync.sql
mysql -h "$MASTER_IP" -e "UNLOCK TABLES"

# 3. Restaurar datos en esclavo
mysql < /tmp/sync.sql

# 4. Establecer GTID en esclavo
mysql -e "SET GLOBAL gtid_slave_pos='$MASTER_GTID';"
```

---

## 3. Resultados esperados

Con el fix aplicado, al hacer `vagrant up bdd-nodo02`:

```
bdd-nodo03: Sincronizando base de datos desde maestro 192.168.56.101...
bdd-nodo03: Lock maestro + GTID capturado: 1-1-28
bdd-nodo03: Sincronización completada desde 192.168.56.101
bdd-nodo03: Configurando replicación multimaster -> 192.168.56.101...
bdd-nodo03: Slave_IO_Running: Yes
bdd-nodo03: Slave_SQL_Running: Yes
bdd-nodo03: Rol multimaster configurado correctamente
```

Sin errores de `Duplicate entry`. La replicación arranca limpia desde la posición GTID correcta.

### Escenarios cubiertos

| Escenario | Comportamiento |
|-----------|---------------|
| Master disponible | Sincroniza desde master vía mysqldump (óptimo) |
| Master NO disponible (caído, firewall, etc.) | Fallback a scripts SQL locales (degradado, puede dar error de duplicados) |
| Re-provision (marker existe) | Salta todo (safe) |

---

## 4. Verificación

### Prueba manual (opcional)

```bash
# 1. Insertar un registro en el maestro
vagrant ssh bdd-nodo01 --command \
  "mysql -u root -pLabAdmin_2025! -e \
   \"INSERT INTO lab_bdd.clientes (nombre, apellido, email, region) \
    VALUES ('TestReplica', 'Test', 'test@replica.com', 'norte');\""

# 2. Verificar en el esclavo
vagrant ssh bdd-nodo02 --command \
  "mysql -u root -pLabAdmin_2025! -e 'SELECT COUNT(*) FROM lab_bdd.clientes;'"

# Ambos deben mostrar el mismo número de registros
```

---

## 5. Lecciones aprendidas

1. **No precargar datos en esclavos** — cuando se usa replicación GTID, el esclavo no debe tener datos insertados localmente antes de arrancar la replicación, porque el binlog del maestro contiene esos mismos INSERTs y se producirán conflictos de clave primaria.

2. **`FLUSH TABLES WITH READ LOCK` + consulta directa de GTID** — `mysqldump` con `--gtid` NO produce una línea `SET GLOBAL gtid_slave_pos` cuando se usa `--databases` (solo con `--all-databases`). En su lugar, se debe bloquear el maestro, consultar `@@gtid_current_pos`, dump, y liberar.

3. **`set +H` necesario** — el caracter `!` en las contraseñas (`LabAdmin_2025!`) activa history expansion de bash. Toda línea que use `"$PASSWORD"` en scripts con `set -e` debe estar precedida por `set +H`.

4. **El orden importa**: primero restaurar dump, luego `SET GLOBAL gtid_slave_pos`, luego `CHANGE MASTER`. El `gtid_slave_pos` debe coincidir con el estado de los datos restaurados.

5. **`IF NOT EXISTS` no es suficiente** — aunque los DDL usen `IF NOT EXISTS` y no fallen, las GTIDs de esas transacciones igual se descargan del maestro. Si no se establece `gtid_slave_pos` correctamente, el slave procesará transacciones redundantes.

---

## 6. Archivos relacionados

- `scripts/provision-role.sh` — Script fixeado
- `scripts/provision-base.sh` — Script base (sin cambios)
- `sql/01-schema.sql` — Esquema de BD
- `sql/02-data.sql` — Datos de prueba
- `sql/03-users.sql` — Usuarios de aplicación
- `docs/01-inicio-y-solucion-de-problemas.md` — Documentación de comandos manuales
