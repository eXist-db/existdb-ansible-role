# Ansible Role: exist DB

**NOTE** this a **beta release**. See "In the Works" below. Some warts might
be included.

This is an Ansible role to install and configure eXist DB
(http://exist-db.org/).

This role allows to install exist by
* pulling from the git repo and building from source
* pulling a pre-packaged archive file from a remote server
* pushing a local pre-packaged archive file to the host

Installations methods can be switched by re-running Ansible.

This role installs exist and performs all necessary tasks to run on a server
(create user, install system service, misc setup).

Various config files get modified before starting exist (wrapper.conf, 
conf.xml, web.xml, client.properties), this is configurable and may be used to
tune behavioral and performance parameters.

By default, the exist/autodeploy directory is left untouched, so any xar files
there get installed at first startup. This can be overridden to pre-install a
defined set of xar packages for each host. This is EXPERIMENTAL and likely to
change. Works for us on large sites where dev/staging/prod servers get a
different set of >20 xar packages pre-installed.

When upgrading or replacing a running exist DB (either by installing a newer
or different archive, or switching install methods between source/archive
installation), a backup gets created by default, and the data directory of the
previous installation gets copied back into the new installation. This is
configurable.

After a fresh exist installation the exist admin password and user passwords
get set. They are persistent and not re-set in later Ansible runs.

## Requirements

Exist DB requires Java. Installing Java is outside of scope of this role, we
assume:
* Java JDK is installed (JRE might be sufficient in some situations, but you can't build from source then)
* the `JAVA_HOME` environment variable is correctly set up
* Java binaries are in the shell `$PATH`

## In the Works

This is a list of features coming soon. Most of this is either prepared but
not fully tested, or already in use at customer sites so that customer
specific settings need to get factored out yet.

- multiple exist instances on the same host, with different install dirs,
  service names and IP:port configs;
- some config files such as conf.xml vary among distributions, so
  templating is not optimal; and these configs might get so special that it's
  hard to template at all;
- custom Xar package installations: we use this at customer sites, but details
  vary and have to be sorted out;
- we currently use the Java admin client to execute XQuery scripts, use Perl
  XMLRPC script for simplicity;

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    exist_user: existdb
    exist_group: existdb
    exist_home: /usr/local/existdb

Settings for the user that runs exist DB. This is a system user, logins are
not allowed. You should create a separate user to manage exist at the shell
level.

    exist_dir: exist
    exist_suffix: ""

Exist DB gets installed into a directory named `exist_dir` inside the directory
`exist_home` (default: /usr/local/existdb/exist).

The `exist_suffix` allows to run multiple instances of exist DB on the same
host, see "Multiple Instances" below. If you run only a single exist instance
on the host, leave this parameter empty.

    exist_http_port: 8080
    exist_ssl_port: 8443

Ports to use for unencrypted and TLS encrypted HTTP.
[XXX convention how to disable HTTP?]

    exist_startup_timeout: 300

How long to wait for exist to come up before raising an error (because we need
to proceed with exist running). If large Xars get installed by autodeploy,
this value may need to be increased.

    exist_service: eXist-db

Service name for SysV/init.d or systemd. Rarely needs to be changed. Gets
`exist_suffix` appended automatically when using multiple exist instances.

    exist_install_method: source

How to install exist. Can be `source` (git clone official existdb repository
and run `build.sh` on the server to install), `remote_archive` (pre-packaged
archive file downloaded from remote server), `local_archive` (pre-packaged
archive present on the Ansible host) or `none` (do not install or modify
eXist). Default is to install from source.

If you can not or do not want to build locally, prepare a pre-packaged archive
for download and use `remote_archive`. If policy or firewalling does not allow
this, use `local_archive`. Use `none` to leave the eXist installation
untouched (eg to run other parts of this role only).

    exist_repo: https://github.com/eXist-db/exist.git
    exist_repo_version: develop-4.x.x
    exist_repo_update: yes
    exist_repo_force: yes

Settings for installing from source. The default is to track the HEAD branch
of the exist official Github repository.

    exist_archive: "eXist-4.2.0-201806071027.tar.gz"

Archive filename when install method is "remote_archive" or "local_archive".

    exist_baseurl: "http://dl.example.com/files/"

Settings for installing using `remote_archive`. Fetch archive file
`exist_archive` from remote URL `exist_baseurl`.

    exist_local_archive_dir: "/tmp"

Settings for installing using `local_archive`. Expect file `exist_archive` in
directory `exist_local_archive_dir` on the Ansible host.

    exist_backup_previnstall: yes
    exist_restore_prevdata: yes

Whether to create a backup when installing a different eXist version, and
whether to restore the previous `webapp/WEB_INF/data` directory in the new
installation.

    exist_wrapperconf_from_template: yes
    exist_logconf_from_template: no
    exist_clientprops_from_template: yes
    exist_webxml_from_template: yes
    exist_confxml_from_template: no

Whether to create certain config files from template.
XXX Not fully supported for conf.xml.

    exist_fdset_enable: true
    exist_fdsoft_limit: 8192
    exist_fdhard_limit: 16384

Increase the OS limit of open file descriptors per process beyond the common
OS default of 1024, otherwise busy sites may experience problems when hitting
this limit.

    exist_kerneltune_enable: false
    exist_kerneltune_swappiness: 10
    exist_kerneltune_cachepressure: 50

Kernel memory tuning parameters.  XXX EXPERIMENTAL

    exist_syslog_enable: false
    exist_syslog_loghost: 127.0.0.1

Settings for logging to a remote syslog server. See "Logging" below.

    exist_confxml_dbconn_cachesize: "256M"
    exist_confxml_trigger_xquerystartup_enable: False
    exist_confxml_trigger_autodeploy_enable: True
    exist_confxml_pool_max: 20
    exist_confxml_recovery_enabled: "yes"
    exist_confxml_recovery_consistency_check: "yes"
    exist_confxml_job_check1_enable: False
    exist_confxml_job_check1_backup: "yes"
    exist_confxml_job_twitter_enable: False
    exist_confxml_job_cleansso_enable: False
    exist_confxml_serializer_indent: "yes"

Template parameters to modify exist conf.xml file.

    exist_wrapper_max_mem: 2048
    exist_wrapper_gcdebug_enable: False
    exist_wrapper_jmx_enable: False
    exist_wrapper_jmx_port: 9911
    exist_wrapper_loglevel: INFO
    exist_wrapper_startup_timeout: 90
    exist_wrapper_shutdown_timeout: 90
    exist_wrapper_ping_timeout: 90

Template parameters to modify exist tools/yajsw/conf/wrapper.conf file.

    exist_webxml_initparam_hidden: "false"

Template parameters to modify exist webapp/WEB-INF/web.xml file.

    exist_install_custom_xars: False

The default behavior is to support exist "autodeploy", that means installing
all Xar files that are present in the `$EXIST_HOME/autodeploy` folder.

Set `exist_install_custom_xars` to True if you need to control which Xar files
to install. You need to provide lists of Xar file names such as "foo-1.0.0.xar"
in variables in the calling playbook, see "Customizing Xar Installation"
below.

Custom Xar installation supports both downloading remote Xar files from a
public HTTP repository and installing local xars from a directory on the
Ansible host, eg for non-public Xars.

    exist_xarbaseurl: "http://demo.exist-db.org/exist/apps/public-repo/public/"
    exist_remote_xars: []

Public custom Xar files to install that can be fetched from a remote server at
the specified URL.

    exist_xarprivdir: /tmp
    exist_local_xars: []

Private custom Xar files to install that must be present in the specified
directory on the Ansible host.

    exist_force_xar_install: "false"

## Setting the Admin Password and Pre-installing User Accounts

In a fresh install, we set the admin password right after starting eXist for
the first time. To do this, eXist needs to be running with the empty default
password first, but this exposure should not last longer than a few seconds.
We keep a marker file `$EXIST_HOME/webapp/WEB-INF/data/.password-set` so we do
this only once.

Admin passwords are kept in a variable `exist_adminpass` which is a dict of
key/value pairs, where the keys are the inventory hostnames of the servers and
the values are the eXist admin password strings for each server, like this:

```
exist_adminpass:
  myserver1: MySecretPass
  myserver2: MyOtherPass
  myserver3: ""
```

It is also possible to pre-set passwords for standard eXist user accounts or to
pre-install additional user accounts with passwords like this:

```
exist_userpass_map:
  myserver1: |
    map:entry("eXide", "thispassword"),
    map:entry("guest", "guestpass"),
    map:entry("SYSTEM", "wonttell")
  myserver2: |
    map:entry("eXide", "thatpassword"),
    map:entry("guest", "guestpass"),
    map:entry("extrauser", "secret")
  myserver3: ""
```

As with the `exist_adminpass` variable, `exist_userpass_map` holds a dict with
inventory hostnames as the key. Values are literal XQuery sequence fragments.
**NOTE** for this reason, all entries except the last one need a trailing
comma, otherwise you will get a syntax error.

As shown for `myserver3`, use an empty string if you don't want to modify user
accounts, or if you really want to use an empty admin password. But both
variables need a key/value pair for each eXist server managed with Ansible,
otherwise you will get a syntax error.

**IMPORTANT** Since the passwords are clear text, they should not be set in a
playbook, but stored in an encrypted Ansible vault instead. In the example
playbook below, this vault file is referenced as `inventory/my_vault.yml`.

## Backup and Restore

Whenever a different eXist version gets installed by Ansible (either by
switching between source/archive, or by installing a different archive, or by
compiling newer source code), this Ansible role creates a backup by default.
These are file backups made after cleanly shutting down eXist.

The backups are stored in dir `{{ exist_home }}/backup` in directories named
after the eXist instance and a timestamp like this:

```
# cd {{ exist_home }}/backup; ls -l
drwxr-x--x 3 existdb existdb 4096 Sep 18 14:09 exist.201809181409
drwxr-x--x 3 existdb existdb 4096 Oct  8 16:03 exist.201810081603
drwxr-x--x 3 existdb existdb 4096 Oct 14 14:51 exist-test.201810141451
drwxr-xr-x 3 existdb existdb 4096 Oct 14 15:03 exist.201810141503
lrwxrwxrwx 1 existdb existdb   18 Oct 14 15:03 last -> exist.201810141503
```

A backup can be restored by calling the `exist-restore.sh` like this:
`/usr/local/existdb/scripts/exist-restore.sh exist.201810081603`.

## Logging

By default, eXist-db logs into logfiles located in
`/usr/local/existdb/exist/webapp/WEB-INF/logs`.

To log to a central remote syslog server, use the following settings:

    exist_logconf_from_template: yes
    exist_syslog_enable: yes
    exist_syslog_loghost: 192.168.0.100

With these settings, `/usr/local/existdb/exist/tools/yajsw/conf/log4j2.xml`
gets modified to log events in syslog format to the remote syslog server
`192.168.0.100`.

## Security Considerations

We recommend to run eXist-db behind a reverse proxy such as `nginx` when
exposing eXist-db to the public Internet. Simply because `nginx` is much more
lightweight in dealing with HTTP abuse attempts.

File webapp/WEB-INF/web.xml gets modified so that `servlet/init-param` prevents
unauthorized directory listings (`exist_webxml_initparam_hidden="true"`). To
restore the default behavior:

    exist_webxml_initparam_hidden: "false"

## Performance Tuning

Increase memory for the exist process beyond 2GB default (unit is MB):

    exist_wrapper_max_mem: 16384

Ensure file descriptor limits are increased:

    exist_fdset_enable: true
    exist_fdsoft_limit: 8192

More tunable parameters. Do not blindly increase, make sure you understand the
implications.

    exist_confxml_dbconn_cachesize: "256M"
    exist_confxml_pool_max: 20

## Multiple Exist Instances on the same Host

XXX Not fully supported yet.

## Customizing Xar Installation

XXX Not fully supported yet.

## Monex

XXX Not fully supported yet.

## Dependencies

None, except Java obviously.

## Example Playbook

Role default vars are overridden below the `role:` line.

```
- name: Setup eXist DB
  hosts: exist_servers
  # need to be root for various install steps
  become: True
  # confidential data (passwords) are read from an encrypted Ansible vault file
  vars_files:
    - ../inventory/my_vault.yml
  environment:
    JAVA_HOME: "/your/jdk/dir"
  roles:
    - role: existdb-ansible-role
      exist_install_method: source
      exist_repo_version: develop-5.0.0
      #exist_http_port: 8081
```

## License

MIT / BSD

## Author Information

This role was created in 2018 by Olaf Schreck (olaf@existsolutions.com) for
Exist Solutions GmbH.
