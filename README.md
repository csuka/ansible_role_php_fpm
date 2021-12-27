# Ansible Role: PHP-FPM

An Ansible Role that installs PHP 8.x on EL 8.

 * 1.0.0 initial release
 * 1.0.1 rewrite naming for php_pear checking
 * 1.0.2 add apache as user to read the socket
 * 1.1.0 ensure key/values are properly added to /etc/php.ini
 * 1.1.1 have composer update value and has its own playbook
 * 1.1.2 improve permissions for socket and php-fpm user
 * 1.1.3 improve logrotate file
 * 1.2.0 improved installation method, added molecule testing

## Good 2 know

 * Ensure the php packages are available for the host
 * php72u-mcrypt is not a valid package anymore in 7.2, thus dropped automatically
 * A change in global vars or opache vars will **restart php**. Changing other settings reload php
 * If php-pear is enabled, ensure the host can connect to pecl.php.net and pear.php.net
 * [Libsodium](https://github.com/jedisct1/libsodium) must be installed via Pear, and not as a additional module. Ensure to install the system package 'libsodium-devel' from the EPEL repo

## Role Variables

Set version:

```yaml
php_version: 7.4
```

The modules are installed via the available repositories of the system.
Too view available modules, on the machine execute:

```bash
[user@vm ~]$ yum search "php-*"
<snip>
php-IDNA_Convert.noarch : Provides conversion of internationalized strings to UTF8
php-adodb.noarch : Database abstraction layer for PHP
php-bcmath.x86_64 : A module for PHP applications for using the bcmath library
php-cli.x86_64 : Command-line interface for PHP
...
<snip>
```

To add additional module ensure they are present in a repository. Add:

```yaml
php_additional_modules:
  - my_module
```

Install php dependencies with:
```yaml
php_fpm_dependencies:
  - libzip-devel
  - make
  - libsodium
  - libsodium-devel
```

Some values are calculated based on machine settings:

```yaml
php_fpm_pm_max_children: "{{ (php_fpm_memory_percentage / 100 * ansible_memtotal_mb / php_fpm_mb_per_thread) | int }}"
```

Set additional values for in php-fpm pool .ini file. Set additional values for /etc/php.ini.

```yaml
php_fpm_additional_ini:
  Section:
    key: value
  PHP:
    my_key: my_value
  Session:
    session.key: my_value
```

See `defaults/main.yml` for complete list of variables available and which are already set.

## Opcache

[Here is a list](https://www.php.net/manual/en/opcache.configuration.php) of values which can be set.

Default values:

```yaml
php_ext_opcache:
  enable: true
  enable_cli: false
  memory_consumption: 512
  interned_strings_buffer: 64
  max_accelerated_files: 65407
  validate_timestamps: true
  revalidate_freq: 2
  save_comments: 1
  blacklist_filename: '/etc/php.d/opcache*.blacklist'
  # my_key_one: my_value
  # my_key_two: my_value
```

## php-pear

php-pear can be installed with:

```yaml
php_pear: true
```

The php-pear package, provided from the repo's, didn't work. So I've chosen to install php-pear via the official method. To automate the installation, the package `expect` is installed and used.

The packages are automatically enabled in php. php is reloaded after a package is placed.

Install or update pear packages with:

```yaml
php_pear_modules:
  pecl/apcu:
    state: latest
    prompts:
      - (.*)Enable internal debugging in APCu \[no\]: "yes"
  pecl/memcache-4.0.5.2:
    state: present
  pecl/libsodium:
    state: latest
```

Update the php-pear package itself with:

```yaml
php_pear_update: true
```

Note that a pear package could require several system packages. This should be tested beforehand, the required system packages should be added via the `php_fpm_dependencies` variable.

The temp directory for PHP pear has to be writeable, in some cases `/tmp` is not writeable. Set this with. Ansible creates the folder and sets its permissions for it.

```yaml
php_pear_tmp_dir: /root/.pecl_tmp
```

## Logrotate

By default, a daily logrotate is done, and the logs are kept on disk for 14 days.
The file is placed in `/etc/logrotate.d/php-fpm`.

Edit the whole logrotate file with:
```yaml
php_fpm_logrotate: |
  my settings
  other settings
  rotate 1
```

## Example Playbook

```yaml
---
- hosts: host1
  roles:
    - php-fpm
  vars:
    php_fpm_dependencies:
      - libzip-devel
      - make
      - libsodium
      - libsodium-devel
    php_pear: true
    php_pear_modules:
      pecl/zip:
        state: present
    php_fpm_global_additional_ini:
      Pdo_mysql:
        pdo_mysql.default_socket: /var/run/mysqld/mysqld.sock
      MySQLi:
        mysqli.default_socket: /var/run/mysqld/mysqld.sock
    php_composer: true
    php_fpm_listen_group: nginx  # to let nginx write to the php-fpm socket
```
