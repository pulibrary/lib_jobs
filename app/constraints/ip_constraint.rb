require 'ipaddr'

class IpConstraint
  def initialize
    @allowed_ips = LibJobs.config[:staff_allowed_ips]&.split(" ").map { |ip| IPAddr.new(ip) }
  end

  def matches?(request)
    remote_ip = IPAddr.new(request.remote_ip)
    @allowed_ips.any? { |ip| ip.include?(remote_ip) }
  end
end
