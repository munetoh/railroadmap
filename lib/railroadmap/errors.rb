# -*- coding: UTF-8 -*-
# Class to hold all errors
#
# severity
#   1  Model has been fixed by local config
#   2  Wrong model => can be fixed by local config
#   3  Wrong model => cannot fixed, Update the RailroadMap
# message
# remidiation
class Errors
  # init
  def initialize
    @errors = {}
    @count = 0
    @severity1_count = 0
    @severity2_count = 0
    @severity3_count = 0
  end
  attr_accessor :errors, :count, :severity1_count, :severity2_count, :severity3_count

  # Add new error
  # e : hash
  def add(e)
    e['id'] = @count
    key = format("RRME%04d", @count)
    @count += 1
    @severity1_count += 1 if e['severity'] == 1
    @severity2_count += 1 if e['severity'] == 2
    @severity3_count += 1 if e['severity'] == 3
    @errors[key] = e
  end

  def size
    return @errors.size
  end
end
