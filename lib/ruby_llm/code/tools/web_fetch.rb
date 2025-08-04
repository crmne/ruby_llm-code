# frozen_string_literal: true

module RubyLLM::Code
  module Tools
    class WebFetch < BaseTool
      def name
        "WebFetch"
      end

      description "Fetches content from a URL"
      
      param :url, desc: "URL to fetch"
      param :headers, desc: "Optional HTTP headers as key=value pairs", required: false
      
      def execute(url:, headers: {})
        uri = URI.parse(url)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 10
        
        request = Net::HTTP::Get.new(uri)
        headers.each { |k, v| request[k] = v }
        
        response = http.request(request)
        
        content = response.body
        
        # Truncate very large responses
        if content.length > 50_000
          content = format_output(content[0...50_000], truncated: true)
        end
        
        {
          url: url,
          status: response.code.to_i,
          content_type: response["content-type"],
          content: content,
          size: response.body.bytesize
        }
      rescue => e
        { error: "Failed to fetch URL: #{e.message}" }
      end
    end
  end
end