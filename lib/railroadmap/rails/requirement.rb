# -*- coding: UTF-8 -*-
# requirements
#
# 20131110 cleanup v010 code

require "ruby-graphviz"

module Rails
  # railroadmap/requirements.rb
  class Requirement
    def initialize
      @requirements_hash = {} # JSON
      @remidiation = {}
      # for remidiation
      @remidiation_json = {}
      @remidiation_json['asset_discrete_policies'] = {}
      @has_remidiation = false
    end
    attr_accessor :has_remidiation

    # Load JSON requirements (v0.2.3)
    #
    # policy definitions
    #   domain           target
    #   ---------------------------
    #   model            Model
    #   ---------------------------
    #   model#action     Class#Method = Domain
    #   modelpage
    #   model.attribute  Variables
    #
    def load(filename)

      $log.debug "loaded existing requirements file #{filename}"
      req_count = 0

      # check
      unless File.exist?(filename)
        print "\e[31m"  # red
        puts "requirements #{filename} is missing."
        puts "create initial file? [Y/n]"
        ans = STDIN.gets
        ans = ans.chomp.downcase

        if ans == 'y'
          # Make sample
          print_sample_requirements(filename)
          print "\e[0m" # reset
        else
          puts "please prepare #{filename}"
          print "\e[0m" # reset
          exit
        end
      end

      # load
      open(filename, 'r') { |fp| @requirements_hash = JSON.parse(fp.read) }

      # TODO: migrate to JSON style
      # 'moderator'   => { level: 10, color: '#BCA352', description: 'moderator'},
      if @requirements_hash['roles'].nil?
        $roles = nil
      else
        $roles = {}
        @requirements_hash['roles'].each do |k, v|
          $roles[k] = { level: v['level'], color: v['color'], description: v['description'] }
        end
      end

      # TODO: change global variable names
      $assets_base_policies = @requirements_hash['asset_base_policies']
      $assets_mask_policies = @requirements_hash['asset_discrete_policies']

      # Load/Inject Policy after model gen.
      if $assets_base_policies.nil?
        # $log.error "Please set $assets_base_policies={} in railroadmap/requirements.rb"
        print "\e[31m"  # red
        puts "    Please set \"asset_base_policies\":{} in #{filename}"
        print "\e[0m" # reset

        $assets_base_policies = {}
      else
        # load model policies
        $stat_policy_model_count = 0
        $stat_policy_model_na_count = 0
        # loop
        $assets_base_policies.each do |k, a|
          set_model_policy(k, a)
          req_count += 1
        end
        # Check model w/o policy => Remidiation
        check_models_wo_policy
      end

      #  set mask policy before propagate the policy
      if $assets_mask_policies.nil?
        # $log.error "Please set $assets_mask_policies={} in railroadmap/requirements.rb"
        print "\e[31m"  # red
        puts "    Please set \"asset_discrete_policies\":{} in #{filename}"
        print "\e[0m" # reset
        $assets_mask_policies = {}
      else
        # TODO: unified list or C,V,Var separate list?
        # 1) propagage => overwrite, OR
        # 2) req mask -> propagate  <== EASY?
        $assets_mask_policies.each do |k, a|
          set_cv_policy(k, a)
          req_count += 1
        end
      end

      puts "    requirments    : #{req_count} assets (provided by #{filename})"

      # Model-> ALL Controller states
      propagate_policy

      # policy propagation diagram, save to PDF
      print_policy_assignment_diagram

      # simple check 1
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
      end
    end

    # deprecated?
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

    # TODO: be JSON native
    # ruby
    # roles: [
    #  { role: 'moderator', action: 'CRUD' },
    #  { role: 'user',  action: 'CRU', is_owner: true } ]
    # JSON
    # "roles": [
    #  { "role": "moderator", "action": "CRUD" },
    #  { "role": "user",  "action": "CRU", "is_owner": true } ]
    def j2r_roles(json)
      if json.nil?
        roles = nil
      else
        roles = []
        json.each do |r|
          roles << { role: r["role"], action: r["action"], is_owner: r['is_owner'] }
        end
      end
      return roles
    end

    # common
    def set_policy(state, policy)
      if state.req_policies.count != 0
        # EXIST => BAD REQ?
        $log.error "set_policy(#{state.id})  REQ POLICY IS ALREADY EXIST! BAD REQ?"
      else
        # get req
        state.model_alias  = policy['model_alias']
        # policy
        p = Abstraction::Policy.new
        p.is_authenticated = policy['is_authenticated']
        p.is_authorized    = policy['is_authorized']
        p.level            = policy['level']
        p.role_list        = j2r_roles(policy['roles'])  # JSON to Ruby
        p.ignore           = policy['ignore']
        p.color            = policy['color']
        p.origin_type = 'req'
        p.origin_id   = 'req'
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

    # Policy propagation: Model -> Variables
    def propagate_policy_to_variables

      # TODO: DF has missing variable (= nit a model attribute)
      $abst_dataflows.each do |n, df|
        if df.type == 'in'
          v = $abst_variables[df.dst_id]
          if v.nil?
            v2 = add_missing_variable(df.dst_id)
            if v2.nil?
              $log.error "propagate_policy_to_variables ADD sid=#{df.dst_id}  => NG"
            else
              df.dst_id = v2.id # Update BAD id
            end
          end
        end

        if df.type == 'dataflow' && df.subtype = 'input' # TODO: obsolete
          # $log.error "propagate_policy_to_variables DF #{n} #{df.type} #{df.subtype} => #{df.dst_id} #{df.dst_hint}"
        end

        if df.type == 'out' && !df.src_id.nil?
          # out w/ src
          v = $abst_variables[df.src_id]
          if v.nil?
            v2 = add_missing_variable(df.src_id)
            if v2.nil?
              $log.error "propagate_policy_to_variables ADD sid=#{df.src_id}  => NG"
            else
              df.src_id = v2.id # Update BAD id
            end
          end
        end
        fail "DEBUG" if df.src_id == 'S_users#each'
      end

      # create alias table of M-CV
      alias_map = {}
      $assets_base_policies.each do |k, v|
        alias_map.merge!(v['model_alias']) unless v['model_alias'].nil?
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

    # stdout policy assignment
    # called from cli.rb
    def print_policy_assignment
      cwidth = $max_id_length
      puts "  Policy assignment"
      puts "  1) MVC states"
      col0 = "state"
      puts " #{col0.rjust(cwidth)}   code  req"
      puts " #{col0.rjust(cwidth)}  (PEP)"
      puts "  --------------------------------------------------------------"
      $abst_states.each do |k, s|
        if s.routed == false
          code_policy_stat = '---'
        elsif s.code_policy.exist?
          if s.code_policy.is_authenticated == false
            if s.code_policy.is_authorized == false
              code_policy_stat = '__ '
            elsif s.code_policy.is_authorized == true
              code_policy_stat = '_A '
            else
              code_policy_stat = 'pub'
            end
          elsif s.code_policy.is_authenticated == true
            if s.code_policy.is_authorized == false
              code_policy_stat = 'A_ '
            elsif s.code_policy.is_authorized == true
              code_policy_stat = 'AA '
            else
              code_policy_stat = 'A_ '
            end
          else
            if s.code_policy.is_authorized == false
              code_policy_stat = '?_ '
            elsif s.code_policy.is_authorized == true
              code_policy_stat = '?A '
            else
              code_policy_stat = 'pub'
            end
          end
        else
          code_policy_stat = "pub"
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

        if s.routed.nil?
          code_policy_stat = '???'
        elsif s.routed == false
          code_policy_stat = '---'
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

        if s.type == 'controller' && s.routed
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

    # Remediation v023
    # RSpec: spec/rails/requirements/json_spec.rb
    def print_sample_requirements(filename = nil)
      model_list = {}

      json = {}

      # roles
      roles = {}

      r0 = {}
      r0['level'] = 10
      r0['color'] = '#BCA352'
      r0['description'] = 'system admin'
      roles['admin'] = r0

      r1 = {}
      r1['level'] = 3
      r1['color'] = '#97A750'
      r1['description'] = 'normal user'
      roles['user'] = r1

      json['roles'] = roles

      # asset_base_policies
      asset_base_policies = {}
      asset_discrete_policies = {}
      json['asset_base_policies'] = asset_base_policies
      json['asset_discrete_policies'] = asset_discrete_policies

      unless $authentication_module.nil?
        $authentication_module.append_sample_requirements(json, model_list)
      end

      unless $authorization_module.nil?
        $authorization_module.append_sample_requirements(json, model_list)
      end

      # for other models
      # puts "    // application models"
      $abst_states.each do |k, s|
        if s.type == 'model'
          m = s.model
          if model_list[m].nil?
            # add tentative policy
            mp = {}

            # TODO: code_policy?
            if s.code_policy.is_authenticated == true
              mp['is_authenticated'] = true
            elsif s.code_policy.is_authenticated == false
              mp['is_authenticated'] = false
            else # NIL
              mp['is_authenticated'] = true
            end

            if s.code_policy.is_authorized == true
              mp['is_authorized'] = true
            elsif s.code_policy.is_authorized == false
              mp['is_authorized'] = false
            else # NIL
              mp['is_authorized'] = false
            end

            if mp['is_authorized']
              mp['level'] = 3
              mp['color'] = 'green'

              roles = {}
              r0 = {}
              r0['role'] = 'admin'
              r0['action'] = 'CRUD'
              roles['admin'] = r0
              r1 = {}
              r1['role'] = 'user'
              r1['action'] = 'CRUD'
              roles['user'] = r1
              mp['roles'] = roles
              mp['commnets'] = 'tentative policy'
            end

            json['asset_base_policies'][m] = mp
          end
        end
      end

      print_json(json, filename)
    end

    def print_json(json, filename)
      out = JSON.pretty_generate(json)
      if filename.nil?
        # STDOUT
        puts "#{out}"
      else
        open(filename, "w") do |f|
          f.write(out)
        end
      end
    end

    #
    def add_discrete_requirement(state)
      @has_remidiation = true
      dp = {}
      if state.code_policy.is_authenticated == false
        dp['is_authenticated'] = false
      elsif state.code_policy.is_authenticated == true
        dp['is_authenticated'] = true
        if state.code_policy.is_authorized == false
          dp['is_authorized'] = false
        elsif state.code_policy.is_authorized == true
          dp['is_authorized'] = true
        else # NIL, Unknown => any role
          dp['is_authorized'] = false
        end
      else # NIL, Unknown => public
        dp['is_authenticated'] = false
        dp['is_authorized'] = false
      end

      if dp['is_authorized']
        dp['level'] = 3
        dp['color'] = 'green'

        r0 = {}
        r0['role'] = 'admin'
        r0['action'] = 'CRUD'

        r1 = {}
        r1['role'] = 'user'
        r1['action'] = 'CRUD'

        dp['roles'] = [r0, r1]
        dp['commnets'] = 'tentative policy'
      end
      @remidiation_json['asset_discrete_policies'][state.id] = dp
    end

    def print_discrete_requirement(filename = nil)
      print_json(@remidiation_json, filename)
    end
  end # class
end # module
