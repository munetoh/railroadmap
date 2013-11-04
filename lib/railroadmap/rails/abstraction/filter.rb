# -*- coding: UTF-8 -*-
#
# Before_filters
#
# overall list
#   $abst_filter[classobj.name] = classobj
#
# within class
#   $list_filte[name] = [type, method_list]
#
#   type = all, except, only
#
#   add_class()
#     $list_filter = Hash.new
#   CommonBeforeFilterParser()
#     $list_filter[hoge] = [type, list]
#   add_def
#     filter list => state.before_filters[]
#   complete_filter()
#     Extract/Abstract filters
#
module Abstraction
  # base class for filter
  class Filter < Abstraction::Command
    def initialize
      super
      @dst = nil
      @guard = nil
    end
    attr_accessor :dst, :guard

    # callback
    def abstract_filter(state)
      $log.debug "abstract_filter() TODO #{state.id} #{@name}"
    end
  end
end
