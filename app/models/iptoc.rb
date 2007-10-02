require 'ipaddr'
class Iptoc < ActiveRecord::Base
  def self.find_by_ip_address(ip_address)
    ip = IPAddr.new(ip_address)
    find(:first, :conditions => ["IP_FROM <= ? AND IP_TO >= ?", ip.to_i, ip.to_i])
  end
end
