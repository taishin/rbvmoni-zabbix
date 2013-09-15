# rbvmoni-zabbix

rbvmoni-zabbixはZabbixでvSphere環境を監視する
下記の機能を実装している

* vCenterからESXi、ストレージ、仮想サーバの情報を取得する
* ESXi、ストレージ、仮想マシンをZabbixに自動登録
* 仮想マシンが削除されるて1日経つと、Zabbixから自動削除する

## Prerequisite

rbvmomi、zbxapiが必要
* vSphere APIを利用するために[rbvmomi](https://github.com/rlane/rbvmomi)をインストール `gem install rbvmomi`
* Zabbix APIを利用するために[zbxapi](http://rubygems.org/gems/zbxapi)をインストール `gem install zbxapi`

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
