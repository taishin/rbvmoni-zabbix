# rbvmoni-zabbix

rbvmoni-zabbix is a Ruby script which monitors vSphere environment by Zabbix.  
This script has the following features. 

* Getting information of ESXi, Storage, and Virtual Machines from vCenter and Zabbix server monitors them.
* Auto-registration of the ESXi, Storage and Virtual Machines to Zabbix.
* Auto-deletion of the ESXi, Storage and Virtual Machines from Zabbix when they are deleted and one day will pass.

## Prerequisite

* [rbvmomi](https://github.com/rlane/rbvmomi) is required in order to use vSphere API. `gem install rbvmomi`
* [zbxapi](http://rubygems.org/gems/zbxapi) is required in order to use Zabbix API. `gem install zbxapi`  
If your Zabbix Server is 2.0.4 later, apply [this workaround](your Zabbix Server is after 2.0.4. 
). 

## Install

1. Set rbvmoni-zabbix.rb on /etc/zabbix. 
* Set userparameter_vsphere-vm.conf on Userparameter directory. (Generally,/etc/zabbix/zabbix_agentd.d)
* Import XML files (Zabbix Template) to Zabbix by Web Interface. 
* Set maximum(30) to Timeout of Zabbix Server and Zabbix Agent. (Generally,/etc/zabbix/zabbix_server.conf,/etc/zabbix/zabbix_agentd.conf)
* Execute rbvmoni-zabbix.rb
 `/etc/zabbix/rbvmoni-zabbix.rb (vCenter IP) (vCenter Username) (vCenter Password) (Zabbix Group Prefix) (Zabbix API URL)`
 Example  
 `/etc/zabbix/rbvmoni-zabbix.rb 10.1.1.1 administrator password DC http://10.1.1.2/zabbix/api`  
0 is retuned when it succeeds.  
Status files and log files are created in /tmp/vsphere/.  
* Regist vCenter into Host of Zabbix, and apply Template-vCenter.xml to it.  
* Create the following macro to registered vCenter. 
  - `{$VC_HOST}` vCenter IP Address
  - `{$VC_USERNAME}` vCenter Username
  - `{$VC_PASSWORD}` vCenter Password
  - `{$DS_NAME}` Zabbix Group Prefix
  - `{$ZBX_URL}` Zabbix API URL

## Options

If you do not want to remove VirtualMachine which you removed from Zabbix, $EnableDeprovisioningHostGroup is set to True, you can move to Host Groups called Deprovisioned Hosts of Zabbix, without removing Host.  
(Thanks, [jaganz](https://github.com/jaganz)!)


 
