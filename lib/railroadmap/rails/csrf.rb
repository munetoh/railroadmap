# -*- coding: UTF-8 -*-
# CSRF
#
# $protect_from_forgery
#
module Rails
  # CSRF check
  class CSRF
    def initialize
      # set unknown => command => enable
      $protect_from_forgery = 'unknown'
    end

    def add_variable
      p = Abstraction::Parser::AstParser.new
      v = p.add_variable('layout', 'layout#csrf_token', 'string', 'model/dummy.rb')
      v.origin = 'auto'
      $map_variable = {} if $map_variable.nil?
      $map_variable['layout#csrf_token'] = ['string', 'csrf_token']
      # TODO: B expression
      # TOKEN = {good,bad}
      $map_bset_types = {} if $map_bset_types.nil?
      $map_bset_types['csrf_token'] = 'TOKEN'
      $log.info "Added variables, layout#csrf_token for CSRF. "
    end
  end
end
