# frozen_string_literal: true

class Record < ApplicationRecord
  before_save :update_or_create_gandi
  before_destroy :destroy_gandi

  def full_name
    "#{name}.#{Rails.application.credentials.domain}"
  end

  def gandi_name
    base = ENV.fetch('SUBDOMAIN')
    if base
      "#{name}.#{base}"
    else
      name
    end
  end

  def full_gandi_name
    base = ENV.fetch('SUBDOMAIN')
    if base
      "#{name}.#{base}.#{Rails.application.credentials.domain}"
    else
      full_name
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  def check(possibly_new_ip)
    if ip == possibly_new_ip
      touch
    else
      self.ip = possibly_new_ip
      self.changed_at = DateTime.now
      save
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  private

  def update_or_create_gandi
    if new_record?
      Rails.logger.debug "is a new record creating gandi"
      create_gandi
    elsif ip_changed?
      Rails.logger.debug "updating gandi"
      update_gandi
    end
  end

  def record_type
    @record_type ||= if !(ip =~ Resolv::IPv4::Regex).nil?
                       "A"
                     elsif !(ip =~ Resolv::IPv6::Regex).nil?
                       "AAAA"
                     else
                       "CNAME"
                     end
  end

  def gandi
    @gandi ||= GandiV5::LiveDNS.domain(Rails.application.credentials.domain)
  end

  def gandi_records
    @gandi_records ||= gandi.fetch_records(gandi_name)
  end

  def gandi_values
    r = gandi_records.select { |r| r.type == record_type }.first
    r.nil? ? [] : r.values
  end

  # https://github.com/robertgauld/gandi_v5
  # https://rubydoc.info/github/robertgauld/gandi_v5/main
  # I assume that four our usecase, records always have one single value
  def create_gandi
    return if Rails.env.development?

    gv = gandi_values
    if gv.empty?
      res = gandi.add_record(gandi_name, record_type, ttl, ip)
      ["DNS Record Created", "A DNS Record already exists with same value"].include?(res)
    else
      update_gandi
    end
  end

  def update_gandi
    return if Rails.env.development?

    i = [ip]
    unless i == gandi_values
      res = gandi.replace_records(i, name: gandi_name, type: record_type)
      raise "Failed to update record" unless res == "DNS Record Created"
    end
    true
  end

  def destroy_gandi
    return if Rails.env.development?

    gandi.delete_records(gandi_name)
  end
end
