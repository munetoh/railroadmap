# -*- coding: UTF-8 -*-

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
  class State
    def initialize(domain, type)  # TODO: domain => model, action
      super()
      @domain = domain    #  "model#action"
      @type = type  # controller model view
      if type != 'model'
        ma = @domain.split('#')
        if ma.size == 2
          @model = ma[0]
          @action = ma[1]
          id = 'C_' + @domain
          @path = get_path(@domain, id)
        else
          if type == 'view' && ma.size == 3
            # View => model#action#format
            $log.debug "#{domain} #{ma} #{type}"
            @model  = ma[0]
            @action = ma[1]
            # TODO: format?
            @path   = 'TBD'
          else # controller
            $log.error "#{domain} #{ma} #{type}"
            @model  = nil
            @action = nil
            @path   = 'TBD'
            # DEBUG
            p $filename
            fail "DEBUG"
          end
        end
      else # Model
        # model
        @model = domain
        @action = nil  # TODO
        @path = nil # TODO: get_path(domain)
      end

      # For diferrent Model and controleler domain
      #   The_role: role <=> admin:role
      @model_alias    = nil
      @filename       = []
      @start_linenum  = 0
      @end_linenum    = 0
      @variables      = []
      @before_filters = nil
      @origin         = 'unknown'  # Code/Auto/Manual
      @subtype        = 'code'  # code attack

      @routed = nil

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

      # Controller BF?
      @is_private   = false   # state flag
      @is_protected = false   # state flag

      # Common Policy Class
      @code_policy = Abstraction::Policy.new
      # multiple policies exist,
      # 1) by base policy propagation to shared state
      # 2) by expeption req against base policy.
      @req_policies  = []
      # which policy we use fot this resource?
      @req_policy_id = 0

      # also set to src state
      @nav_error = false
      @df_error = false

      @controller_class      = nil
      @base_controller_class = nil

      # root block
      @block_root      = Block.new
      @block_root.type = 'root'
      @block_root.id   = @id + '_R'
      $block           = @block_root  # set current block,  => root

      # XSS raw dataflow
      @test_xss_path = []  # C-V
      @xss_in        = []
      @xss_out       = []

      # HTML5 state diagram
      @is_v2v_src = false
      @is_v2v_dst = false
      @is_c2c_src = false
      @is_c2c_dst = false

      # security requirement error
      @req_error = false
      @marks = [] # Brakeman

      # Graphviz
      gv_node = nil
      gv_node2 = nil
    end
    attr_accessor :id, :type, :domain, :model, :action, :path, :url, :model_alias,
                  :filename, :start_linenum, :end_linenum,
                  :variables,
                  :origin,
                  :is_private, :is_protected,
                  :xss_in, :xss_out, :test_xss_path,
                  :subtype,
                  :controller_class, :base_controller_class,
                  :is_v2v_src, :is_v2v_dst, :is_c2c_src, :is_c2c_dst, :req_error,
                  :marks,
                  :before_filters,
                  :code_policy, :req_policies, :req_policy_id, :nav_error, :df_error,
                  :gv_node, :gv_node2, :routed

    # cal this after parse the state to set the URL of C and V state
    def set_url
      # Get URL
      @url = nil
      if type != 'model' && @is_private == false && @is_protected == false
        unless $route_map.nil?
          begin
            r = $route_map[@domain]
          rescue TypeError => e
            $log.error "State:initialize() $route_map was changed. update railroadmap/abstraction.rb file. new $route_map can generated by routemap command"
            raise "HALT"
          end
          if r.nil?
            $log.debug "no URL for #{@domain}"
          else
            @url = r[2]
          end
        end
      end # C and V
    end

    # 20130724 added
    def get_path_old(domain, id)
      $log.error "get_path(#{domain}, #{id})"
      ma = @domain.split('#')
      return nil if ma[0].nil? || ma[1].nil?

      # Get path from $route_map
      $route_map.each do |k, v|
        if !v.nil? && v.size >= 2
          if ma[0] == v[0] && ma[1] == v[1]
            # hit
            $log.error "get_path() #{domain} => #{k} #{v}"
            return k
          end
        else
          $log.error "get_path(),  $route_map was changed. update railroadmap/abstraction.rb file. new $route_map can generated by routemap command"
          $log.error "get_path(),  $ railroadmap routemap"
          fail "railroadmap/abstraction.rb, OLD $route_map format"
        end
      end
      return nil
    end

    # 20130816 added for new $route_map format
    # e.g. 'user#new' =>  ["GET", "users_new", "/users/new(.:format)"],
    def get_path(domain, id)
      # Get path from $route_map
      $route_map.each do |k, v|
        # e.g. 'user#new' =>  ["GET", "users_new", "/users/new(.:format)"],
        return v[1] if k == domain # Hit
      end
      return nil # Miss
    end

    #---------------------------------------------------------------------------
    # Json export  <= TODO: update
    def to_json(*a)
      {
        "json_class"   => self.class.name,
        "data"         => {
          "domain" => @domain,
          "type" => @type,
          # Code Location
          "filename" => @filename,
          "start_linenum" => @start_linenum,
          "end_linenum" => @end_linenum,
          # Befor filters
          "is_private" => @is_private,
          "is_protected" => @is_protected,
          "ssl_required" => @ssl_required,
          "ssl_allowed" => @ssl_allowed,
          # Devise/CanCan
          "is_authenticated" => @is_authenticated,
          "authorize" => @authorize,
          # for HTML5
          "is_v2v_src" => @is_v2v_src,
          "is_v2v_dst" => @is_v2v_dst,
          "is_c2c_src" => @is_c2c_src,
          "is_c2c_dst" => @is_c2c_dst,
          # mark (brakeman)
          "marks" => @marks
        }
      }.to_json(*a)
    end

    # Json import
    def self.json_create(o)
      s = new(o["data"]["domain"], o["data"]["type"])
      # Location
      s.filename = o["data"]["filename"]
      s.start_linenum = o["data"]["start_linenum"]
      s.end_linenum = o["data"]["end_linenum"]
      s.is_private =  o["data"]["is_private"]
      s.is_protected =  o["data"]["is_protected"]
      s.ssl_required =  o["data"]["ssl_required"]
      s.ssl_allowed =  o["data"]["ssl_allowed"]
      s.is_authenticated =  o["data"]["is_authenticated"]
      s.authorize =  o["data"]["authorize"]
      s.is_v2v_src =  o["data"]["is_v2v_src"]
      s.is_v2v_dst =  o["data"]["is_v2v_dst"]
      s.is_c2c_src =  o["data"]["is_c2c_src"]
      s.is_c2c_dst =  o["data"]["is_c2c_dst"]
      # Marks brakeman
      s.marks = o["data"]["marks"]
      return s
    end

    #---------------------------------------------------------------------------
    def add_mark(mark)
      @marks.push(mark)
    end

    #---------------------------------------------------------------------------
    def add_variable(v)
      @variables << v
    end

    def complete_condition(guard2abst, guard2abst_byblk)
      @block_root.complete_condition(nil, nil, guard2abst, guard2abst_byblk)
    end

    def print
      filename = @filename
      flag = ''
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

    # Authorization
    # CanCan
    #   type     location  example
    #   ------------------------------------------------
    #   bf       @class    load_and_authorize_resource
    #   command  @def      authorize! :manage, Upload
    #   guard    @code     can?
    #   ------------------------------------------------
    #
    # this is object, so put subject and action here
    # 20131109 obsolete
    #
    # def add_cancan(type, subject, action, object)
    #  @cancan = {} if @cancan.nil?  # TODO: cancan
    #  key = "#{type}:#{subject}:#{action}"
    #  @cancan[key] = [type, subject, action]
    #  $log.debug "add_cancan #{subject} #{action} #{object} => #{@cancan}"
    # end

    # Setup for Dashboard
    #
    # TODO: call def -> variable -> dashboard.erb

    # TODO: Missing PEP both on code and req => unclear
    # Update @authentication_comment
    # TODO: @authentication_filter_list => @authentication_comment
    #
    # return
    #   1 of state is unclear
    #
    # called by lib/security-assurance-model.rb
    def setup4dashboard_controller
      # authenticaton_comment
      if @is_authenticated
        # Authenticated - OK
        @authentication_comment = "AUTH(#{@authentication_comment})"
      elsif @is_public
        # Public by explicit filter  - OK
        @authentication_comment = "NO_AUTH(#{@authentication_comment})"
      else
        # TODO: check requirments
        # req_error is set by lib/rails/requirement.rb
        if @req_error
          @authentication_comment = "NO_AUTH(#{@authentication_comment}) and NO_REQ"
          @is_unclear_authentication = true  # TODO
          @is_unclear = true
          @is_public  = true
        else
          @authentication_comment = "NO_AUTH(Note: #{@authentication_comment})"
          @is_public = true
        end
      end

      # authorization_comment
      if @is_authorized.nil?
        if @is_public
          @authorization_comment = "NO_AUTH => NO_PEP"
          @is_unclear_authorization = false
        else
          @authorization_comment = "NO_PEP"
          @is_unclear_authorization = true
          @is_unclear = true
        end
      elsif @is_authorized == true
        @authorization_comment = "PEP(#{@authorization_comment})"
        @is_unclear_authorization = false
      elsif @is_authorized == false
        if @is_public
          @authorization_comment = "NO_AUTH=>NO_PEP(#{@authorization_comment})"
        else
          @authorization_comment = "NO_PEP(#{@authorization_comment})"
        end
        @is_unclear_authorization = false
      else
        fail "FATAL"
      end

      #  PEP vs Policy
      if @is_authorized == true && @level.nil?
        $log.info "setup4dashboard_controller() POLICY PEP ON, Policy Missing"
        @level    = 'Missing'
        @category = 'Missing'
        @is_unclear_pdp = true
        @is_unclear = true
      elsif @is_authorized != true && !@level.nil?
        $log.error "setup4dashboard_controller() POLICY PEP missing, Policy ON"
        # TODO
      else
        if @level.nil? || @category.nil?
          # No policy
          if $domains.nil?
            $log.info "setup4dashboard_controller() POLICY #{@id} level=#{@level} category=#{@category}"
          else
            if $domains[@model].nil?
              $log.info "setup4dashboard_controller() POLICY #{@id} level=#{@level} category=#{@category}"
            else
              @level = $domains[@model]['level']
              @category = $domains[@model]['category']
              $log.debug "setup4dashboard_controller() POLICY #{@id} level=#{@level} category=#{@category} USE DOMAIN POLICY"
            end
          end
        end
      end

      if @is_unclear
        return 1
      else
        return 0
      end
    end

    # View
    #  1 C-render->V check the controller's PEP  <= pass1
    #  2 V-render->V check parent's PEPs         <= pass2
    #  3 Layout, TODO:                            <= pass1
    #
    # called by lib/security-assurance-model.rb
    def setup4dashboard_view_pass1
      # Get alias
      model = @model
      unless $alias_model.nil?
        unless $alias_model[@model].nil?
          # use alias
          model = $alias_model[@model]
        end
      end

      cid = 'C_' + model + "#" + @action
      c = $abst_states[cid]
      if model == 'layout'
        # 3 Layout, TODO
        @authentication_comment = "-"
        @authorization_comment  = "Layout(depends on main view)"
        @is_unclear_authorization = false
      elsif !c.nil?
        # 1 C-render->V check the controller's PEP
        @authentication_comment   = "-"
        @authorization_comment    = c.code_policy.authorization_comment + " @controller"
        @is_unclear_authorization = c.code_policy.is_unclear_authorization
        @is_unclear               = c.code_policy.is_unclear
        # other
        @is_public                = c.code_policy.is_public
        @url                      = c.url  # copy URL too
        # copy Policy too
        @level    = c.code_policy.level
        @category = c.code_policy.category  # TODO: Obsolate
      else
        # Miss?
        tlist = get_transitions_to(@id)
        if tlist.size > 0
          # 2 V-render->V check parent's PEPs  SKIP
        else
          # TODO: OLD
          req = nil # $assets[@domain]
          if !req.nil? && req['except_auth_check'] == 'on'
            @authentication_comment   = "-"
            @authorization_comment    = "Except (#{req['reason']})"
          else
            @authentication_comment   = "-"
            @authorization_comment    = "Unknown"
            @is_unclear_authorization = true
            @is_unclear = true
            # Remidiation?
            $remidiation_req_list <<  "  '#{@domain}' => {'except_auth_check' => 'on', 'reason' => 'TBD'},"
            $log.info "#{@id} Unknown Authorization =>  '#{@domain}' => {'except_auth_check' => 'on', 'reason' => 'TBD'}"
          end
        end
      end

      $log.info "setup4dashboard_view_pass1() POLICY missing #{@id}" if @level.nil? # or @category.nil?

      if @is_unclear
        return 1
      else
        return 0
      end
    end

    def setup4dashboard_view_pass2
      # Get alias
      model = @model
      unless $alias_model.nil?
        unless $alias_model[@model].nil?
          # use alias
          model = $alias_model[@model]
        end
      end

      tmp_is_unclear = false
      cid = 'C_' + model + "#" + @action
      c = $abst_states[cid]
      if model == 'layout'
        # 3 Layout, SKIP
      elsif !c.nil?
        # 1 C-render->V check the controller's PEP  SKIP
      else
        tlist = get_transitions_to(@id)
        if tlist.size > 0
          # 2 V-render->V check parent's PEPs
          @url = ''
          @authorization_comment = ''
          @is_unclear_authorization = false

          tlist.each do |src|
            c = $abst_states[src.src_id]
            @code_policy.authorization_comment   += "#{c.domain}=" + c.code_policy.authorization_comment + ', '
            @code_policy.is_unclear_authorization = true if c.code_policy.is_unclear_authorization
            tmp_is_unclear            = true if c.code_policy.is_unclear
            @url += c.url + ', ' unless c.url.nil?

            # TODO: overwrite now, must mix
            @code_policy.level    = c.code_policy.level
            @code_policy.category = c.code_policy.category
          end
          @authentication_comment   = "-"
        end
      end

      if @level.nil?
        if !$domains.nil? && !$domains[@model].nil?
          @level    = $domains[@model]['level']
          @category = $domains[@model]['category']
        else
          $log.info "setup4dashboard_view_pass2() POLICY missing #{@id}  #{@model}, no $domains[]"
        end
      end

      $log.info "setup4dashboard_view_pass2() POLICY missing #{@id}" if @level.nil? # or @category == nil

      if tmp_is_unclear
        @is_unclear = tmp_is_unclear
        return 1
      else
        return 0
      end
    end

    # get trans to sid
    def get_transitions_to(sid)
      list = []
      $abst_transitions.each do |k, v|
        list << v if v.dst_id == sid # Add
      end
      return list
    end

    # Controller PEP ==> Model
    #  1. C states =>  list
    #  2. check AA
    #  3. comments
    #
    #  list = [
    #      action=> [
    #        authentication = [fname, on|off]
    #        authorization  = [fname, on|off]
    #   Score
    #      action:fname:on|off,
    #
    # called by lib/security-assurance-model.rb
    def setup4dashboard_model
      tmp_is_unclear = false

      @is_unclear_authorization = false
      @is_unclear_authorization = false

      model = @model
      # route
      unless $alias_model.nil?
        unless $alias_model[@model].nil?
          # use alias
          model = $alias_model[@model]
        end
      end

      c_count = update_action_list(model)

      # check alias
      unless model_alias.nil?
        model_alias.each do |m, v|
          c_count += update_action_list(m, m)
        end
      end

      if c_count == 0
        # No controller for this model
        @code_policy.authentication_comment    = "No controller?"
        @code_policy.authorization_comment     = "No controller?"
        @code_policy.is_unclear_authentication = true
        @code_policy.is_unclear_authorization  = true
        @code_policy.is_public = true
      else
        @code_policy.authentication_comment   = "TBDD"
        @code_policy.authorization_comment = "TDDD"
      end

      if @code_policy.no_authenticated_action_list.size > 0
        # TODO: support ALL, SEMI
        @code_policy.is_public = true
      end

      if tmp_is_unclear
        @code_policy.is_unclear = tmp_is_unclear
        return 1
      else
        return 0
      end
    end

    def update_action_list(model, cname = nil)
      c_count = 0
      $abst_states.each do |k, c|
        if c.type == 'controller' && c.model == model && c.routed
          # Hit
          if cname.nil?
            action = c.action
          else
            action = cname + '#' + c.action
          end
          c_count += 1
          if c.code_policy.is_authenticated
            @code_policy.authenticated_action_list << action
          else
            @code_policy.no_authenticated_action_list << action
          end

          if c.code_policy.is_authorized
            @code_policy.authorized_action_list << action
          else
            @code_policy.no_authorized_action_list << action
          end
        end
      end
      return c_count
    end

  end
end
