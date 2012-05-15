#
# CSRF
#
# $protect_from_forgery
#
module Rails
  class CSRF
    def initialize
    end
    
    def add_variable
      p = Abstraction::Parser::AstParser.new
      p.add_variable('layout', 'layout#csrf_token', 'string', 'model/dummy.rb')
      
      $map_variable = Hash.new if $map_variable == nil
      $map_variable['layout#csrf_token'] = ['string','csrf_token']
      
      # TODO B expression
      # TOKEN = {good,bad}
      $map_bset_types = Hash.new if $map_bset_types == nil
      $map_bset_types['csrf_token'] = 'TOKEN'
      
      $log.info "Added variables, layout#csrf_token for CSRF. "
    end
  end
end