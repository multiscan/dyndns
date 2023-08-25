class Record < ApplicationRecord
  before_destroy :destroy_gandi
  before_save :update_or_create_gandi

  def full_name
    "#{self.name}.#{Rails.application.credentials.domain}"
  end

  def gandi_name
    base=ENV.fetch('SUBDOMAIN')
    if base
      "#{self.name}.#{base}"
    else
      self.name
    end
  end

  def full_gandi_name
    base=ENV.fetch('SUBDOMAIN')
    if base
      "#{self.name}.#{base}.#{Rails.application.credentials.domain}"
    else
      self.full_name
    end
  end

  def check(possibly_new_ip)
    if self.ip == possibly_new_ip
      self.touch
    else
      self.ip = possibly_new_ip
      self.changed_at = DateTime.now()
      save
    end
  end

  private

  def update_or_create_gandi
    if self.new_record?
      puts "is a new record creating gandi"
      create_gandi
    else
      if self.ip_changed?
        puts "updating gandi"
        update_gandi 
      end
    end
  end

  def record_type()
    @record_type ||= begin
      if !!(self.ip =~ Resolv::IPv4::Regex)
        "A"
      elsif !!(self.ip =~ Resolv::IPv6::Regex)
        "AAAA"
      else
        "CNAME"
      end
    end
  end

  def gandi
    @gandi ||= GandiV5::LiveDNS::domain(Rails.application.credentials.domain)
  end

  def gandi_records
    @gandi_records ||= begin
      gandi.fetch_records(self.gandi_name)
    end
  end

  def gandi_values
    r = gandi_records.select {|r| r.type == record_type}.first
    r.nil? ? [] : r.values
  end

  # https://github.com/robertgauld/gandi_v5
  # https://rubydoc.info/github/robertgauld/gandi_v5/main
  # I assume that four our usecase, records always have one single value
  def create_gandi()
    return if Rails.env == "development"
    gv = gandi_values
    if gv.empty?
      res = gandi.add_record(self.gandi_name, self.record_type, self.ttl, self.ip)
      res == "DNS Record Created" || res == "A DNS Record already exists with same value"
    else
      update_gandi()
    end
  end

  def update_gandi()
    return if Rails.env == "development"
    i = [self.ip]
    unless i == gandi_values
      res = gandi.replace_records(i, name: gandi_name, type: record_type)
      raise "Failed to update record" unless res == "DNS Record Created"
    end
    true
  end

  def destroy_gandi()
    return if Rails.env == "development"
    gandi.delete_records(self.gandi_name)
  end
end
