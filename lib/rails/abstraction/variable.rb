
module Abstraction
  #############################################################################
  # Variables/ Models
  #   type           name
  #   ---------------------------------------------
  #   Model/DB => S_model#attribute   
  #   variable => S_model#variable    e.g. session, Devise
  #   ----------------------------------------------------------
  class Variable
    def initialize(domain, type, vtype)
      @domain = domain
      @type = type
      @vtype = vtype
      @filename = []
      @state = nil
      
      
      # link to the Model State
      @state = nil
      
      # Model - Mass Injection
      #  true  public
      #  false protected
      @attr_accessible = true
      
      @abstract = ''
      
            
      @id = 'S_' + @domain      
    end
    attr_accessor :id, :filename, :state, :attr_accessible, :state, :domain, :type, :abstract
    
    def print
      if $verbose > 1 then
        filename = @filename
      else
        filename = ''
      end
        
        
      if @attr_accessible then flag = '-'
      else                     flag = 'P'
      end
      
      puts "    #{@type.ljust(12)} #{flag} #{@domain.ljust(40)}  #{filename}"

    end
  end
end