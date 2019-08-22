# TODO

* review backup
* revision detection in src install
* custom xar install

# Current Version

Version 1.0RC1 (Aug 24 2019)

## New Features

* add support for eXist-db 5.x
* add multi-instance support (multiple eXist-db on the same host)
* improve memory and GC parameter configuration
* improve Jetty port and IP address configuration

## Fixes and Improvements

* cleanup exist_adminpass and exist_userpass_map formats
* add syslog support
* add kernel memory tuning (swappiness)
* add install_method: 'none' (do not touch an installed version)
* make install/replace decision logic more robust
* adapt for deprecated XQuery functions in eXist-db 5.x (thanks @joewiz)
* review and improve documentation
* add Ansible tags
* replace deprecated Ansible constructs (thanks @OyvindLG)
* add Ansible meta data (thanks @jdwit)

## Incompatibilities with Earlier Versions

* format of exist_adminpass and exist_userpass_map variable has changed, see "Setting the Admin Password and Pre-installing User Accounts" in README.md
* recommended role invocation has changed to `include_role`, see "Example Playbook" in README.md
* some config variables have been removed or renamed, please refer to `defaults/main.yml` or README.md

# Old Versions

## Unversioned Beta-Release (Nov 1 2018)

Initial public beta release.
