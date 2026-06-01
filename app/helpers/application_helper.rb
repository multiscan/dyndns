# frozen_string_literal: true

module ApplicationHelper
  def nice_time(dt)
    dt.nil? ? "--" : "#{dt} (#{time_ago_in_words(dt)})"
  end
end
