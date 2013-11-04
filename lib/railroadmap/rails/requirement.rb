# -*- coding: UTF-8 -*-
# requirements

require "ruby-graphviz"

module Rails
  # railroadmap/requirements.rb
  class Requirement
    def initialize
      @remidiation = {}
    end

    # Policy
    # remidiation
    def add_policy_remidiation(domain, key, value)
      r = @remidiation[domain]
      if r.nil?
        # new
        r = {}
        r[key] = value
        @remidiation[domain] = r
      else
        r2 = r[key]
        if r2.nil?
          r[key] = value
        else
          $log.error "#{key} exist"
        end
      end
    end

    def print_policy_remidiation
      if $roles.size == 0
        print "\e[31m"  # red
        puts "    missing req.   : #{@remidiation.size} (controller states), set $roles"
        print "\e[0m"   # reset
      elsif @remidiation.size > 0
        print "\e[31m"  # red
        puts "    missing req.   : #{@remidiation.size} (controller states)"
        puts ""
        puts "Set the followings to $assets in rairoadmap/requirements.rb"
        puts "---"
        puts "# Remidiation. Gen by tool"
        level = 40
        @remidiation.each do |d, r|
          domain_name = "'#{d}'"
          puts "#{domain_name.rjust(level)} => {\n"
          r.each do |k, v|
            k2 = "'#{k}'"
            if v.class == String
              v2 = "'#{v}'"
            else
              v2 = v
            end
            puts "#{k2.rjust(level)} => #{v2},"
          end
          puts "                                            },"
        end

        puts "---"
        print "\e[0m" # reset
      else
        print "\e[32m"  # green
        puts "    missing req.   : 0"
        print "\e[0m" # reset
      end
    end

    def get_lowest_role
      name = 'TBD'
      level = 15
      category = 0

      $roles.each do |n, r|
        if r['level'] < level
          name = n
          level = r['level']
          category = r['categories'][0]
        end
      end
      return name, level, category
    end

    # =================================================================================
    # Policy injection and propagation
    # Set requirment policy to Model
    #  => Missing model => Bad req => Warning
    def set_model_policy(model_name, model_policy)
      key = "M_" + model_name
      s = $abst_states[key]
      if s.nil?
        $log.error "set_model_policy()  model=#{model_name} is missing"
        # TODO: Missing model => Bad req => Warning
      else
        set_policy(s, model_policy)
      end
    end

    def set_cv_policy(key, policy)
      s = $abst_states[key]
      if s.nil?
        $log.error "set_cv_policy()  state=#{key} is missing"
        # TODO: Missing model => Bad req => Warning
      else
        set_policy(s, policy)
      end
    end

    # common
    def set_policy(state, policy)
      if state.req_policies.count != 0
        # EXIST => BAD REQ?
        $log.error "set_policy(#{state.id})  REQ POLICY IS ALREADY EXIST! BAD REQ?"
      else
        # get req
        state.model_alias  = policy[:model_alias]
        # policy
        p = Abstraction::Policy.new
        p.is_authenticated = policy[:is_authenticated]
        p.is_authorized    = policy[:is_authorized]
        p.level            = policy[:level]
        p.role_list        = policy[:roles]
        p.ignore           = policy[:ignore]
        p.color            = policy[:color]
        p.origin_type = 'req'
        p.origin_id = 'req'
        state.req_policies << p

        # copy level to code => dashboard
        state.code_policy.level = p.level

        $stat_policy_model_count += 1
      end
    end

    # Check model w/o policy
    # => No policy => Bad req => Warning
    def check_models_wo_policy
      good_req = true
      rps = []
      $abst_states.each do |k, s|
        if s.type == 'model'
          if s.req_policies.count == 0
            good_req = false
            $log.error "check_models_wo_policy() no policy for #{s.id}"
            # TODO: add warnings
            $stat_policy_model_na_count += 1
            p  = "  # #{s.id}\n"
            p += "  '#{s.model}' => {\n"
            p += "    is_authenticated: true,\n"
            p += "    is_authorized:    true,\n"
            p += "    level:            5,  # Mid \n"
            p += "    roles:  [\n"
            p += "      { role: 'user', action:'CRUD' }\n"
            p += "    ]\n"
            p += "  },\n"
            rps << p
          end
        end
      end

      if good_req == false
        # print remidiation
        print "\e[31m"  # red
        puts "Missing base policies"
        puts "---"
        rps.each do |p|
          puts p
        end
        puts "---"
        print "\e[0m" # reset
      end
      return good_req
    end

    # Policy propagation, M->C->V
    def propagate_policy
      $max_id_length = 30
      $imcompleate_trans_count = 0

      #  M to C
      $abst_states.each do |k, s|
        if s.type == 'model' && s.req_policies.count == 1
          # M->C
          propagate_policy_to_controller(s)
        end
        # TODO: ?
        $max_id_length = k.length if k.length > $max_id_length
      end

      # C to V
      $abst_states.each do |k, s|
        if s.type == 'controller' && s.req_policies.count == 1
          # M->C
          propagate_policy_to_view(s)
        end
      end

      # V to V
      propagate_policy_to_view_form

      # M to S
      propagate_policy_to_variables

      if $imcompleate_trans_count > 0
        print "\e[31m"  # red
        puts "    imcompleate trans, count: #{$imcompleate_trans_count} (from view states)"
        print "\e[0m"   # reset
      end
    end

    # Policy propagation, M->C
    def propagate_policy_to_controller(state)
      # model
      $abst_states.each do |k, s|
        if s.type == 'controller'
          # check alias
          alias_hit = false
          unless state.model_alias.nil?
            alias_hit = true if state.model_alias[s.model] == state.model
          end

          if s.model == state.model || alias_hit
            if s.req_policies.count > 0
              # req exist
              # $log.error "propagate_policy_to_controller() SKIP #{s.id} req exist"
            else
              # Deep copy
              p = Marshal.load(Marshal.dump(state.req_policies[0])) # 0 must exist
              p.origin_type = 'model'
              p.origin_id = state.id
              s.req_policies << p
              # copy level from req to code
              s.code_policy.level = p.level
            end
          end
        end
      end
    end

    # Policy propagation, C to V
    # state C state
    def propagate_policy_to_view(state)
      $abst_states.each do |k, s|
        if s.type == 'view'
          if s.domain == state.domain && state.req_policies.count == 1
            # Deep copy
            p = Marshal.load(Marshal.dump(state.req_policies[0]))
            p.origin_type = 'controller'
            p.origin_id = state.id
            s.req_policies << p
            # copy level from req to code
            s.code_policy.level = p.level
          end
        end
      end
    end

    # Policy propagation, V1->V2
    #       navigation
    #   V1  --form-->   V2
    def propagate_policy_to_view_form
      $abst_states.each do |k1, state|
        if state.type == 'view'
          # V-V transitions
          $abst_transitions.each do |k2, t|
            if t.src_id == state.id
              # HIT SRC
              dst = $abst_states[t.dst_id]
              if dst.nil?
                $log.info "propagate_policy_to_view_form() no dst #{k2}"
                $imcompleate_trans_count += 1
                # TODO: add warning
              elsif dst.type == 'view'
                # $log.error "propagate_policy_to_view_form() HIT #{k} "
                if state.req_policies.count == 1
                  # Deep copy the policy if missing
                  p =  Marshal.load(Marshal.dump(state.req_policies[0]))
                  p.origin_type = 'view'
                  p.origin_id = state.id
                  dst.req_policies << p
                  # copy level from req to code
                  dst.code_policy.level = p.level
                else
                  $log.info "propagate_policy_to_view_form() #{state.id} HIT  -> #{t.dst_id} multiple policies at src side"
                end
              end
            end
          end # do
        end # view
      end # do
    end

    # TODO: workaround for missing variables, move to ?
    def add_missing_variable(id)
      fail "$abst_variables is not defined" if $abst_variables.nil?
      return nil if id.nil?

      domain = id.gsub('S_', '')
      type  = 'code'
      vtype = 'unknown'
      filename = 'unknown'

      # TODO: roles#hoge => role#hoge
      ma = domain.split('#')
      if ma.size == 2
        model = ma[0].singularize
        attribute = ma[1]
        domain = model + '#' + attribute
        # $log.error "add_missing_variable NEW #{ma[0]}=>#{model} #{domain}"
      end

      v = Abstraction::Variable.new(domain, type, vtype)
      v.filename << filename
      v.origin = 'code'
      if $abst_variables[v.id].nil?
        # $log.error "#{v.id} SET"
        $abst_variables[v.id] = v
        return v
      else
        # $log.error "#{v.id} EXIST"
        return $abst_variables[v.id]
      end
    end

    def propagate_policy_to_variables

      # TODO: DF has missing variable (= nit a model attribute)
      $abst_dataflows.each do |n, df|
        # $log.error "propagate_policy_to_variables DF #{n} #{df.type} #{df.subtype}"
        if df.type == 'in'
          # $log.error "propagate_policy_to_variables DF #{n} #{df.type} #{df.subtype} => #{df.dst_id} #{df.dst_hint}"
          v = $abst_variables[df.dst_id]
          if v.nil?
            v2 = add_missing_variable(df.dst_id)
            if v2.nil?
              $log.error "propagate_policy_to_variables ADD sid=#{df.dst_id}  => NG"
            else
              # $log.error "propagate_policy_to_variables ADD #{df.dst_id}  => #{v2.id}"
              df.dst_id = v2.id # Update BAD id
            end
          end
        end
        if df.type == 'dataflow' && df.subtype = 'input' # TODO: obsolete
          # $log.error "propagate_policy_to_variables DF #{n} #{df.type} #{df.subtype} => #{df.dst_id} #{df.dst_hint}"
        end
        if df.type == 'out' && !df.src_id.nil?
          # out w/ src
          # $log.error "propagate_policy_to_variables DF #{n} #{df.type} #{df.subtype} #{df.src_id}"
          v = $abst_variables[df.src_id]
          if v.nil?
            v2 = add_missing_variable(df.src_id)
            if v2.nil?
              $log.error "propagate_policy_to_variables ADD sid=#{df.src_id}  => NG"
            else
              # $log.error "propagate_policy_to_variables ADD #{df.src_id}  => #{v2.id}"
              df.src_id = v2.id # Update BAD id
            end
          end
        end
        fail "DEBUG" if df.src_id == 'S_users#each'
      end

      # create alias table of M-CV
      alias_map = {}
      $assets_base_policies.each do |k, v|
        alias_map.merge!(v[:model_alias]) unless v[:model_alias].nil?
      end

      # OK check the level model == model
      $abst_variables.each do |k, dst|
        # check model
        sid = 'M_' + dst.model
        sid = 'M_' + alias_map[dst.model] unless alias_map[dst.model].nil?  # use alias
        state = $abst_states[sid]
        unless state.nil?
          # Hit
          p =  Marshal.load(Marshal.dump(state.req_policies[0]))
          if p.nil?
            # $log.error "Copy policy fail"
          else
            p.origin_type = 'model'
            p.origin_id = state.id
            dst.req_policies << p
            # copy level from req to code
            dst.code_policy.level = p.level
            # $log.error "propagate_policy_to_variables #{k} <= #{sid}, level=#{p.level}"
          end
        end
      end

    end

    # Policy propagation, V1->V2
    #       navigation
    #   V1  <--layout-- V2
    def check_cv_wo_policy
      # TODO
    end

    def print_policy_assignment
      cwidth = $max_id_length
      puts "  Policy assignment"
      puts "  1) MVC states"
      col0 = "state"
      puts " #{col0.rjust(cwidth)}   code  req"
      puts "  --------------------------------------------------------------"
      $abst_states.each do |k, s|
        code_policy_stat = "pub"
        if s.code_policy.exist?
          # code_policy_stat = "set"
          if s.code_policy.is_authenticated == false
            code_policy_stat = 'pub'
          elsif s.code_policy.is_authenticated == true
            if s.code_policy.is_authorized == false
              code_policy_stat = 'A_ '
            elsif s.code_policy.is_authorized == true
              code_policy_stat = 'AA '
            else
              code_policy_stat = 'A_ '
            end
          end
        end

        req_policy_stat = s.req_policies.count.to_s
        if s.req_policies.count == 1
          if s.req_policies[0].ignore == true
            req_policy_stat = 'ignore'
          elsif s.req_policies[0].is_authenticated == false
            # Public
            req_policy_stat = 'pub'
          elsif s.req_policies[0].is_authenticated == true
            if s.req_policies[0].is_authorized == false
              req_policy_stat = 'A_'
            elsif s.req_policies[0].is_authorized == true
              req_policy_stat = 'AA'
            else
              req_policy_stat = 'A_'
            end
          end
        end

        code_policy_stat = '   ' if s.type != 'controller'

        src_id = ""
        if s.req_policies.count == 1
          src_id = " <= #{s.req_policies[0].origin_id}"
        elsif s.req_policies.count >= 1
          src_id = " <= "
          s.req_policies.each do |p|
            src_id += "#{p.origin_id},"
          end
        end

        print "\e[35m" if s.df_error  # Puple
        print "\e[36m" if s.nav_error # Cyan
        print "\e[31m" if s.req_error # red
        puts " #{s.id.rjust(cwidth)}   #{code_policy_stat}  #{req_policy_stat.ljust(6)} #{src_id}"
        print "\e[0m" # reset
      end # do
      puts "  --------------------------------------------------------------"
      puts "  color) \e[31mcheck PEP, \e[36mcheck Nav., \e[35mcheck dataflow\e[0m"
    end

    # Graphviz out
    #  dot, pdf
    def print_policy_assignment_diagram
      g = GraphViz.new(:G, type: :digraph, rankdir: "LR")
      # set MVC node
      req = g.add_nodes('requirements')
      req[shape: 'box']
      # C
      gc = g.subgraph
      gc[rank: 'same']
      # V
      gv = g.subgraph
      gv[rank: 'same']
      # V form
      gf = g.subgraph
      gf[rank: 'same']

      $abst_states.each do |k, s|
        p = s.req_policies[0]
        if p.nil?
          color = nil
        else
          color = p.color
        end

        if s.type == 'controller'
          s.gv_node = gc.add_nodes(s.id)
          s.gv_node[shape: 'doubleoctagon']
          s.gv_node[color: p.color] unless color.nil?
        elsif s.type == 'view'
          s2 = $abst_states[p.origin_id] unless p.nil?
          if !s2.nil? && s2.type == 'view'
            # 2nd view (form)
            s.gv_node = gf.add_nodes(s.id)
          else
            s.gv_node = gv.add_nodes(s.id)
          end
          s.gv_node[shape: 'octagon']
          s.gv_node[color: p.color] unless color.nil?
        else
          # model
          s.gv_node = g.add_nodes(s.id)
          s.gv_node[shape: 'tripleoctagon']
          s.gv_node[color: p.color] unless color.nil?
        end
      end

      # for C-> V-> C
      gc2 = g.subgraph
      gc2[rank: 'same']
      $abst_states.each do |k, s|
        if s.type == 'controller'
          s.gv_node2 = gc2.add_nodes(s.id + " ")
          p = s.req_policies[0]
          s.gv_node2[color: p.color] if !p.nil? && !p.color.nil?
          if s.code_policy.is_authenticated
            if s.code_policy.is_authorized
              s.gv_node2[penwidth: '4']
            else
              s.gv_node2[penwidth: '8']
            end
          end
        end
      end

      # set edge
      $abst_states.each do |k, s|
        s.req_policies.each do |p|
          if p.origin_id == 'req'
            e = g.add_edges(req, s.gv_node)
          else
            src = $abst_states[p.origin_id]
            e = g.add_edges(src.gv_node, s.gv_node)
            p = src.req_policies[0]
            e[color: p.color] if !p.nil? && !p.color.nil?
          end
        end
      end

      # set V->C edge
      $abst_transitions.each do |k, t|
        src = $abst_states[t.src_id]
        dst = $abst_states[t.dst_id]
        if !src.nil? && !dst.nil?
          if src.type == 'view' && dst.type == 'controller'
            e = g.add_edges(src.gv_node, dst.gv_node2)
            p = src.req_policies[0]
            if !p.nil? && !p.color.nil?
              e[color:     p.color]
              e[fontcolor: p.color]
            end
            # arrowhead
            #  authenticated => tee
            #  + auth => box
            if dst.code_policy.is_authenticated
              if dst.code_policy.is_authorized
                e[arrowhead: 'box']
              else
                e[arrowhead: 'tee']
              end
            end
            # line style
            #   normal: no guard
            #   dashed: guard
            t.authentication_filter = t.block.get_authentication_filter
            t.authorization_filter = t.block.get_authorization_filter
            if !t.authentication_filter.nil?
              e[style: 'dashed']
              e[label: t.block.abst_condition_success]
            elsif !t.authorization_filter.nil?
              e[style: 'dashed']
              e[label: t.block.abst_condition_success]
            end
          end
        end
      end
      g.output(dot: "railroadmap/policy.dot")
      g.output(pdf: "railroadmap/policy.pdf")
    end

    # Load requirements
    def load(requirements_req, requirements_file)
      require requirements_req
      $log.debug "loaded existing requirements file #{requirements_file}"
      # Load/Inject Policy after model gen.
      if $assets_base_policies.nil?
        # $log.error "Please set $assets_base_policies={} in railroadmap/requirements.rb"

        print "\e[31m"  # red
        puts "    Please set $assets_base_policies={} in railroadmap/requirements.rb"
        print "\e[0m" # reset

        $assets_base_policies = {}
      else
        # policy definitions
        #   domain           target
        #   ---------------------------
        #   model            Model
        #   ---------------------------
        #   model#action     Class#Method = Domain
        #   modelpage
        #   model.attribute  Variables
        #
        $stat_policy_model_count = 0
        $stat_policy_model_na_count = 0
        # loop
        $assets_base_policies.each do |k, a|
          set_model_policy(k, a)
        end
        # Check model w/o policy
        # => Remidiation
        check_models_wo_policy
      end

      #  set mask policy before propagate the policy
      if $assets_mask_policies.nil?
        # $log.error "Please set $assets_mask_policies={} in railroadmap/requirements.rb"
        print "\e[31m"  # red
        puts "    Please set $assets_mask_policies={} in railroadmap/requirements.rb"
        print "\e[0m" # reset
        $assets_mask_policies = {}
      else
        # TODO: unified list or C,V,Var separate list?
        # 1) propagage => overwrite, OR
        # 2) req mask -> propagate  <== EASY?
        $assets_mask_policies.each do |k, a|
          set_cv_policy(k, a)
        end
      end

      # Model-> ALL Controller states
      propagate_policy

      # Controller state -> View states
      # DEBUG print all policies
      # print_policy_assignment
      # save to PDF
      print_policy_assignment_diagram

      # check 1
      if $authentication_module.nil?
        # no authentication module => RED
        print "\e[31m" # red
        puts "    authentication : N/A (railroadmap/config.rb)"
        print "\e[0m"  # reset
      else
        puts "    authentication : #{$authentication_module.name}"
      end

      if $authorization_module.nil?
        # no authorizarion module => RED
        print "\e[31m" # red
        puts "    authorizarion  : N/A (railroadmap/config.rb)"
        print "\e[0m"  # reset
      else
        puts "    authorizarion  : #{$authorization_module.name}"
        if $ac_type != 'rbac'
          puts "    ERROR - aplication using CanCan, set $ac_type to rbac"
        end
      end

      # TODO: move to requirements.rb
      # check 2, req. vs. state prop
      remidiation  = "Define public states. e.g. home, sign_in, and sign_up pages"
      remidiation << "File: railroadmap/requirements.rb\n"
      remidiation << "---\n"
      remidiation << "$assets = {\n"
      remidiation << "  #  From code\n"
      level = 40
      remidiation_count = 0
      req_count = 0

      # For all controller states check given assets list provided by railroadmap/requirements.rb
      $abst_states.each do |n, s|
        # Controller
        if s.type == 'controller'
          domain_name = "'#{s.domain}'"
          # check existance
          asset_req = nil # OLD $assets[s.domain]
          if !asset_req.nil?
            # Hit, check with assets[]
            $log.debug "Rails:Requirement.load()  #{s.domain}"
            req_count += 1

            # 20130817 New code, just check the existance
            # TODO: check inconsistency between PEP placemant and PDP definition
            unless $authentication_module.nil?
              # app uses Auth
              if s.is_authenticated.nil?
                if asset_req['authentication'] == 'no'
                  s.authentication_comment += "no auth defined by req."
                elsif asset_req['authentication'] == 'not_routed'
                  s.authentication_comment += "no routes defined by req."
                else
                  s.req_error = true
                  add_policy_remidiation(s.domain, 'authentication', 'no')
                  add_policy_remidiation(s.domain, 'comment', 'remidiation(except)')
                end
              else
                # TODO: check confrict?
              end
            end

            if $authorization_module.nil?
              $log.error "No authotization module for #{s.id}"
            else
              # app has PDP
              if s.is_authenticated == true
                # C has Authentication check
                if asset_req['authorization'] == 'no'
                  s.authorization_comment = "no authorization defined by req."
                  if s.is_authorized
                    $log.error "Confrict! policy say no, but code has PEP"
                  end
                  s.is_authorized = false
                end
              else
                # No PDP/PEP
              end
            end
          elsif !$asset_remediations[s.domain].nil?
            $log.error "DEBUG $asset_remediations"
            fail "DEBUG"
          else # asset_req != nil
            # MISS => Default => remidiation
            if s.is_protected == true || s.is_private == true
              # SKIP functions
              $log.debug "No AA for protected and provate method #{s.id}, not routed"
            else
              # Auth
            end
          end
        elsif s.type == 'view' then
          # View
          # supress Nav w/ authorization error
          domain_name = "'#{s.domain}'"
        else
          # Model
        end  # controller
      end

      puts "    requirments    : #{req_count} assets (provided by user)"

      # New
      print_policy_remidiation

    rescue LoadError => e
      puts "Missing requirements #{requirements_file}"
      puts "create initial file? [Y/n]"
      ans = STDIN.gets
      ans = ans.chomp.downcase

      if ans == 'y'
        # Make sample
        open(requirements_file, "w") do |f|
          # TODO: use info from SRC
          f.write "# RailroadMap security requirements file\n"
          # Version
          f.write "\n"
          f.write "# Type of Access Control. rbac\n"
          f.write "$ac_type = 'rbac'\n"
          f.write "\n"
          f.write "$roles = {\n"
          f.write "}\n"
          f.write "$assets = {\n"
          f.write "}\n"
          f.write "# EOF\n"
        end
      end
      # use dummy
      # Set NULL
      $ac_type = 'unknown'
      # ROLE
      $roles = ['anon']
      # ACCOUNT
      $users = { 'anon' => 'anon' }
      # ASSET
      $assets = { 'unknown' => ['anon', 'x'] }
    end
  end
end
