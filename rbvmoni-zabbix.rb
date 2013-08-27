#!/usr/bin/ruby

require 'rubygems'
require 'zbxapi'
require 'logger'
require 'rbvmomi'
require 'fileutils'

def print_usage
  puts "usage: rbvmomi_zabbix.rb (vCenter Host) (vCenter Username) (vCenter Password) (Prefix Groups Name) (Zabbix URL)"
  exit
end

print_usage if ARGV.size != 5
vcHost = ARGV[0]
vcUser = ARGV[1]
vcPass = ARGV[2]
dsName = ARGV[3]
$zbxUrl = ARGV[4]


##################################
#User Defined Parameters
#Exclude Vmware Templates? (jaganz)
$includeVmwareTemplates = false
#Deprovisioning Method (delete host or move to deprovisioned host group?)
$EnableDeprovisioningHostGroup = true
$DEPROV_GROUP = "Deprovisioned Hosts"
#Zabbix Valid Login
$zuser = "Admin"
$zpass = "zabbix"
#Other Related Stuff
ESX_GROUP = "#{dsName} ESXi"
DS_GROUP = "#{dsName} Datastore"
VM_GROUP = "#{dsName} VirtualMachine"
ESX_TEMPLATE = "Template-vSphere-ESXi"
DS_TEMPLATE = "Template-vSphere-Datastore"
VM_TEMPLATE = "Template-vSphere-VM"
FILEPATH = "/tmp/vsphere"


################
# SCRIPT START #
################

class Zbx < ZabbixAPI

  def initialize()
    @user = $zuser
    @pass = $zpass
    begin
      @zbxapi = ZabbixAPI.new($zbxUrl).login(@user, @pass)
    rescue => exc
      p exc
      $log.error(exc)
      exit
    end
  end

  def send_zbx(zbxCmd, zbxHash)
    begin
      @zbxapi.raw_api(zbxCmd, zbxHash)
    rescue => exc
      p exc
      $log.error(exc)
      exit
    end
  end

  def search_zbxGroup(groupName)
    zbxHash = {
      :name => groupName
    }
    send_zbx("hostgroup.exists", zbxHash)
  end

  def create_zbxGroup(groupName)
    zbxHash = {
      :name => groupName
    }
    send_zbx("hostgroup.create", zbxHash)
  end

  def get_zbxGroupId(groupName)
    if search_zbxGroup(groupName)
      zbxHash = {
      :name => groupName
      }
      send_zbx("hostgroup.getobjects", zbxHash)[0]['groupid']
    else
      create_zbxGroup(groupName)['groupids'][0]
    end
  end

  def search_zbxTemplate(templateName)
    zbxHash = {
      :name => templateName
    }
    send_zbx("template.exists", zbxHash)
  end

  def get_zbxTemplateId(templateName)
    unless search_zbxTemplate(templateName)
      errmsg = "#{templateName} is not exist."
      $log.error(errmsg)
      abort(errmsg)
    end 
    @zbxapi.raw_api("template.getobjects", {
      :name => templateName
    })[0]['templateid']
  end

  def search_zbxHost(hostName)
    zbxHash = {
      :host => hostName
    }
    send_zbx("host.exists", zbxHash)
  end

  def create_zbxHost(hosts, groupName, templateName)
    @groupId = get_zbxGroupId(groupName)
    @templateId = get_zbxTemplateId(templateName)
    hosts.each {|host|
      zbxHash = {
        :host => host,
        :interfaces => [{
          :type => 1,
          :main => 1,
          :useip => 1,
          :ip => "127.0.0.1",
          :dns => "",
          :port => "10050"
          }],
        :groups => [{
          :groupid => @groupId
        }],
        :templates => [{
          :templateid => @templateId
        }]
      } unless search_zbxHost(host)
      send_zbx("host.create", zbxHash) 
    } 
  end

  def get_zbxHostId(hostName)
    zbxHash = {
      :host => hostName
    }
    send_zbx("host.getobjects", zbxHash)[0]['hostid']
  end

  def delete_zbxHost(hostName)
    zbxHash = {
      :hostid => get_zbxHostId(hostName)
    } if search_zbxHost(hostName)
    send_zbx("host.delete", zbxHash) if zbxHash
  end

  def deprov_zbxHost(hostName, deprovGroup)  
    if search_zbxGroup(deprovGroup) == false
      create_zbxGroup(deprovGroup)  
    end
    @deprovGroupid = get_zbxGroupId(deprovGroup)   
    zbxHash = {
      :hostid => get_zbxHostId(hostName),
      :groups => [{
        :groupid => @deprovGroupid 
      }],
      :status => 1
    } if search_zbxHost(hostName)
    send_zbx("host.update", zbxHash) if zbxHash
  end
end

class VSphere < RbVmomi::VIM
  def initialize(host, user, pass)
    @host = host
    @user = user
    @password = pass

    begin
      @vim = RbVmomi::VIM.connect :host => @host, :user => @user, :password => @password, :insecure => true
    rescue => exc
      p exc
      $log.error(exc)
      exit
    end

    begin
      @dc = @vim.serviceInstance.find_datacenter
    rescue => exc
      p exc
      $log.error(exc)
      exit
    end
  end


  def get_host_status(type)

    new_list = Array.new

    case type

    when "host"
      @dc.hostFolder.childEntity.each do |vmhost|
        vmhost.host.grep(RbVmomi::VIM::HostSystem).each do |stat|
          newname = stat.name.gsub(/:/,"-")
          stat_fileName = "h_#{newname}"
          new_list << newname unless File.exist?($filePath + stat_fileName)
          statData = {
            "host-Hostname"         => stat.name,
            "host-Product"          => stat.summary.config.product.fullName,
            "host-HardwareMode"     => stat.summary.hardware.model,
            "host-CPUModel"         => stat.summary.hardware.cpuModel,
            "host-CPUMHz"           => stat.summary.hardware.cpuMhz,
            "host-CPUCore"          => stat.summary.hardware.numCpuCores,
            "host-CPUUsage"         => stat.summary.quickStats.overallCpuUsage,
            "host-TotalMemorySize"  => stat.summary.hardware.memorySize/1024/1024,
            "host-MemoryUsage"      => stat.summary.quickStats.overallMemoryUsage,
            "host-PowerState"       => stat.summary.runtime.powerState,
            "host-MaintenanceMode"  => stat.summary.runtime.inMaintenanceMode,
            "host-Uptime"           => stat.summary.quickStats.uptime
          }
          writefile(stat_fileName, statData)
        end
        if new_list.length > 0
          unless defined?(@zbxapi)
            @zbxapi = Zbx.new
          end
          @zbxapi.create_zbxHost(new_list, ESX_GROUP, ESX_TEMPLATE)
        end
      end

    when "ds"
      @dc.datastore.grep(RbVmomi::VIM::Datastore).each do |stat|
        newname = stat.name.gsub(/:/,"-")
        stat_fileName = "d_#{newname}"
        new_list << newname unless File.exist?($filePath + stat_fileName)
        vm_list =[]
        stat.vm.grep(RbVmomi::VIM::VirtualMachine).each {|v| vm_list << v.name }
        statData = {
          "ds-Name" => stat.name,
          "ds-Capacity" => stat.summary.capacity,
          "ds-FreeSpace" => stat.summary.freeSpace,
          "ds-VM" => vm_list.join(', ')
        }
        writefile(stat_fileName, statData)
      end
      if new_list.length > 0
        unless defined?(@zbxapi)
          @zbxapi = Zbx.new
        end
        @zbxapi.create_zbxHost(new_list, DS_GROUP, DS_TEMPLATE)
      end

    when "vm"
      @dc.vmFolder.childEntity.grep(RbVmomi::VIM::VirtualMachine).each do |stat|
       if stat.summary.config.template != true || (stat.summary.config.template == true && includeVmwareTemplates == true ) #exclude templates (jaganz)
        newname = stat.name.gsub(/:/,"-")
        stat_fileName = "v_#{newname}"
        new_list << newname unless File.exist?($filePath + stat_fileName)
        statData = {
          "vm-Name" => stat.name,
          "vm-ESXi" => stat.runtime.host.name,
          "vm-powerState" => stat.summary.runtime.powerState,
          "vm-guestFullName" => stat.summary.guest.guestFullName,
          "vm-HostName" => stat.summary.guest.hostName,
          "vm-IPAddress" => stat.summary.guest.ipAddress,
          "vm-VMwareTools" => stat.summary.guest.toolsStatus,
          "vm-maxCpuUsage" => stat.summary.runtime.maxCpuUsage,
          "vm-numCpu" => stat.summary.config.numCpu,
          "vm-overallCpuUsage" => stat.summary.quickStats.overallCpuUsage,
          "vm-memorySizeMB" => stat.summary.config.memorySizeMB,
          "vm-hostMemoryUsage" => stat.summary.quickStats.hostMemoryUsage,
          "vm-guestMemoryUsage" => stat.summary.quickStats.guestMemoryUsage,
          "vm-UncommittedStorage" => stat.summary.storage.uncommitted,
          "vm-UsedStorage" => stat.summary.storage.committed,
          "vm-UnsharedStorage" => stat.summary.storage.unshared,
          "vm-Uptime" => stat.summary.quickStats.uptimeSeconds
        }
        writefile(stat_fileName, statData)
      end
      if new_list.length > 0
        unless defined?(@zbxapi)
          @zbxapi = Zbx.new
        end
        @zbxapi.create_zbxHost(new_list, VM_GROUP, VM_TEMPLATE)
      end
     end #exclude Templates
    end

    
  end

end

def writefile(fileName, data)
  begin
    statsFile = open($filePath + fileName, "w")
  rescue => exc
    p exc
    $log.error(exc)
    exit
  end
  data.each_pair {|key, value| statsFile.puts "#{key}:#{value}"}
  statsFile.close
end


#Manage Deprovisioning based on delta time of last updated stat files
def stats_file_age_check(time)
  Dir::glob($filePath + "*").each do |f|
    if Time.now - File.stat(f).mtime >= time
      /\A[vhd]_(.*)\z/ =~ File.basename(f)
      unless defined?(zbxapi)
        @zbxapi = Zbx.new
      end
      if $EnableDeprovisioningHostGroup == true
        if $DEPROV_GROUP.to_s.strip.length == 0
          log.error("Error in deprovisioning step: $EnableDeprovisioningHostGroup is activated but not DEPROV_GROUP is defined.")
          raise "$EnableDeprovisioningHostGroup is activated but DEPROV_GROUP is not defined."
        else
          @zbxapi.deprov_zbxHost($1, $DEPROV_GROUP)
          $log.info($1 + " deprovisioned (moved into deprovisioning group) on zabbix after " + time.to_s + " seconds without updates")
        end
      else
       $log.info($1 + " deprovisioned (deleted) on zabbix after " + time.to_s + " seconds without updates")
        @zbxapi.delete_zbxHost($1)
        File.delete(f)
      end
    end
  end
end

def stats_file_check(zbx_host, fileName)
  create_zbxHost(hosts, groupName, templateName) unless File.exist?(fileName)
end





$filePath = FILEPATH + "/stats/"
FileUtils.mkdir_p($filePath) unless File.exists?($filePath)
logPath = FILEPATH + "/logs/"
FileUtils.mkdir_p(logPath) unless File.exists?(logPath)
$log = Logger.new(logPath + 'rbvmoni-zabbix.log', 'weekly')


stats_file_age_check(3600 * 24)

ds = VSphere.new(vcHost, vcUser, vcPass)

ds.get_host_status("host")
ds.get_host_status("ds")
ds.get_host_status("vm")

puts 0
