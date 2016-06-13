require 'spec_helper'

module VSphereCloud
  describe VCenterClient do
    describe "#find_disk" do

      before do
        @disk_cid = "disk-#{SecureRandom.uuid}"

        @client, @datacenter, @datastore, @disk_folder = setup

        @disk = @client.create_disk(@datacenter.mob, @datastore, @disk_cid, @disk_folder, 128, Resources::PersistentDisk::DEFAULT_DISK_TYPE)
      end

      after do
        @client.delete_disk(@datacenter.mob, @disk.path)
      end

      it "returns the disk if it exists" do
        disk = @client.find_disk(@disk_cid, @datastore, @disk_folder)

        expect(disk.cid).to eq(@disk_cid)
        expect(disk.size_in_mb).to eq(128)
      end

      it "returns nil when the disk can't be found" do
        disk = @client.find_disk("not-the-#{@disk_cid}", @datastore, @disk_folder)

        expect(disk).to be_nil
      end

      it "returns nil when the disk folder doesn't exit" do
        disk = @client.find_disk(@disk_cid, @datastore, "the-wrong-disk-folder")

        expect(disk).to be_nil
      end
    end

    def setup
      host = ENV.fetch('BOSH_VSPHERE_CPI_HOST')
      user = ENV.fetch('BOSH_VSPHERE_CPI_USER')
      password = ENV.fetch('BOSH_VSPHERE_CPI_PASSWORD')
      disk_folder = ENV.fetch('BOSH_VSPHERE_CPI_DISK_PATH', 'ACCEPTANCE_BOSH_Disks')
      datacenter_name = ENV.fetch('BOSH_VSPHERE_CPI_DATACENTER', 'BOSH_DC')
      vm_folder = ENV.fetch('BOSH_VSPHERE_CPI_VM_FOLDER', 'ACCEPTANCE_BOSH_VMs')
      template_folder = ENV.fetch('BOSH_VSPHERE_CPI_TEMPLATE_FOLDER', 'ACCEPTANCE_BOSH_Templates')
      ephemeral_datastore_pattern = Regexp.new(ENV.fetch('BOSH_VSPHERE_CPI_DATASTORE_PATTERN', 'jalapeno'))
      persistent_datastore_pattern = Regexp.new(ENV.fetch('BOSH_VSPHERE_CPI_PERSISTENT_DATASTORE_PATTERN', 'jalapeno'))
      cluster_name = ENV.fetch('BOSH_VSPHERE_CPI_CLUSTER', 'BOSH_CL')
      resource_pool_name = ENV.fetch('BOSH_VSPHERE_CPI_RESOURCE_POOL', 'ACCEPTANCE_RP')

      cluster_configs = {cluster_name => ClusterConfig.new(cluster_name, {'resource_pool' => resource_pool_name})}
      logger = Logger.new(StringIO.new(""))

      client = VCenterClient.new("https://#{host}/sdk/vimService", logger: logger)
      client.login(user, password, 'en')

      cluster_provider = Resources::ClusterProvider.new({
        datacenter_name: datacenter_name,
        mem_overcommit: 1.0,
        client: client,
        logger: logger,
      })
      datacenter = Resources::Datacenter.new({
          client: client,
          use_sub_folder: false,
          vm_folder: vm_folder,
          template_folder: template_folder,
          name: datacenter_name,
          disk_path: disk_folder,
          ephemeral_pattern: ephemeral_datastore_pattern,
          persistent_pattern: persistent_datastore_pattern,
          clusters: cluster_configs,
          cluster_provider: cluster_provider,
          logger: logger,
        })

      persistent_datastores = datacenter.select_datastores(persistent_datastore_pattern).values
      return client, datacenter, persistent_datastores.first, disk_folder
    end
  end
end
