module ApplicationHelper
  def nice_time(dt)
    dt.nil? ? "--" : "#{dt.to_s} (#{time_ago_in_words(dt)})"
  end

end
