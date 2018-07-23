require 'cloud/vsphere/logger'

module VSphereCloud
  class FileProvider
    include Logger

    def initialize(http_client:, vcenter_host:, client:, retryer: nil)
      @client = client
      @vcenter_host = vcenter_host
      @http_client = http_client
      @retryer = retryer || Retryer.new
    end

    def fetch_file_from_datastore(datacenter_name, datastore, path)
      # get the first host which is healthy
      host = datastore.host.detect do |host_mount|
        host = host_mount.key
        !host.runtime.in_maintenance_mode && host.runtime.power_state == 'poweredOn' && host.runtime.connection_state = 'connected'
      end.key

      url = "https://#{host.name}/folder/#{path}?" +
        "dsName=#{URI.escape(datastore.name)}"

      service_ticket = get_generic_service_ticket(url: url, method: 'httpGet')


      logger.info("Fetching file from #{url}...")
      response = do_request(request_type: 'GET', url: url, allow_not_found: true, headers: {'Content-Type' => 'application/octet-stream', 'Cookie' => "vmware_cgi_ticket=#{service_ticket.id}"})

      if response.nil?
        logger.info("Could not find file at #{url}.")
        nil
      else
        logger.info('Successfully downloaded file.')
        response.body
      end
    end

    def upload_file_to_datastore(datastore, path, contents)
      # get the first host which is healthy
      host = datastore.mob.host.detect do |host_mount|
        host = host_mount.key
        !host.runtime.in_maintenance_mode && host.runtime.power_state == 'poweredOn' && host.runtime.connection_state = 'connected'
      end.key

      url = "https://#{host.name}/folder/#{path}?" +
        "dsName=#{URI.escape(datastore.name)}"

      service_ticket = get_generic_service_ticket(url: url, method: 'httpPut')

      logger.info("Uploading file to #{url}...")

      do_request(request_type: 'PUT', url: url, body: contents,
        headers: { 'Content-Type' => 'application/octet-stream', 'Cookie' => "vmware_cgi_ticket=#{service_ticket.id}"})
      logger.info('Successfully uploaded file.')
    end

    def upload_file_to_url(url, body, headers)
      logger.info("Uploading file to #{url}...")

      do_request(request_type: 'POST', url: url, body: body, headers: headers)
      logger.info('Successfully uploaded file.')
    end

    private

    def get_generic_service_ticket(url:, method:)
      session_manager = @client.service_content.session_manager
      session_spec = VimSdk::Vim::SessionManager::HttpServiceRequestSpec.new
      session_spec.method = method
      session_spec.url = url

      logger.info("Acquiring generic service ticket for URL: #{url} and Method: #{method}")
      session_manager.acquire_generic_service_ticket(session_spec)
    end

    def do_request(request_type:, url:, body: nil, headers: {}, allow_not_found: false)
      base_headers = {}
      unless body.nil?
        if body.is_a?(File)
          content_length = body.size
        elsif body.respond_to?(:bytesize)
          content_length = body.bytesize
        else
          content_length = body.length
        end
        base_headers = { 'Content-Length' => content_length }
      end
      req_headers = base_headers.merge(headers)

      case request_type
      when 'GET'
        make_request = lambda { @http_client.get(url, req_headers) }
      when 'POST'
        make_request = lambda { @http_client.post(url, body, req_headers) }
      when 'PUT'
        make_request = lambda { @http_client.put(url, body, req_headers) }
      else
        raise "Invalid request type: #{request_type}."
      end

      response = @retryer.try do
        resp = make_request.call

        if resp.code == 404 && allow_not_found
          [nil, nil]
        elsif resp.code >= 400
          err = "Could not transfer file '#{url}', received status code '#{resp.code}'"
          logger.warn(err)
          [nil, err]
        else
          [resp, nil]
        end
      end

      response
    end
  end
end
