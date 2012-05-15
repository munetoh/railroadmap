
module Abstraction
  #############################################################################
  # Subvertex/State/Station
  #
  #   type           name
  #   ---------------------------------------------
  #   controller     C_model#action
  #   model          M_model          --- Variable(attribute)
  #   view           V_model#action
  #   ----------------------------------------------
  #  
  #   hoge/hoge  => hoge:hoge
  #
  class State
    def initialize(domain, type)
      @domain = domain
      @type = type
      @filename = []
      @variables = []
     
      # Set ID (=key)
      case @type
      when 'controller'
        @id = 'C_' + @domain
      when 'model'
        @id = 'M_' + @domain
      when 'view'
        @id = 'V_' + @domain
      else
        @id = 'NA_' + @domain
      end
      
      # C
      @is_private = false
      @is_protected = false
      @ssl_required = false
      @ssl_allowed  = false
      @is_authenticated = false
      
      @controller_class = nil
      @base_controller_class = nil
      
      # root block
      @block_root = Block.new
      @block_root.type = 'root'
      @block_root.id = @id + '_R'
      $block = @block_root  # set current block,  => root
      
      # HTML5 state diagram
      @is_VV_src = false
      @is_VV_dst = false
      @is_CC_src = false
      @is_CC_dst = false   
    end
    attr_accessor :id, :type, :domain, :filename, :variables, 
    :is_private, :is_protected, :ssl_required, :ssl_allowed, :is_authenticated,
    :controller_class, :base_controller_class,
    :is_VV_src, :is_VV_dst, :is_CC_src, :is_CC_dst
    
    def add_variable(v)
      @variables << v
    end
    
    def complete_condition(guard2abst, guard2abst_byblk)
      @block_root.complete_condition(nil, nil, guard2abst, guard2abst_byblk)
    end
    
    
    def print
      if $verbose > 1 then
        filename = @filename
      else
        filename = ''
      end
      
      flag =''
      if @is_authenticated then flag += 'A'
      else                      flag += '-'  
      end
            
      if @ssl_required then flag += 'S'
      else                  flag += '-'  
      end

      if @ssl_allowed then  flag += 's'
      else                  flag += '-'  
      end      
          
      if @is_private   then  flag += 'p'
      else                   flag += '-'
      end      
      
      if @is_protected then  flag += 'P'
      else                   flag += '-'
      end
            
      puts "    #{@type.ljust(12)} #{flag} #{@domain.ljust(40)}  #{@controller_class} < #{@base_controller_class} #{filename}"
    end
    
    def print_block
       @block_root.print(0)
    end
    
  end

end