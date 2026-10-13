# Upgrading AssetSecure

## 6.x → 8.x (in-place)

AssetSecure 8.x moves the application from Laravel 8 to Laravel 12 and runs a
large set of database migrations. Existing data is kept: the migrations alter
the schema in place, and custom-field columns keep their existing names.

### Before you start

1. **PHP 8.2 – 8.5** is required (`php -v`). The extensions needed are listed by
   `php upgrade.php` (curl, fileinfo, json, mbstring, pdo, bcmath, ldap, gd, xml, zip, …).
2. **Back up everything** and copy the backups off the server:
   ```bash
   php artisan assetsecure:backup      # 6.x installs: php artisan snipeit:backup
   mysqldump -u <user> -p <database> > assetsecure-pre-v8.sql
   ```
   Also keep a copy of `.env`, `public/uploads/`, `storage/private_uploads/` and the
   OAuth keys `storage/oauth-*.key`. **Never lose `APP_KEY`**: without it, encrypted
   custom fields cannot be decrypted.
3. Test the upgrade on a copy of the production database first.

### Git / bare-metal installs (`assetsecure.sh`)

```bash
cd /var/www/assetsecure
php artisan down
git pull origin master
php upgrade.php          # checks PHP, permissions; runs composer, backup, migrations and cache clears
php artisan up
```

If you prefer doing it by hand instead of `upgrade.php`:

```bash
composer install --no-dev --prefer-dist
php artisan migrate --force
php artisan config:clear && php artisan route:clear && php artisan view:clear && php artisan cache:clear
php artisan passport:keys   # only if storage/oauth-*.key are missing
```

### Docker installs

`docker-compose.yml` keeps the `mariadb` service name and the `db` volume, so an
existing database volume is reused.

1. Compose now reads settings from **`.env`** (previously `.env.docker`). Copy your
   existing values across (`APP_KEY`, `APP_URL`, `DB_*`, `MAIL_*`, …), starting from
   the new `.env.docker` template.
2. Set `MARIADB_VERSION` in `.env` to the MariaDB version your data volume was
   created with (check with `docker compose exec mariadb mariadb --version` before
   upgrading). Earlier releases used `mariadb:latest`; starting an existing volume
   on an *older* MariaDB version can fail. Upgrading MariaDB is fine.
3. Uploads, backups, OAuth keys and SSL certificates now persist in the named
   `storage` volume mounted at `/var/lib/assetsecure`. Earlier compose files left
   them in an anonymous volume, so copy them out of the old container before you
   recreate it:
   ```bash
   docker cp assetsecure:/var/lib/assetsecure ./assetsecure-data-backup
   ```
   After the upgrade, copy the contents back:
   `docker cp ./assetsecure-data-backup/. assetsecure:/var/lib/assetsecure/`, then
   `docker compose restart assetsecure`.
4. Rebuild and start the stack: `docker compose up -d --build`. The container runs the
   migrations on startup.

### Behaviour changes to know about

| Area | Change | Action |
|------|--------|--------|
| Artisan commands | `snipeit:*` commands are now `assetsecure:*` (e.g. `assetsecure:backup`, `assetsecure:ldap-sync`) | Update any cron jobs or scripts that call them. `php artisan schedule:run` is unchanged. |
| Session cookie | Default cookie name is now `assetsecure_session` (only applies if `COOKIE_NAME` is not set in `.env`) | Users sign in again once. |
| Backups | New backup files are named `assetsecure-*.zip` | Older backups can still be restored. |
| Theme | v6 skins are replaced by colour settings. The default header colour is the AssetSecure blue `#0096ff` | Adjust under *Settings → Branding* if needed. |
| SAML | SP metadata download is named `assetsecure-metadata.xml` | No change on the IdP side. |
| Installer | `snipeit.sh` is replaced by `assetsecure.sh` | — |

### Unchanged on purpose (compatibility)

- Custom field database columns keep the `_snipeit_<name>_<id>` naming. Renaming
  them would break existing data, API integrations and saved reports.
- The SCIM extension schema URN (`urn:ietf:params:scim:schemas:extension:grokability:2.0:User`)
  and the mobile-app OAuth redirect URI stay as they are, so existing identity-provider
  and client configurations keep working.
