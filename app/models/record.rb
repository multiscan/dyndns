class Record < ApplicationRecord
  before_destroy :destroy_gandi
  before_save :update_or_create_gandi

  def full_name
    self.name << "." << Rails.application.credentials.domain
  end

  # def check!(possibly_new_ip)
  #   if self.ip == possibly_new_ip
  #     self.touch
  #   else
  #     self.ip = possibly_new_ip
  #     save!
  #   end
  # end

 private

  def update_or_create_gandi
    if self.new_record?
      puts "is a new record creating gandi"
      # create_gandi
    else
      if self.ip_changed?
        puts "updating gandi"
        # update_gandi 
      end
    end
  end

  # https://github.com/robertgauld/gandi_v5
  # https://rubydoc.info/github/robertgauld/gandi_v5/main
  
  def create_gandi()
    d = GandiV5::LiveDNS::domain(Rails.application.credentials.domain)
    res = d.add_record(self.name, "A", self.ttl, self.ip)
    res == "DNS Record Created" || res == "A DNS Record already exists with same value"
  end

  def update_gandi()
    d = GandiV5::LiveDNS::domain(Rails.application.credentials.domain)
    # r = d.fetch_records("lth", "A").first
    r = d.fetch_records("lth").select{|r| r.a?}.first
    raise "Failed to fetch record from Gandi" unless r
    i = [self.ip]
    unless i == r.values
      res = d.replace_records(i, name: self.name, type: "A")
      raise "Failed to update record" unless res == "DNS Record Created"
    end
    true
  end

  def destroy_gandi()
    d = GandiV5::LiveDNS::domain(Rails.application.credentials.domain)
    d.delete_records(self.name)
  end
end
