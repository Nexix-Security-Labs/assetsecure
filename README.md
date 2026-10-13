![AssetSecure by Nexix Security Labs](public/img/logo.png)

## AssetSecure - Asset Management Software

AssetSecure is an IT asset management system for IT operations teams: know who has which laptop, when it was purchased so it can be depreciated correctly, which software licenses are in use, and more.

It is built on [Laravel 12](https://laravel.com) and requires PHP 8.2 or newer.

__This is web-based software__. There is no executable file (no .exe files); it runs on a web server and is accessed through a web browser. It runs on Linux, macOS and Windows servers, and can also be run with Docker.

-----

### Installation

**Ubuntu / Debian (automated):**

```bash
curl -O https://raw.githubusercontent.com/Nexix-Security-Labs/assetsecure/master/install.sh
sudo bash install.sh
```

`install.sh` downloads and runs [`assetsecure.sh`](assetsecure.sh), which installs Apache, MariaDB, PHP and Composer, creates the database (with a randomly generated password stored in `.env`), runs the migrations and configures the virtual host. Use a distribution that ships PHP 8.2+ (Ubuntu 24.04+, Debian 12+).

To install a specific branch or tag, run the script directly: `sudo AS_BRANCH=<branch-or-tag> ./assetsecure.sh` (default: `master`). The script is safe to re-run: it keeps the existing `.env`, database password and app key.

When asked for the address, enter exactly what you will type in the browser: it becomes `APP_URL`, and AssetSecure builds every link, script and stylesheet URL from it, so pages load without styling if the two differ. The installer suggests `localhost` on WSL2 (where `127.0.0.1` is often not forwarded to Windows) and the server's IP address elsewhere. To change it later, edit `APP_URL` in `/var/www/assetsecure/.env` and run `sudo -u www-data php /var/www/assetsecure/artisan config:clear`.

The code is owned by a dedicated `assetsecure` user; the web server (`www-data`) can only write to `storage/`, `bootstrap/cache/` and `public/uploads/`.

**Docker:**

```bash
cp .env.docker .env      # then edit APP_URL, APP_KEY and the DB_* values
docker compose up -d --build
```

The app is served on port `8069` by default (override with `APP_PORT`). Persistent data (uploads, backups, OAuth keys, SSL certificates) lives in the `/var/lib/assetsecure` volume.

**Manual:** clone the repository, run `composer install --no-dev`, copy `.env.example` to `.env`, configure it, run `php artisan key:generate`, then open `/setup` in a browser.

-----

### Upgrading

See [UPGRADING.md](UPGRADING.md). Upgrading from AssetSecure 6.x to 8.x requires PHP 8.2+ and runs database migrations, so **back up your database and uploads first**.

-----

### Bug Reports & Feature Requests

Please use the [GitHub Issues for this project](https://github.com/Nexix-Security-Labs/assetsecure/issues). Search existing issues (open *and* closed) before opening a new one.

-----

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). This project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

-----

### Security

> **To report a security vulnerability, please email security@nexixsecuritylabs.com instead of using the issue tracker.** See [SECURITY.md](SECURITY.md).

-----

### License

AssetSecure is free software licensed under the [GNU Affero General Public License v3.0 or later](LICENSE). See [NOTICE.md](NOTICE.md) for attribution.

-----

AssetSecure is developed by [Nexix Security Labs](https://nexixsecuritylabs.com).
