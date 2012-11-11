#!/usr/bin/ruby

require 'rubygems'	
require 'rbvmomi'
require 'pp'


filepath = "/tmp/vsphere/"

begin
	vim = RbVmomi::VIM.connect :host => ARGV[0], :user => ARGV[1], :password => ARGV[2], :insecure => true
rescue => exc
	p exc
	exit
end

#
# cennect datacenter
#
begin
	dc = vim.serviceInstance.find_datacenter
rescue => exc
	p exc
	exit
end

#
# get Host state
#

host = dc.hostFolder.children.first.host.grep(RbVmomi::VIM::HostSystem).each do |h|

	host = h.name.gsub(/:/,"-")
	begin
		hfile = open(filepath + "h_" + host, "w")
	rescue => exc
		p exc
		exit
	end
	hfile.print "host-Hostname:", h.name, "\n"
	hfile.print "host-Product:", h.summary.config.product.fullName, "\n"
	hfile.print "host-HardwareMode:", h.summary.hardware.model, "\n"
	hfile.print "host-CPUModel:", h.summary.hardware.cpuModel, "\n"
	hfile.print "host-CPUMHz:", h.summary.hardware.cpuMhz, "\n"
	hfile.print "host-CPUCore:", h.summary.hardware.numCpuCores, "\n"
	hfile.print "host-CPUUsage:", h.summary.quickStats.overallCpuUsage, "\n"
	hfile.print "host-TotalMemorySize:", h.summary.hardware.memorySize/1024/1024, "\n"
	hfile.print "host-MemoryUsage:", h.summary.quickStats.overallMemoryUsage, "\n"
	hfile.print "host-PowerState:", h.summary.runtime.powerState, "\n"
	hfile.print "host-MaintenanceMode:", h.summary.runtime.inMaintenanceMode, "\n"
  	hfile.print "host-Uptime:", h.summary.quickStats.uptime, "\n"
	hfile.close
end

#
# get Datastore status
#
datastore = dc.datastore.grep(RbVmomi::VIM::Datastore).each do |d|
	ds = d.name.gsub(/:/,"-")
	begin
		dfile = open(filepath + "d_" + ds, "w")
	rescue => exc
		p exc
		exit
	end
	dfile.print "ds-Name:", d.name, "\n"
	dfile.print "ds-Capacity:", d.summary.capacity, "\n"
	dfile.print "ds-FreeSpace:", d.summary.freeSpace, "\n"
	dfile.print "ds-VM:"
	vm = d.vm.grep(RbVmomi::VIM::VirtualMachine).each do |v|
		dfile.print "\"", v.name, "\"", " "
	end
	dfile.print "\n"
	dfile.close
end

#
# get VirtualMachin status
#
vs = dc.vmFolder.childEntity.grep(RbVmomi::VIM::VirtualMachine).each do |v|
	vm = v.name.gsub(/:/,"-")
	begin
		vfile = open(filepath + "v_" + vm, "w")
	rescue
		p exc
		exit
	end
	vfile.print "vm-Name:", v.name, "\n"
	vfile.print "vm-ESXi:", v.runtime.host.name, "\n"
	vfile.print "vm-powerState:", v.summary.runtime.powerState, "\n"
	vfile.print "vm-guestFullName:", v.summary.guest.guestFullName, "\n"
	vfile.print "vm-HostName:", v.summary.guest.hostName, "\n"
	vfile.print "vm-IPAddress:", v.summary.guest.ipAddress, "\n"
	vfile.print "vm-VMwareTools:", v.summary.guest.toolsStatus, "\n"
	vfile.print "vm-maxCpuUsage:", v.summary.runtime.maxCpuUsage, "\n"
	vfile.print "vm-numCpu:", v.summary.config.numCpu, "\n"
	vfile.print "vm-overallCpuUsage:", v.summary.quickStats.overallCpuUsage, "\n"
	vfile.print "vm-memorySizeMB:", v.summary.config.memorySizeMB, "\n"
	vfile.print "vm-hostMemoryUsage:", v.summary.quickStats.hostMemoryUsage, "\n"
	vfile.print "vm-guestMemoryUsage:", v.summary.quickStats.guestMemoryUsage, "\n"
	vfile.print "vm-UncommittedStorage:", v.summary.storage.uncommitted, "\n"
	vfile.print "vm-UsedStorage:", v.summary.storage.committed, "\n"
	vfile.print "vm-UnsharedStorage:", v.summary.storage.unshared, "\n"
	vfile.print "vm-Uptime:", v.summary.quickStats.uptimeSeconds, "\n"
	vfile.close
end

puts 0
