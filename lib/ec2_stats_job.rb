require "ec2_stats_job/version"

begin
  require 'aws-sdk-ec2' # v3 +
rescue LoadError
  require 'aws-sdk-v1' # v1
end

require 'json'
require 'yaml'
require 'active_job'

# Silently fail if ohai gem is unavailable or we are not on ec2
# begin
#   require 'ohai'
#   exit unless system("ohai ec2 >/dev/null 2>&1")
# rescue LoadError
# end

# Require one HTTP client library
begin
  require 'faraday'
rescue LoadError
  begin
    require 'net/http'
  rescue LoadError
    require 'httparty'
  end
end

module Ec2StatsJob
  class Error < StandardError; end

  class Job < ActiveJob::Base
    def perform(app_username)
      Client.new(app_username).ec2_stats_update
    end
  end

  class Client
    def initialize(app_username)
      @app_username = app_username
      if File.exist?("/opt/cloud/aws.yml")
        config = YAML.load_file("/opt/cloud/aws.yml")
        AWS.config(config)
      else
        AWS.config
      end
    end

    def ec2_stats_update
      inst = ec2_instance
      s=`uptime`
      inst.tags["top:full-uptime"] = s.strip
      inst.tags["top:load-avg"] = s.split(/average: /).last.strip
      inst.tags["top:last-upd"] = s.split(/ up/).first.strip
      inst.tags["top:app-user-mem"] = `ps auxww | grep ^#{@app_username} | awk '{sum += $6 } END { print sum }'`
      inst.tags["top:free-ram"] = `free -m | grep cache: | rev | awk '{print $1}' | rev`
      inst.tags["top:free-swap"] = `free -m | grep Swap: | rev | awk '{print $1}' | rev`
      inst.tags["top:disk-use"] = `df -h  | awk {'print $5'} | sort -nu | tail -n 1`
    end

    def ec2_instance
      @ec2_instance ||= begin
        if defined?(AWS::VERSION) && BigDecimal(AWS::VERSION.split('.')[0..1].join('.')) < 2
          AWS::EC2.new.regions[region].instances[instance_id]
        elsif defined?(Aws::CORE_GEM_VERSION) && BigDecimal(Aws::CORE_GEM_VERSION.split('.')[0..1].join('.')) > 3
          ENV['AWS_REGION'] = region
          Aws::EC2::Instance.new(id: instance_id)
        else
          raise Error, "unsupported aws-sdk version number. please open an issue with your version"
        end
      end
    end

    def region
      @region ||= ec2_info["region"]
    end

    def instance_id
      @instance_id ||= ec2_info["instanceId"]
    end

    def ec2_info
      @ec2_info ||= http_get(EC2_INFO_URL)
    end

    private

    EC2_INFO_URL = "http://169.254.169.254/latest/dynamic/instance-identity/document"

    def http_get(url)
      if defined?(Faraday)
        JSON.parse(Faraday.new(url).get.body)
      elsif defined?(Net::HTTP)
        JSON.parse(Net::HTTP.get(URI.parse(url)))
      elsif defined?(Httparty)
        HTTParty.get(url).parsed_response
      else
        raise Error, "missing compatible http library" # Should actually crash earlier (LoadError line 21)
      end
    end
  end
end
