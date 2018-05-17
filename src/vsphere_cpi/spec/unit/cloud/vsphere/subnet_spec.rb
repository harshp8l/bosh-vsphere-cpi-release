require 'spec_helper'

module VSphereCloud
  describe Subnet do
    subject(:subnet) { Subnet.build(nsxt_provider, subnet_definition, logger) }
    let(:logger) { instance_double('Bosh::Cpi::Logger', info: nil, debug: nil) }
    let(:nsxt_provider) { instance_double(VSphereCloud::NSXTProvider) }
    let(:subnet_definition) { {
      'range' => range,
      'gateway' => gateway,
      'cloud_properties' => cloud_props }
    }
    let(:cloud_props) { {
          'edge_cluster_id' => edge_cluster_id,
          't0_router_id' => t0_router_id,
          't1_name' => 'router-name',
          'transport_zone_id' => transport_zone_id,
          'switch_name' => 'switch-name',
      }
    }
    let(:range) { '192.168.111.0/24' }
    let(:gateway) {'192.168.111.1'}
    let(:t0_router_id) { 't0-router-id' }
    let(:transport_zone_id) { 'zone-id' }
    let(:edge_cluster_id) { 'cluster_id' }

    context 'when invalid subnet_definition is given' do
      context 'when cloud_properties is empty' do
        let(:cloud_props) { '' }

        it 'raises an error' do
          expect{ subnet }.to raise_error('cloud_properties must be provided')
        end
      end
      context 'when no cloud_properties given' do
        let(:subnet_definition) { {
            'range' => '192.168.111.0/24',
            'gateway' => '192.168.111.1'}
        }

        it 'raises an error' do
          expect{ subnet }.to raise_error('cloud_properties must be provided')
        end
      end

      context 'when t0_router_id is not provided' do
        let(:cloud_props) { {
            'edge_cluster_id' => 'cluster_id',
            'transport_zone_id' => 'zone-id',
        } }

        it 'raises an error' do
          expect{ subnet }.to raise_error('t0_router_id cloud property can not be empty')
        end
      end
      context 'when t0_router_id is empty' do
        let(:t0_router_id) { '' }
        it 'raises an error' do
          expect{ subnet }.to raise_error('t0_router_id cloud property can not be empty')
        end
      end

      context 'when edge_cluster_id is not provided' do
        let(:cloud_props) { {
            't0_router_id' => t0_router_id,
            'transport_zone_id' => transport_zone_id,
        } }
        it 'raises an error' do
          expect{ subnet }.to raise_error('edge_cluster_id cloud property can not be empty')
        end
      end
      context 'when edge_cluster_id is empty' do
        let(:edge_cluster_id) { '' }

        it 'raises an error' do
          expect{ subnet }.to raise_error('edge_cluster_id cloud property can not be empty')
        end
      end

      context 'when transport_zone_id is not provided' do
        let(:cloud_props) { {
            'edge_cluster_id' => edge_cluster_id,
            't0_router_id' => t0_router_id
        } }
        it 'raises an error' do
          expect{ subnet }.to raise_error('transport_zone_id cloud property can not be empty')
        end
      end
      context 'when transport_zone_id is empty' do
        let(:transport_zone_id) { '' }

        it 'raises an error' do
          expect{ subnet }.to raise_error('transport_zone_id cloud property can not be empty')
        end
      end

      context 'when range is empty' do
        let(:range) { '' }
        it 'raises an error' do
          expect{ subnet }.to raise_error('Incorrect subnet definition. Proper CIDR block range must be given')
        end
      end

      context 'when range is not provided' do
        let(:subnet_definition) { {
            'gateway' => '192.168.111.1',
            'cloud_properties' => cloud_props }
        }
        it 'raises an error' do
          expect{ subnet }.to raise_error('Incorrect subnet definition. Proper CIDR block range must be given')
        end
      end

      context 'when incorrect range is provided' do
        let(:range) { '192.168.111.111/33' }
        it 'raises an error' do
          expect{ subnet }.to raise_error(/Netmask, 33, is out of bounds for IPv4/)
        end
      end

      context 'when gateway is empty' do
        let(:gateway) { '' }
        it 'raises an error' do
          expect{ subnet }.to raise_error('Incorrect subnet definition. Proper gateway must be given')
        end
      end

      context 'when gateway is not provided' do
        let(:subnet_definition) { {
            'range' => range,
            'cloud_properties' => cloud_props }
        }

        it 'raises an error' do
          expect{ subnet }.to raise_error('Incorrect subnet definition. Proper gateway must be given')
        end
      end

      context 'when incorrect gateway is provided' do
        let(:gateway) { '192.168.111.111/31' }
        it 'raises an error' do
          expect{ subnet }.to raise_error('Incorrect subnet definition. Proper gateway must be given')
        end
      end
    end

    describe '#create_infrastructure' do
      let(:logical_switch) { instance_double(NSXT::LogicalSwitch,
                                             :id => 'switch-id',
                                             :display_name => 'switch-name') }
      let(:t1_router) { instance_double(NSXT::LogicalRouter,
                                        id: 't1-router-id',
                                        display_name: 'router-name' ) }

      it 'creates T1 router and attaches it to T0, creates logical switch and attaches it to T1' do
        expect(nsxt_provider).to receive(:create_t1_router)
          .with('cluster_id', 'router-name').and_return(t1_router)
        expect(nsxt_provider).to receive(:enable_route_advertisement)
          .with('t1-router-id')
        expect(nsxt_provider).to receive(:attach_t1_to_t0)
          .with('t0-router-id', 't1-router-id')
        expect(nsxt_provider).to receive(:create_logical_switch)
          .with('zone-id', 'switch-name').and_return(logical_switch)
        expect(nsxt_provider).to receive(:attach_switch_to_t1)
          .with('switch-id', 't1-router-id', instance_of(NSXT::IPSubnet))
        result = subnet.create_infrastructure
        expect(result.id).to eq('switch-id')
        expect(result.display_name).to eq('switch-name')
      end

      context 'when optional params are not provided' do
        let(:subnet_definition) { {
            'range' => '192.168.111.0/24',
            'gateway' => '192.168.111.1',
            'cloud_properties' => {
                'edge_cluster_id' => 'cluster_id',
                't0_router_id' => 't0-router-id',
                'transport_zone_id' => 'zone-id',
            } } }
        let(:logical_switch) { instance_double(NSXT::LogicalSwitch,
                                               :id => 'switch-id',
                                               :display_name => 'switch-id') }
        let(:t1_router) { instance_double(NSXT::LogicalRouter,
                                          id: 't1-router-id',
                                          display_name: 't1-router-id' ) }
        it 'creates T1 router and attaches it to T0, creates logical switch and attaches it to T1' do
          expect(nsxt_provider).to receive(:create_t1_router)
             .with('cluster_id', nil).and_return(t1_router)
          expect(nsxt_provider).to receive(:enable_route_advertisement)
             .with('t1-router-id')
          expect(nsxt_provider).to receive(:attach_t1_to_t0)
             .with('t0-router-id', 't1-router-id')
          expect(nsxt_provider).to receive(:create_logical_switch)
             .with('zone-id', nil).and_return(logical_switch)
          expect(nsxt_provider).to receive(:attach_switch_to_t1)
             .with('switch-id', 't1-router-id', instance_of(NSXT::IPSubnet))

          result = subnet.create_infrastructure
          expect(result.id).to eq('switch-id')
          expect(result.display_name).to eq('switch-id')
        end
      end

      context 'when NSXT API returns an error' do
        before do
          allow(logger).to receive(:error)
        end

        context 'when failed to enable_route_advertisement' do
          it 'deletes created router' do
            expect(nsxt_provider).to receive(:create_t1_router)
               .with('cluster_id','router-name').and_return(t1_router)
            expect(nsxt_provider).to receive(:enable_route_advertisement)
               .with('t1-router-id').and_raise('Some nsxt error')
            expect(nsxt_provider).to receive(:delete_t1_router)
               .with('t1-router-id')
            expect { subnet.create_infrastructure }
                .to raise_error(/Failed to create subnet/)
          end
        end
        context 'when failed to attach_t1_to_t0' do
          it 'deletes created router' do
            expect(nsxt_provider).to receive(:create_t1_router)
               .with('cluster_id','router-name').and_return(t1_router)
            expect(nsxt_provider).to receive(:enable_route_advertisement)
               .with('t1-router-id')
            expect(nsxt_provider).to receive(:attach_t1_to_t0)
               .with('t0-router-id', 't1-router-id').and_raise('Some nsxt error')
            expect(nsxt_provider).to receive(:delete_t1_router)
               .with('t1-router-id')
            expect { subnet.create_infrastructure }
                .to raise_error(/Failed to create subnet/)
          end
        end
        context 'when failed to attach_switch_to_t1' do
          it 'deletes created router and switch' do
            expect(nsxt_provider).to receive(:create_t1_router)
               .with('cluster_id','router-name').and_return(t1_router)
            expect(nsxt_provider).to receive(:enable_route_advertisement)
               .with('t1-router-id')
            expect(nsxt_provider).to receive(:attach_t1_to_t0)
               .with('t0-router-id', 't1-router-id')
            expect(nsxt_provider).to receive(:create_logical_switch)
               .with('zone-id', 'switch-name').and_return(logical_switch)
            expect(nsxt_provider).to receive(:attach_switch_to_t1)
               .and_raise('Some nsxt error')

            expect(nsxt_provider).to receive(:delete_t1_router)
               .with('t1-router-id')
            expect(nsxt_provider).to receive(:delete_logical_switch)
               .with('switch-id')
            expect {subnet.create_infrastructure }
                .to raise_error(/Failed to create subnet/)
          end
        end
      end
    end
  end
end