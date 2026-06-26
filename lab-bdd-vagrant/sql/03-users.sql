-- --------------------------------------------------------
-- Usuario: lab_admin
-- Propósito: administración del esquema lab_bdd desde el
--            host Windows vía DBeaver + túnel SSH, y desde
--            scripts de mantenimiento locales.
-- Autenticación: mysql_native_password (necesario para DBeaver)
-- --------------------------------------------------------
-- Acceso local (socket Unix dentro del contenedor)
CREATE USER IF NOT EXISTS 'lab_admin'@'localhost'
  IDENTIFIED BY 'LabAdmin_2025!';
GRANT ALL PRIVILEGES ON lab_bdd.* TO 'lab_admin'@'localhost';
-- Acceso remoto (TCP desde host Windows vía DBeaver u otros contenedores)
CREATE USER IF NOT EXISTS 'lab_admin'@'%'
  IDENTIFIED BY 'LabAdmin_2025!';
GRANT ALL PRIVILEGES ON lab_bdd.* TO 'lab_admin'@'%';
-- --------------------------------------------------------
-- Usuario: app_user
-- Propósito: simular un usuario de aplicación; solo puede
--            leer y escribir datos, nunca modificar el esquema.
-- --------------------------------------------------------
CREATE USER IF NOT EXISTS 'app_user'@'localhost'
  IDENTIFIED BY 'AppUser_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* TO 'app_user'@'localhost';
CREATE USER IF NOT EXISTS 'app_user'@'%'
  IDENTIFIED BY 'AppUser_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* TO 'app_user'@'%';
-- --------------------------------------------------------
-- Usuario: repl_user (replicación)
-- Creado también en init.sh para el rol master; se define
-- aquí por si se ejecuta en modo standalone.
-- --------------------------------------------------------
CREATE USER IF NOT EXISTS 'repl_user'@'%'
  IDENTIFIED BY 'ReplUser_2025!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
-- --------------------------------------------------------
-- Aplicar los cambios de privilegios de inmediato
-- --------------------------------------------------------
FLUSH PRIVILEGES;
-- Verificar que los usuarios quedaron registrados
SELECT User, Host, plugin FROM mysql.user
WHERE User IN ('lab_admin', 'app_user', 'repl_user', 'root')
ORDER BY User;
