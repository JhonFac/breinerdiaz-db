# Base de Datos PostgreSQL — Entorno Seguro (`breinerdiaz-db`)

Configuración de **PostgreSQL 16 Alpine** diseñada bajo el principio de **cero exposición pública** a Internet.

---

## 🔒 1. Principio de Seguridad y Prevención de Fugas

> ### ⚠️ ¿Por qué Docker salta el firewall UFW en Linux/VPS?
> Por defecto, cuando defines `ports: - "5432:5432"`, Docker modifica la tabla `iptables` directamente para escuchar en `0.0.0.0` (todas las interfaces, incluyendo tu IP pública). **UFW no puede bloquearlo** y los bots de Internet escanean y atacan puertos como `5432`, `6379` o `9000` en cuestión de minutos.
>
> **Solución aplicada en este Compose:**
> - Enlace forzado a **Loopback Local**: `"127.0.0.1:${DB_LOCAL_PORT:-5434}:5432"`.
> - La base de datos **solo responde a conexiones originadas desde dentro de la misma máquina** o a través de un **túnel SSH**.
> - En producción estricta, si no usas DBeaver, puedes eliminar por completo la sección `ports:`. Los demás contenedores de tu backend se comunican por la red interna `breiner_internal_net` sin requerir ningún puerto expuesto al host.

---

## 🚀 2. Uso Rápido en Local

### Paso 1: Verificar el archivo `.env`
El archivo `.env` ya cuenta con contraseñas seguras generadas. Puedes revisarlo o ajustarlo:
```bash
# Ver configuración actual
type .env
```

### Paso 2: Levantar el contenedor
```bash
docker compose up -d
```

### Paso 3: Verificar estado de salud
```bash
docker compose ps
```
Debe figurar con estado `Up (healthy)`.

### Paso 4: Detener el contenedor
```bash
docker compose down
```
*(Los datos se conservan de forma permanente en el volumen `breinerdiaz_postgres_data`).*

---

## 🐘 3. Conexión con DBeaver o TablePlus

### A. Desde tu máquina local
- **Host:** `127.0.0.1` (o `localhost`)
- **Port:** `5434` *(o el valor configurado en `DB_LOCAL_PORT`)*
- **Database:** `breinerdiaz_db`
- **Username:** `breiner_admin`
- **Password:** *(La definida en tu `.env`)*

---

### B. Desde tu máquina hacia el VPS de Producción (Túnel SSH en DBeaver)
En el VPS, la base de datos **nunca** debe abrirse en el firewall ni en `0.0.0.0`. Te conectas así desde DBeaver:

1. **Pestaña Principal (Main):**
   - **Host:** `127.0.0.1`
   - **Port:** `5434` *(o el puerto local mapeado en la VPS)*
   - **Database:** `breinerdiaz_db`
   - **Username / Password:** Credenciales del `.env` de producción.
2. **Pestaña SSH:**
   - Marca: **"Use SSH Tunnel"**
   - **Host / IP:** La IP pública de tu VPS (Hostinger).
   - **Port:** `22`
   - **User Name:** `deploy` *(o tu usuario SSH)*
   - **Authentication Method:** `Public Key` (tu llave privada SSH) o `Password`.
3. Haz clic en **Test Connection**. DBeaver entrará por el puerto 22 seguro y alcanzará PostgreSQL en `127.0.0.1`.

---

## 🌐 4. Conectar el Backend (`breinerdiaz-api`) a esta Base de Datos

Los contenedores dentro de la misma red de Docker no necesitan puertos mapeados en el host. En el `docker-compose.yml` de tu API, añade la red:

```yaml
services:
  api:
    ...
    environment:
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@breinerdiaz_postgres:5432/${POSTGRES_DB}
    networks:
      - breiner_internal_net

networks:
  breiner_internal_net:
    external: true
```

---

## 💾 5. Respaldos y Restauración

### Crear un Respaldo (Backup rápido):
```bash
docker exec -t breinerdiaz_postgres pg_dump -U breiner_admin -d breinerdiaz_db -F c -b -v -f /backups/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').dump
```

### Restaurar un Respaldo:
```bash
docker exec -i breinerdiaz_postgres pg_restore -U breiner_admin -d breinerdiaz_db -v /backups/tu_archivo.dump
```

---

## 🛡️ 6. Checklist de Seguridad para VPS (Hostinger)

1. [x] **PostgreSQL atado a `127.0.0.1`:** Evita la fuga de UFW.
2. [ ] **Firewall de Hostinger (Panel Web):** Crear reglas de entrada permitiendo únicamente:
   - Puerto `22` (SSH)
   - Puerto `80` (HTTP - Redirección Let's Encrypt / Caddy)
   - Puerto `443` (HTTPS - Tráfico web seguro)
   - Puerto `9443` *(Solo si utilizas Portainer, de lo contrario déjalo cerrado)*
   - **TODO lo demás CERRADO** (0 reglas abiertas para 5432, 5433, 6379, 9000, 9001, etc.).
3. [x] **Archivo `.env` fuera de Git:** Verificado en `.gitignore`.
4. [ ] **Contraseñas únicas y robustas:** Cambiar contraseñas por defecto en producción.
