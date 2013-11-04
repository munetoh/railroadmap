# -*- coding: UTF-8 -*-

module Abstraction
  #############################################################################
  # Variables/ Models
  #   type           name
  #   ---------------------------------------------
  #   Model/DB => S_model#attribute
  #   variable => S_model#variable    e.g. session, Devise
  #   ----------------------------------------------------------
  class Variable # < Abstraction::Policy
    def initialize(domain, type, vtype)  # TODO: somain => model, attribute
      super()

      @domain = domain
      @type = type
      ma = @domain.split('#')

      @type = type  # controller model view
      if type == 'model' || type == 'code' || type == 'devise' # TODO: devise - deprecated
        if ma.size == 2
          @model = ma[0].singularize
          @attribute = ma[1]
        else
          $log.error "initialize() domain=#{domain} ma=#{ma} type=#{type}"
          @model = nil
          @attribute = 'TBD'
        end
      else
        # !model
        $log.error "initialize() domain=#{domain} ma=#{ma} type=#{type}"
        @model = domain
        @attribute = 'TBD'  # TODO
      end

      @vtype = vtype
      @filename = []
      @state = nil
      @origin = 'unknown'  # Code/Auto/Manual

      # link to the Model State
      @state = nil

      # Model - Mass Injection
      #  true  public
      #  false protected
      @attr_accessible = true
      @abstract = ''

      # Common Policy Class
      @req_policies = []
      @code_policy = Abstraction::Policy.new

      @id = 'S_' + @domain
    end
    attr_accessor :id, :filename, :state, :attr_accessible, :state, :domain, :type,
                  :abstract, :origin, :model, :attribute,
                  :req_policies, :code_policy

    # Policy
    #
    # IN  --CUD--> V --R--> OUT
    #
    def set_policy(dir, mls, mcs)
      # TODO: ?
    end

    # call by lib/security-assurance-model.rb
    def setup4dashboard
      get_policy(@model)
      if @level.nil?
        if $alias_model.nil?
          # $log.error "setup4dashboard() TODO: no policy for model=#{@model} attr=#{@attribute}"
        else
          model = $alias_model[@model]
          get_policy(model)
          if @level.nil?
            # $log.error "no policy for #{@model}  = check alias => MISS"
          end
        end
      end

      return 0
    end

    # Get policy from controller?
    def get_policy(model)
      $abst_states.each do |n, s|
        if s.type == 'model' && s.model == model
          s.req_policies.each do |p|
            # TODO: last one
            @level = p.level
          end
        end
      end
    end

    def print
      filename = @filename
      if @attr_accessible then flag = '-'
      else                     flag = 'P'
      end
      puts "    #{@type.ljust(12)} #{flag} #{@domain.ljust(40)}  #{filename}"
    end
  end
end
