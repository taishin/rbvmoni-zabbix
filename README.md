# rbvmoni-zabbix

rbvmoni-zabbix is a Ruby script which monitors vSphere environment by Zabbix.

This script has the following features. 

* Getting information of ESXi, Storage, and Virtual Machines from vCenter and Zabbix server monitors them.
* Auto-registration of the ESXi, Storage and Virtual Machines to Zabbix.
* Auto-deletion of the ESXi, Storage and Virtual Machines from Zabbix when they are deleted and one day will pass.

## Prerequisite

* [rbvmomi](https://github.com/rlane/rbvmomi) is required in order to use vSphere API. `gem install rbvmomi`
* [zbxapi](http://rubygems.org/gems/zbxapi) is required in order to use Zabbix API. `gem install zbxapi`

## Install

* rbvmoni-zabbix.rbを/etc/zabbixに保存
* userparameter_vsphere-vm.confを/etc/zabbix/zabbix_agentd.dに保存
* XMLファイルをZabbixにインポート
* Server, AgentのTimeoutを最大(30)にする /etc/zabbix/zabbix_server.conf,/etc/zabbix/zabbix_agentd.conf
* `/etc/zabbix/rbvmoni-zabbix.rb (vCenter IP) (vCenter Username) (vCenter Password) (Zabbix Group Prefix) (Zabbix API URL)`
** `/etc/zabbix/rbvmoni-zabbix.rb 10.1.1.1 administrator password DC http://10.1.1.2/zabbix/api`
正常に終了すれば、0が表示される
/tmp/vsphere/にステータスファイルとログファイルが作成される
* ZabbixのHostにvCenterを登録し、Template-vCenter.xmlを適用する
* 下記のマクロを作成する
* {$VC_HOST}
* {$VC_USERNAME}
* {$VC_PASSWORD}
* {$DS_NAME}
* {$ZBX_URL}
* 
