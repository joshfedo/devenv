# Mounts a directory from the host machine on the vm at the designated path using an NFS mount
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +mount_options+:: +Array+ additional mount options
def mount_nfs (conf, id, host_path, guest_path, mount_options: [])
  conf.vm.synced_folder host_path, guest_path, id: id, create: true, nfs_export: false, type: 'nfs',
    :nfs => { mount_options: mount_options }
end

# Binds location on guest machine from provided source to target
# Params:
# +conf+:: vagrant provisioning conf object
# +source_path+:: +String+ full path to directory on host machine
# +target_path+:: +String+ mount location on virtual machine
def mount_bind (conf, source_path, target_path)
  conf.vm.provision :shell, run: 'always' do |conf|
    conf.name = "binding #{source_path} -> #{target_path}"
    conf.inline = %-
      mkdir \-p #{source_path}
      mkdir \-p #{target_path}
      sudo mount \-o bind #{source_path} #{target_path}
    -
  end
end

# Mounts directory from the host machine on the vm at the designated path using default vmfs
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +mount_options+:: +Array+ additional mount options
def mount_vmfs (conf, id, host_path, guest_path, mount_options: [])
  if id.start_with?('-')
    throw "Error: mount_vmfs id may not begin with a hyphen, id of #{id} given"
  end
  
  FileUtils.mkdir_p host_path   # ensure path on host is present
  conf.vm.synced_folder host_path, guest_path, id: id, mount_options: mount_options
end

# Asserts that an entry is in the /etc/exports file to gaurantee that an NFS mount is possible
# Params:
# +host_path+:: +String+ path to required share directory
def assert_export (host_path)
  if File.exist?('/etc/exports') == false
    $stderr.puts "Error: /etc/exports does not exist. See /server/README.md for details"
    exit false
  end
  
  exports = File.readlines('/etc/exports')
  for line in exports
    if line.start_with?(host_path + '/ -alldirs')
      return true
    end
  end
  $stderr.puts "Error: /etc/exports is missing an entry for #{host_path}/. See /server/README.md for details"
  exit false
end
