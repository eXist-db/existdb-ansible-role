# Ansible Role: exist DB

This is an Ansible role to install and configure eXist DB
(http://exist-db.org/).

The current version is 1.1 (Dec 13 2021). This release supports
**eXist-db 5.x** and **multiple eXist-db instances** on a single host.
For a list of changes since the public beta release, please see
RELEASE_NOTES.md.

## Overview

This role allows to install exist by
* pulling from the git repo and building from source
* pulling a pre-packaged archive file from a remote server
* pushing a local pre-packaged archive file to the host

Installation methods can be switched by re-running Ansible.

This role installs exist and performs all necessary tasks to run on a server
(create user, install system service, miscellaneous setup).

Various config files get modified before starting exist (wrapper.conf, 
conf.xml, web.xml, client.properties), this is configurable and may be used to
tune behavioral and performance parameters.

By default, the exist/autodeploy directory is left untouched, so any xar files
there get installed at first startup. This can be overridden to pre-install a
defined set of xar packages for each host.

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
* the fact 'exist_java_home' is set by the calling playbook OR
  an ansible fact gathering script populating 'ansible_local.java.java_home' was deployed OR
  the `JAVA_HOME` environment variable is correctly set up
* Java binaries are in the shell `$PATH`

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    exist_user: existdb
    exist_group: existdb
    exist_home: /usr/local/existdb

Settings for the user that usually runs exist DB. This is a system user,
logins are not allowed. A separate user should be created to manage exist at
the shell level, this is outside the scope of this role.

    exist_instname: 'exist'
    #exist_instname: 'exist-test'
    #exist_instname: 'exist-prod'

The instance name of this eXist-db. If you are not running multiple instances
the default resembles the standard installation. If you **are** running
multiple instances, this variable distinguishes one instance from the others.

This variable is used to name the installation directory below `exist_home`.
It is also used as the system service name (systemd or SysV init).

    exist_instuser: 'existdb'
    #exist_instuser: 'tester'
    #exist_instuser: 'customer1'

The user that runs this eXist-db instance. If you are not running multiple
instances the default is to run eXist as user `existdb` just like the standard
installation. If you **are** running multiple instances, this variable can be
used to run each eXist-db instance under a separate user.

The specified Unix user gets created by this role if it does not exist yet.

    exist_instdescription: ''
    #exist_instdescription: 'testing'
    #exist_instdescription: 'my experimental setup'

An optional description string for this eXist-db instance. This gets used by
reporting tools only and is not required for operation. May be used to
provide additional information about this instance. Can be a multiline string,
but only the first line gets read by reporting tools. The content of this
variable gets stored in `$EXIST_HOME/contrib/DESCRIPTION.md` along with other
information.

    exist_http_port: 8080
    exist_ssl_port: 8443
    #exist_http_host: '127.0.0.1'
    #exist_ssl_host: '127.0.0.1'

Ports and IP bindings to use for unencrypted and TLS encrypted HTTP. The
defaults resemble a standard installation.

For multi-instance installations, each eXist-db instance requires unique HTTP
and SSL port numbers.

By default, eXist-db will bind to the given ports on all interfaces. You can
restrict the binding to a certain IP and network interface by explicitly
setting the `exist_http_host` and `exist_ssl_host` variables. A common use case
is to bind eXist-db to localhost only (thus not providing service on public IP
adresses) and use a frontend proxy such as `nginx` to provide public service.

To explicitly disable HTTP, you may set `exist_http_port: 0`. This has some
implications, see below "Restricting HTTP/HTTPS to Ports or IP Adresses" for
details.

    exist_mem_init_heap: 2048
    exist_mem_max_heap: 2048
    exist_mem_max_meta: 1024
    exist_mem_max_direct: 1024

Memory settings for this eXist-db instance. They map to the Java flags `-Xms`,
`-Xmx`, `-XX:MaxMetaspaceSize` and `-XX:MaxDirectMemorySize`.

    exist_mem_g1gc_pausegoal: 200
    exist_mem_gcdebug_enable: no
    exist_mem_nmt_enable: no
    exist_mem_strdedup_enable: yes
    exist_mem_niocachetune_enable: no

Special memory settings suited for high-load installations:
* `exist_mem_g1gc_pausegoal` is the value of Java option `-XX:MaxGCPauseMillis`
* `exist_mem_gcdebug_enable` enables GC logging for memory usage analysis
* `exist_mem_nmt_enable` enable Java Native Memory Tracking. **NOTE** ignored for exist 4.x because of conflicts with the YAJSW wrapper
* `exist_mem_strdedup_enable` enables Java String Deduplication
* `exist_mem_niocachetune_enable` works around a bug in java.nio that may lead to excessive memory usage in Java version < 11. This issue appears only in high load environments

Out of Memory error settings for this eXist-db instance. These only take effect if the JVM runs out of memory for eXist-db to operate. As it is almost impossible to recover from a Java OutOfMemoryError, it is recommened to at least enable `exist_mem_exitoom_enable` as this will help possible further corruption to the eXist-db database itself.

    exist_mem_exitoom_enable: yes
    exist_mem_dumpoom_enable: no

The `exist_mem_dumpoom_enable` setting will cause the JVM to write a Heap Dump file to `$EXIST_HOME/dump` if it runs out of memory. This can be useful for debugging possible Memory Leaks in eXist-db, or analyzing where eXist-db applications are consuming excessive memory.

    exist_major_version: 4

You need to explicitly specify whether you are going to install an eXist-db 4.x
or higher version. There is currently no auto-detection.

    exist_install_method: source

How to install exist, default is to install from source. Value can be:
* `source` (git clone official existdb repository and run `ant` or `maven` on the server to install)
* `remote_archive` (pre-packaged archive file downloaded from remote server)
* `local_archive` (pre-packaged archive present on the Ansible host)
* `none` (do not install or modify eXist).

If you can not or do not want to build locally, prepare a pre-packaged archive
for download and use `remote_archive`. If policy or firewalling does not allow
to pull packages from remote hosts, use `local_archive`. Use `none` to leave
the eXist installation untouched (eg to run other parts of this role only).

    exist_repo: https://github.com/eXist-db/exist.git
    exist_repo_version: develop-4.x.x
    exist_repo_update: yes
    exist_repo_force: yes

Settings for installing from source. The default is to track the HEAD branch
of the exist official Github repository (4.x branch).

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
whether to restore the previous data directory in the new installation.

    exist_startup_timeout: 300

How long to wait for exist to come up before raising an error (because we need
to proceed with exist running). If large Xars get installed by autodeploy,
this value may need to be increased.

    exist_wrapperconf_from_template: yes
    exist_jettyconf_from_template: yes
    exist_logconf_from_template: no
    exist_clientprops_from_template: yes
    # leave below at "no"
    exist_webxml_from_template: no
    exist_confxml_from_template: no

Whether to create certain config files from templates. Not fully supported for
conf.xml and web.xml, leave that disabled!

    exist_fdset_enable: yes
    exist_fdsoft_limit: 8192
    exist_fdhard_limit: 16384

Increase the OS limit of open file descriptors per process beyond the common
OS default of 1024, otherwise busy sites may experience problems when hitting
this limit. The fdhard limit is actually not used, we set both for consistency.

    exist_kerneltune_enable: no
    exist_kerneltune_swappiness: 10
    exist_kerneltune_cachepressure: 50

Kernel memory tuning parameters. This helps a little (but not much) on highly
loaded systems that run out of memory and start swapping. If some memory of an
eXist-db process gets swapped out, performance will drop dramatically. These
settings instruct the kernel to try to avoid swapping if possible.

    exist_syslog_enable: no
    exist_syslog_loghost: 127.0.0.1

Settings for logging to a remote syslog server. See "Logging" below.

    exist_log_retention_days: 30

How many days to keep old logfiles before they get deleted by the logrotate
mechanism. See "Logging" below.

    exist_prohibit_usermod: []

By default, this role will create the `exist_instuser` Unix user and set the
password specified in the vault. List Unix user names that this role must not
touch. This is useful if the `exist_instuser` Unix user already exists and has
a valid password already.

    # for exist 4.x >= 4.6
    exist_wrapper_relclasspath: "target/classes"
    # for exist 4.x < 4.6
    #exist_wrapper_relclasspath: "classes"
    exist_wrapper_loglevel: INFO
    exist_wrapper_startup_timeout: 90
    exist_wrapper_shutdown_timeout: 90
    exist_wrapper_ping_timeout: 90

Template parameters to modify exist tools/yajsw/conf/wrapper.conf file.
Applies to eXist 4.x and earlier only.

    exist_confxml_dbconn_cachesize: "256M"
    exist_confxml_trigger_xquerystartup_enable: no
    exist_confxml_trigger_autodeploy_enable: yes
    exist_confxml_pool_max: 20
    exist_confxml_recovery_enabled: "yes"
    exist_confxml_recovery_consistency_check: "yes"
    exist_confxml_job_check1_enable: no
    exist_confxml_job_check1_backup: "yes"
    exist_confxml_job_twitter_enable: no
    exist_confxml_job_cleansso_enable: no
    exist_confxml_serializer_indent: "yes"

Template parameters to modify exist conf.xml file. Ignored if
`exist_confxml_from_template` left at `no`.

    exist_webxml_initparam_hidden: "true"

Template parameters to modify exist webapp/WEB-INF/web.xml file. Ignored if
`exist_webxml_from_template` left at `no`.

## Setting the Admin Password and Pre-installing User Accounts

In a fresh install, we set the admin password right after starting eXist for
the first time. To do this, eXist needs to be running with the empty default
password first, but this exposure should not last longer than a few seconds.
We keep a marker file `{{ exist_datadir }}/.password-set` so we do this only
once.

Admin passwords are kept in a variable `exist_adminpass` which is a dict of
key/value pairs, where the keys are the inventory hostnames of the servers and
the values are dicts of key/value pairs, where the key is the exist instance
name and the value is the eXist admin password strings for each server, like
this:

```
exist_adminpass:
  myserver1:
    myinstanceA: MySecretPass
    myinstanceB: DifferentPass
  myserver2:
    exist: MyDefaultPass
  myserver3:
    unprotected: ""
```

It is also possible to pre-set passwords for standard eXist user accounts or to
pre-install additional user accounts with passwords like this:

```
exist_userpass_map:
  myserver1:
    myinstanceA:
      "eXide": "thispassword"
      "guest": "guestpass"
      "SYSTEM": "wonttell"
  myserver2:
    myinstanceB:
      "eXide": "thatpassword"
      "guest": "guestpass"
      "extrauser": "secret"
  myserver3: {}
```

As with the `exist_adminpass` variable, `exist_userpass_map` holds a dict with
inventory hostnames as the key. Values are dicts itself with the exist instance
name as the key, and a dict of usernames/passwords as the value.

As shown for `myserver3`, use an empty dict if you don't want to modify user
accounts, or if you really want to use an empty admin password. But both
variables need a key/value pair for each eXist server managed with Ansible,
otherwise you will get a syntax error.

**IMPORTANT** Since the passwords are clear text, they should not be set in a
playbook, but stored in an encrypted Ansible vault instead. In the example
playbook below, this vault file is referenced as `inventory/my_vault.yml`.

## Restricting HTTP/HTTPS to Ports or IP Adresses

By default, eXist-db will bind to ports specified in `exist_http_port` and
`exist_ssl_port` on all interfaces of the server, including localhost. On an
Internet connected server, this exposes the eXist-db instance to the world,
which may or may not be what you intended.

Exist Solutions recommends to run eXist-db behind a lightweight frontend proxy
such as `nginx` running on the same server. This gives much better access
control, certificate handling, URL rewriting and logging options than
eXist-db/Jetty can provide.

In this scenario, you would specify `exist_http_host: '127.0.0.1'` and
`exist_ssl_host: '127.0.0.1'` to bind exist to the loopback interface only.
Then you configure the proxy to listen on the standard HTTP/HTTPS port and
forward requests to the exist instance running on 127.0.0.1:xxxx.

This provides a simple way to disable HTTP for an exist server (and serve SSL
only): let exist bind its HTTP port to localhost only (so it's not reachable
without proxy); do not proxy HTTP requests to exist; redirect HTTP to HTTPS
URLs in the proxy.

### Disabling HTTP entirely

Regulations or policies may require that unencrypted HTTP is disabled
completely. This can be achieved by setting `exist_http_port: 0`.

Note this has some implications, as some eXist-db components might default to
HTTP and fail. This role will adjust the admin client config file
`client.properties` to use SSL. Other config files may need attention.

In theory, you could also disable the SSL/TLS listener by setting
`exist_ssl_port: 0`. In practice, this will break exist 4.x installations
because of interactions with the YAJSW wrapper. Just don't.

## Backup and Restore

Whenever a different eXist version gets installed by Ansible (either by
switching between source/archive, or by installing a different archive, or by
compiling newer source code), this Ansible role creates a backup by default.
These are file backups made after cleanly shutting down eXist.

[outdated documentation removed]

## Logging

By default, eXist-db logs into logfiles located in `$EXIST_HOME/logs` (exist
5.x) or `$EXIST_HOME/webapp/WEB-INF/logs` (exist 4.x).

Use the following setting to control how many days log files are kept before
automatic deletion by the logrotate mechanism. Set to zero to prohibit any log
file deletion (by not installing a logrotate config).

    exist_log_retention_days: 30

To log to a central remote syslog server, use the following settings:

    exist_logconf_from_template: yes
    exist_syslog_enable: yes
    exist_syslog_loghost: 192.168.0.100

With these settings, the `$EXIST_HOME/etc/log4j2.xml` (exist 5.x) or
`$EXIST_HOME/tools/yajsw/conf/log4j2.xml` (exist 4.x) config file 
gets modified to log events in syslog format to the remote syslog server
`192.168.0.100`.

## Security Considerations

We recommend to run eXist-db behind a reverse proxy such as `nginx` when
exposing eXist-db to the public Internet. Simply because `nginx` is much more
lightweight in dealing with HTTP abuse attempts.

File webapp/WEB-INF/web.xml gets modified so that `servlet/init-param` prevents
unauthorized directory listings (`exist_webxml_initparam_hidden="true"`). To
restore the default behavior, set this variable to string "false".

## Performance Tuning

Increase heap memory for the exist process beyond 2GB default (unit is MB). Set
min and max to the same amount to help the G1GC garbage collector to size its
region space:

    exist_mem_min_heap: 16384
    exist_mem_max_heap: 16384

Limit the amount of `Metaspace` and `DirectMemory` to reasonable values (unit
is MB). Without limits on highly loaded servers, these may consume significant
amounts of memory that does not get garbage collected. The suggested values
are good even for highly loaded servers. Should you encounter exceptions
relating to out of `Metaspace` or `DirectMemory` you may need to increase
these values:

    exist_mem_max_meta: 1024
    exist_mem_max_direct: 1024

Ensure file descriptor limits are increased, otherwise you may get an "out of
file descriptors" exception on loaded systems:

    exist_fdset_enable: yes
    exist_fdsoft_limit: 8192

Avoid swapping. If the eXist-db process starts to use swap space, performance
will degrade massively and likely result in a slow meltdown. The following
parameters instruct the kernel to reduce the likelyhood of swap space usage:

    exist_kerneltune_enable: yes
    exist_kerneltune_swappiness: 1

However, that's no silver bullet. If you consume more memory than you actually
have, you will swap, no matter what.

More tunable parameters from file `conf.xml`. Do not blindly increase, make
sure you understand the implications. Note `conf.xml` is currently not
templated by default.

    exist_confxml_dbconn_cachesize: "256M"
    exist_confxml_pool_max: 20

### Heavy Memory Tuning

For highly loaded eXist-db servers, more tweaking may be needed to address
excessive memory consumption.

Enable Java G1GC string deduplication:

    exist_mem_strdedup_enable: yes

Enable workaround for java.nio excessive memory usage (JDK-8147468) - ignore
if using Java11 or higher:

    exist_mem_niocachetune_enable: yes

Enable GC logging for further analysis:

    exist_mem_gcdebug_enable: yes

Enable Java Native Memory Tracking in exist 5.x. This has no effect on 4.x
because it will conflict with the YAJSW wrapper.

    exist_mem_nmt_enable: yes

If GC analysis suggests that GC cannot keep up, you might consider increasing
G1GCs pause time goal from 200 to 250 or 300 milliseconds:

    exist_mem_g1gc_pausegoal: 250

## Multiple Exist Instances on the same Host

Back in the old days, it was quite tedious to run more than one eXist-db
instance on a single server. It involved various manual tasks to keep the
installations dirs separate, assign port numbers, or create service startup
files for each instance.

The eXist-db Ansible role v1.0 supports multiple eXist installations by
automating the necessary configuration steps. You would create an Ansible
play that includes multiple instances of the existdb-ansible-role, each with
its own set of role variables.

In a multi-instance setup, each instance MUST declare at least the following
variables:

```
exist_instname: exist-foo
exist_instuser: foo
exist_http_port: 7649
exist_ssl_port: 7382
```

* `exist_instname` must be unique to distinguish the instances from each other. this implicitly specifies the system service name and the installation directory;
* `exist_instuser` is the Unix user that runs this instance (user gets created by default). this can be used to isolate access permissions for each instance;
* `exist_http_port` and `exist_ssl_port` must be unique for exist instances on the same host, and must not conflict with other applications that may use these ports.

These are mandatory minimum variables for multiple instances. Additional
variables to customize each instance can be passed as well.

### I Want the Old Single-Instance Setup that I'm familiar with

Fine. Keep the single role instance and **don't** set any of the variables
above. In this case the following defaults get used which you are familiar
with:

```
exist_instname: eXist
exist_instuser: existdb
exist_http_port: 8080
exist_ssl_port: 8443
```

Running a single-instance setup is actually a special case multi-instance
setup with only one instance and default values.

### Installation Directories

All eXist-db instances are installed below `exist_home (default /usr/local/existdb)`. Each instance has its own subdirectory here, named after its `exist_instname`. Given the examples above (single-instance plus foo instance added):

```
# default instance
/usr/local/existdb/exist
# foo instance
/usr/local/existdb/exist-foo
```

Each instance installation directory gets restricted access modes.

### Service Startup

For each instance, an indiviual named service startup file gets created. For the examples above you could run:

```
service eXist stop
service exist-foo start
```

## Customizing Xar Installation

Works, but not fully documented yet.

## Monex

XXX Not fully supported yet.

## Dependencies

None, except Java obviously.

## Example Playbook

```
- name: Setup eXist DB instances
  hosts: exist_servers
  # need to be root for various install steps
  become: yes
  # confidential data (passwords) are read from an encrypted Ansible vault file
  vars_files:
    - ../inventory/my_vault.yml
  environment:
    JAVA_HOME: "/your/jdk/dir"

  tasks:
    - name: Ensure Maven is installed for exist5 src install
      include_role:
        name: ansible-role-maven

    # 4.x instance (apps4test)
    - name: Ensure exist instance apps4test is setup
      include_role:
        name: existdb-ansible-role
      vars:
        exist_instname: 'apps4test'
        exist_instuser: 'exsol'
        exist_instdns: 'apps4test.example.com'
        exist_major_version: 4
        exist_install_method: source
        exist_repo: 'https://github.com/eXist-db/exist.git'
        exist_repo_version: 'develop-4.x.x'
        exist_http_host: '127.0.0.1'
        exist_http_port: 8571
        exist_ssl_host: '127.0.0.1'
        exist_ssl_port: 8572
        exist_mem_init_heap: 4096
        exist_mem_max_heap: 4096
        exist_mem_gcdebug_enable: yes
        exist_mem_strdedup_enable: yes
        exist_mem_nmt_enable: no
        exist_mem_niocachetune_enable: yes
        exist_install_custom_xars: no
        exist_webxml_from_template: no
        exist_logconf_from_template: yes
        exist_syslog_enable: yes
        exist_kerneltune_enable: yes
        exist_wrapper_relclasspath: "target/classes"
      tags:
        - apps4test

    # 5.0 instance (apps5test)
    - name: Ensure exist instance apps5test is setup
      include_role:
        name: existdb-ansible-role
      vars:
        exist_instname: 'apps5test'
        exist_instuser: 'exsol'
        exist_instdns: 'apps5test.example.com'
        exist_major_version: 5
        exist_install_method: source
        exist_repo: 'https://github.com/eXist-db/exist.git'
        exist_repo_version: 'develop-5.0.0'
        exist_http_host: '127.0.0.1'
        exist_http_port: 8561
        exist_ssl_host: '127.0.0.1'
        exist_ssl_port: 8562
        exist_mem_init_heap: 4096
        exist_mem_max_heap: 4096
        exist_mem_gcdebug_enable: yes
        exist_mem_strdedup_enable: yes
        exist_mem_nmt_enable: yes
        exist_mem_niocachetune_enable: yes
        exist_install_custom_xars: no
        exist_webxml_from_template: no
        exist_logconf_from_template: yes
        exist_syslog_enable: yes
        exist_kerneltune_enable: yes
      tags:
        - apps5test
```

## License

LGPL v2

## Author Information

This role was created in 2018 by Olaf Schreck (olaf@existsolutions.com) for
Exist Solutions GmbH.
