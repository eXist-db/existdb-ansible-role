# Current Version

Version 1.0 (Aug 15 2021)

This version has been applied to various eXist-db instances that are actively
in production, including more complex setups that use production/staging/dev
environments or data replication for high availability.

## New Features

* add support for eXist-db 5.x
* add multi-instance support (multiple eXist-db on the same host)
* improve memory and GC parameter configuration
* improve Jetty port and IP address configuration
* very flexible pre-installation of xar packages

## Fixes and Improvements

* [bugfix] disable exist_webxml_from_template by default (thanks @sermo-de-arboribus)
* provide installation documentation
* cleanup exist_adminpass and exist_userpass_map formats
* add syslog support
* add logrotate support for automatic deletion of old log files
* add kernel memory tuning (swappiness)
* add install_method: 'none' (do not touch an installed version)
* make install/replace decision logic more robust
* adapt for deprecated XQuery functions in eXist-db 5.x (thanks @joewiz)
* review and improve documentation
* add Ansible tags
* replace deprecated Ansible constructs (thanks @OyvindLG)
* add Ansible meta data (thanks @jdwit)
* rewrite upload-xmlrpc.pl in python3
* can apply patches after git checkout on source build
* prepare for 'run xquery during startup' (add collection '/db/system/autostart')
* allow xars to be installed from path on destination host (add 'remote_src')
* help ansible check-mode by allowlisting non-modifying shell calls (add 'check_mode: false')
* make maven options configurable (add 'exist_mvn_options')
* disable restxq autostart (add 'exist_confxml_trigger_restxq_enable')
* ability to "live"-patch xars by adding attributes to 'xar_install', see 'exist_xar_' and 'exist_replication_'

## Incompatibilities with Earlier Versions

* format of exist_adminpass and exist_userpass_map variable has changed, see "Setting the Admin Password and Pre-installing User Accounts" in README.md
* recommended role invocation has changed to `include_role`, see "Example Playbook" in README.md
* some config variables have been removed or renamed, please refer to `defaults/main.yml` or README.md

# Old Versions

## Unversioned Beta-Release (Nov 1 2018)

Initial public beta release.
