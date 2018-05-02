require 'rspec'
require 'integration/spec_helper'
require 'cloud/vsphere/cpi_extension'

describe '#add cpi extension' do
  subject(:cpi) do
    VSphereCloud::Cloud.new(cpi_options('default_disk_type' => 'thin'))
  end

  let(:network_spec) do
    {
      'static' => {
        'ip' => "169.254.1.#{rand(4..254)}",
        'netmask' => '255.255.254.0',
        'cloud_properties' => { 'name' => @vlan },
        'default' => ['dns', 'gateway'],
        'dns' => ['169.254.1.2'],
        'gateway' => '169.254.1.3'
      }
    }
  end
  let(:vm_type) do
    {
      'ram' => 512,
      'disk' => 2048,
      'cpu' => 1,
    }
  end



  context 'when it creates a stemcell on vsphere' do
    it 'adds an extension to vcenter and attaches stemcell to that extension' do
      begin
        stemcell_id = upload_stemcell(cpi)
        stemcell_vm = @cpi.client.find_vm_by_name(@cpi.datacenter.mob, stemcell_id)
        expect(stemcell_vm.config.managed_by.extension_key).to eql(VSphereCloud::VCPIExtension::DEFAULT_VSPHERE_CPI_EXTENSION_KEY)
      ensure
        cpi.delete_stemcell(stemcell_id)
      end
    end
  end

  context 'when it creates a vm on vsphere' do
    after do
      cpi.delete_vm(@vm_cid) if @vm_cid
    end

    it 'adds vm to the default cpi extension' do
      @vm_cid = cpi.create_vm(
        'agent-007',
        @stemcell_id,
        vm_type,
        network_spec,
        [],
        {'key' => 'value'}
      )
      vm = @cpi.client.find_vm_by_name(@cpi.datacenter.mob, @vm_cid)
      expect(vm.config.managed_by.extension_key).to eql(VSphereCloud::VCPIExtension::DEFAULT_VSPHERE_CPI_EXTENSION_KEY)
    end
  end

  context 'when extension does not exist and it creates a vm on vsphere' do
    before do
      begin
        cpi.client.service_content.extension_manager.unregister_extension(VSphereCloud::VCPIExtension::DEFAULT_VSPHERE_CPI_EXTENSION_KEY)
      rescue
      end
    end

    after do
      cpi.delete_vm(@vm_cid) if @vm_cid
    end

    it 'does not add VM to the CPI extension' do
      @vm_cid = cpi.create_vm(
        'agent-007',
        @stemcell_id,
        vm_type,
        network_spec,
        [],
        {'key' => 'value'}
      )
      vm = @cpi.client.find_vm_by_name(@cpi.datacenter.mob, @vm_cid)
      expect(vm.config.managed_by).to be_nil
    end
  end
end