# -*- coding: UTF-8 -*-
# Security check
# TODO: update, cancan => any

module Rails
  # Security check
  class SecurityCheck
    def initialize
      @securitycheck = {}
      scan_info      = {}
      $warning ||= Warning.new
      scan_info['app_path'] = $approot_dir
      scan_info['number_of_states'] = $abst_states.size
      scan_info['number_of_transitions'] = $abst_transitions.size

      puts "    Static security test (PEP@controller check)"
      # PEP - Controller
      check_missing_authentication
      check_missing_authorization

      if $warning.count > 0
        puts "    Static security test (PEP@view check, Navigation error) - SKIP"
        puts "    Static security test (dataflow check) - SKIP"
      else
        # PEP - View
        puts "    Static security test (PEP@view check, Navigation error)"
        check_inconsistent_authentication
        check_inconsistent_authorization
        # DF in and out
        puts "    Static security test (dataflow check)"
        check_inconsistent_dataflow
      end

      # TODO: deprecated
      # if $use_cancan
      #   check_inconsistent_authorization_cancan1
      #   check_inconsistent_authorization_cancan2
      #   # check_inconsistent_authorization_cancan3
      #   check_inconsistent_authorization_cancan4
      #   check_inconsistent_authorization_cancan5
      # end

      # Show result
      if $warning.count > 0
        print "\e[31m"  # red
        puts "    warnings : #{$warning.count} (access control)"
        # puts ""
        # suppress False-Positive
        # $warning.suppress_falsepositive
        # Remidiation for FP
        # $warning.print_falsepositive_mask
        # puts ""
      else
        print "\e[32m"  # green
        puts "    warnings : #{$warning.count}  (access control)"
      end
      print "\e[0m" # reset

      # Prepare for JSON out
      scan_info['security_warnings'] = $warning.count
      @securitycheck['scan_info'] =  scan_info
      @securitycheck['warnings'] =  $warning.warnings  # Array
    end

    #--------------------------------------------------------------------------
    # Check missing authentication
    def check_missing_authentication_v010
      # requirement error (req_error) flag
      #
      # default => false
      # lib/rails/requirement.rb => set true
      $abst_states.each do |n, s|
        if s.req_error
          w = Hash.new
          w['warning_type'] = 'Missing authentication'
          w['message'] = "No authentication for #{s.domain}"  # TODO: get URL also
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'Medium'    # Weak Medium High
          $warning.add(w)
        end
      end
    end

    def print_pep_error(state, type)
      print "\e[31m" # Red
      puts "      Missing PEP(#{type})  #{state.id}"
      print "\e[0m" # reset
    end

    def check_missing_authentication
      $abst_states.each do |n, s|
        if s.type == 'controller' && !s.req_policies[0].nil?
          if s.req_policies[0].is_authenticated
            if s.code_policy.is_authenticated
              # Good
            else
              # No PEP
              s.req_error = true
              type = 'Missing authentication'
              msg = "[Req:O, Code:X] No authentication for #{s.domain}"  # TODO: get URL also
            end
          else
            if s.code_policy.is_authenticated
              # No Req
              s.req_error = true
              type = 'Missing authentication'
              msg = "[Req:X, Code:O] No authentication for #{s.domain}"  # TODO: get URL also
            else
              # God public
            end
          end
        end

        if s.req_error
          w = Hash.new
          w['warning_type'] = type
          w['message'] = msg
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'High'    # Weak Medium High
          $warning.add(w)

          print_pep_error(s,  'authentication')
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check authorization at controller
    def check_missing_authorization
      $abst_states.each do |n, s|
        if s.type == 'controller' && !s.req_policies[0].nil?
          if s.req_policies[0].is_authorized
            if s.code_policy.is_authorized
              # Good
            else
              # No PEP
              s.req_error = true
              type = 'Missing authorization'
              msg = "[Req:O, Code:X] No authorization for #{s.domain}"  # TODO: get URL also
            end
          else
            if s.code_policy.is_authorized
              # No Req
              s.req_error = true
              type = 'Missing authorization'
              msg = "[Req:X, Code:O] No authorization for #{s.domain}"  # TODO: get URL also
            else
              # God public
            end
          end
        end

        if s.req_error
          w = Hash.new
          w['warning_type'] = type
          w['message'] = msg
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'High'    # Weak Medium High
          $warning.add(w)

          print_pep_error(s, 'authorization')
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check authentication authorization at view
    # Here, we trust PEP@Controller code (consistent w/ req)
    def print_nav_error(trans, ssl, dsl)
      print "\e[36m" # Cyan
      puts "      Navigation error? #{trans.src_id}[lv:#{ssl}] => #{trans.dst_id}[lv:#{dsl}]"
      print "\e[0m" # reset
    end

    def check_inconsistent_authentication
      $abst_transitions.each do |n, t|
        unless t.dst_id.nil?
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authenticated
            # PEP exist@controller

            if t.authentication_filter
              # Has PEP
              # $log.error "check_inconsistent_authentication #{t.id} has PEP"
            else
              # No PEP
              # same domain?
              if ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authenticated
                  # $log.error "check_inconsistent_authentication #{t.id} no PEP but auth state"
                else
                  # $log.error "check_inconsistent_authentication #{t.id} no PEP - ERROR"
                  t.nav_error = true
                  ss.nav_error  = true
                  w = Hash.new
                  w['warning_type'] = 'Missing view side authentication check'
                  w['message'] = "View #{ss.domain} has NO-authentication check, but enforcement at controller side #{ds.domain}."
                  w['file'] = t.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_nav_error(t, ss.code_policy.level, ds.code_policy.level)
                end
              else
                # $log.error "check_inconsistent_authentication #{t.id} no PEP many pol - TODO"
              end
            end
          end
        end
      end
    end

    def check_inconsistent_authorization
      $abst_transitions.each do |n, t|
        unless t.dst_id.nil?
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authorized
            # PEP exist@controller

            # update filter check
            t.authorization_filter = t.block.get_authorization_filter
            if t.authorization_filter
              # Has PEP
              # $log.error "check_inconsistent_authorization #{t.id} has PEP"
            else
              # No PEP
              # same domain?
              if ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authorized
                  # $log.error "check_inconsistent_authorization #{t.id} no PEP but auth state"
                else
                  # $log.error "check_inconsistent_authorization #{t.id} to #{ds.id} no PEP - ERROR"
                  # p t.guard
                  t.nav_error = true
                  ss.nav_error  = true
                  w = Hash.new
                  w['warning_type'] = 'Missing view side authorization check'
                  w['message'] = "View #{ss.domain} has NO-authorization check, but enforcement at controller side #{ds.domain}."
                  w['file'] = t.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_nav_error(t, ss.code_policy.level, ds.code_policy.level)
                end
              else
                # $log.error "check_inconsistent_authorization #{t.id} no PEP many pol - TODO"
              end
            end
          end
        end
      end
    end

    #---------------------------------------------------------------------------
    def print_df_error(df, ssl, dsl)
      print "\e[35m" # purpule
      puts "      suspicuous dataflow H2L #{df.src_id}[lv:#{ssl}] => #{df.dst_id}[lv:#{dsl}]"
      print "\e[0m" # reset
    end

    def check_inconsistent_dataflow
      $abst_dataflows.each do |n, df|
        if df.type == 'out' && !df.src_id.nil? && !df.dst_id.nil?
          ss = $abst_variables[df.src_id]
          ds = $abst_states[df.dst_id]

          unless ss.nil? || ds.nil?
            # $log.error "check_inconsistent_dataflow HIT #{ss.id} #{ds.id}"
            unless ss.code_policy.nil? || ds.code_policy.nil?
              unless ss.code_policy.level.nil? || ds.code_policy.level.nil?
                # $log.error "check_inconsistent_dataflow HIT #{ss.code_policy.level} VS #{ds.code_policy.level}"
                if ss.code_policy.level > ds.code_policy.level
                  # $log.error "check_inconsistent_dataflow HIT #{ss.code_policy.level} => #{ds.code_policy.level}"

                  df.df_error = true
                  ds.df_error  = true
                  w = Hash.new
                  w['warning_type'] = 'High to low dataflow'
                  w['message'] = "View #{ds.domain} has high to low dataflow"
                  w['file'] = ds.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_df_error(df, ss.code_policy.level, ds.code_policy.level)
                end
                # set policy level to DF
                df.src_level = ss.code_policy.level
                df.dst_level = ds.code_policy.level
              end
            end
          end
        end
      end
    end

    #---------------------------------------------------------------------------
    # TODO: move to cancan.rb?, mirate to generic $authorization
    # CanCan deprecated
    # Ability.rb <-> controllers
    #
    def check_inconsistent_authorization_cancan1
      $authorization_module.subjects.each do |s, v1|
        # Subjects
        $authorization_module.objects.each do |o, v2|
          # Objects
          # Actions
          as = $authorization_module.get_action(s, o)
          as.each do |a|
            if a[1] == 'NA'
              w = Hash.new
              w['warning_type'] = 'Missing enforcement'
              w['message'] = "No enforcement code for #{s}:#{a[0]}:#{o}. Or unnecessary access control definition."  # TODO: get URL also
              w['file'] = nil # TODO: controller
              w['line'] = nil
              w['code'] = nil
              w['location'] = nil
              w['user_input'] = nil
              w['confidence'] = 'Medium'    # Weak Medium High
              $warning.add(w)
            end
          end
        end
      end
    end

    # View(check) --> Controllers(no check)
    #
    # 1) V->C transition has cancan check
    # 2) dist controller state does not have check => ERROR
    #
    # This simply check the existance of guard and PEP.
    # This does not check the gurd and policy itself. <= TODO
    def check_inconsistent_authorization_cancan2
      $abst_transitions.each do |n, t|
        unless t.cancan.nil?
          # trans has cancan check
          if t.dst_id.nil?
            $log.debug "#{t.src_id} => has CanCan check. But UNKNOWN dst. please check the nav. model"
          else
            # Get state
            ss = $abst_states[t.src_id]
            ds = $abst_states[t.dst_id]
            if ds.nil?
              # TODO: path?
              $log.error "#{t.src_id} => has CanCan check. But UNKNOWN dst "
              w = Hash.new
              w['warning_type'] = 'Missing controller side authorization check'
              w['message'] = "View #{t.src_id} has authorization check, can not find destination controller. TBD"  # TODO: get URL also
              w['file'] = nil # TODO: controller
              w['line'] = nil
              w['code'] = nil
              w['location'] = nil
              w['user_input'] = nil
              w['confidence'] = 'Weak'    # Weak Medium High
              $warning.add(w)
            else
              if ds.authorize == true
                # OK
                $log.debug "#{t.src_id} => #{t.dst_id} PEP => OK"
              elsif ds.cancan.nil?
                # TODO: check transition  with cancan guard or not
                $log.debug "#{t.src_id} => #{t.dst_id} NO CANCAN PEP => ERROR (No protection for direct access)"
                w = Hash.new
                w['warning_type'] = 'Missing controller side authorization check'
                w['message'] = "View #{ss.domain} has authorization check, but no enforcement at controller side #{ds.domain}"  # TODO: get URL also
                w['file'] = nil # TODO: controller
                w['line'] = nil
                w['code'] = nil
                w['location'] = nil
                w['user_input'] = nil
                w['confidence'] = 'High'    # Weak Medium High
                $warning.add(w)
              else
                # TODO: check ACL is same or not
                $log.debug "#{t.src_id} => #{t.dst_id} <= CANCAN, #{t.cancan} VS #{ds.cancan}. GOOD!"
              end
            end
          end
        end
      end # do
    end

    # View(check) --> Controllers(no check)  <=== OLD, obsolete
    #
    # 1) View State has cancan check
    # 2) follow transitions
    # 3) dist controller state does not have check => ERROR
    #
    def check_inconsistent_authorization_cancan3
      $abst_states.each do |n1, s|
        if s.type == 'view' && !s.cancan.nil?  # TODO: cancan?
          $log.error "View with cancan guard at #{s.domain}"
          # looking fo the trans from this state
          $abst_transitions.each do |n2, t|
            if t.src_id == s.id
              if t.dst_id.nil?
                $log.error "#{s.id} => UNKNOWN"
              else
                $log.error "#{s.id} => #{t.dst_id}"
                # Get state
                ds = $abst_states[t.dst_id]
                if ds.nil?
                  # TODO: path?
                  $log.error "#{s.id} => #{t.dst_id} <= UNKNOWN"
                  w = Hash.new
                  w['warning_type'] = 'Missing controller side authorization check'
                  w['message'] = "View #{s.domain} has authorization check, can not find destination controller. TBD"  # TODO: get URL also
                  w['file'] = nil # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)
                else
                  if ds.authorize == true
                    # OK
                  elsif ds.cancan.nil?
                    # TODO: check transition  with cancan guard or not
                    $log.error "#{s.id} => #{t.dst_id} <= NO CANCAN <= ERROR"
                    w = Hash.new
                    w['warning_type'] = 'Missing controller side authorization check'
                    w['message'] = "View #{s.domain} has authorization check, but no enforcement at controller side #{ds.domain}"  # TODO: get URL also
                    w['file'] = nil # TODO: controller
                    w['line'] = nil
                    w['code'] = nil
                    w['location'] = nil
                    w['user_input'] = nil
                    w['confidence'] = 'Medium'    # Weak Medium High
                    $warning.add(w)
                  else
                    # TODO: check ACL is same or not
                    $log.error "#{s.id} => #{t.dst_id} <= CANCAN, #{s.cancan} VS #{ds.cancan}"
                  end
                end
              end
            end
          end # do
        end
      end
    end

    # --> View(no check) --> Controllers(check)
    #   C(nac) -> V(nac) -> C(ac)  <= Navigation error
    #   C(ac1) -> V(nac) -> C(ac2) <= ac1==ac2 then OK, else error
    #
    # 1) Controller with authorization check
    # 2) ftans to this
    #
    # depends on context
    # Trace by role?
    #
    # This check => simpliy check all transision and dest.
    def check_inconsistent_authorization_cancan4
      $abst_transitions.each do |n, t|
        if t.cancan.nil?
          # trans does not have cancan check/guard
          unless t.dst_id.nil?
            ss = $abst_states[t.src_id]
            ds = $abst_states[t.dst_id]
            if !ds.nil? && ss.type == 'view'
              if ds.authorize == true
                # PEP exist
                $log.debug "#{t.src_id} => #{t.dst_id} PEP => exist but no guard 1"
                # Get ACL
                raas = $authorization_module.get_role_and_action(ds.domain)
                w = Hash.new
                w['warning_type'] = 'Missing view side authorization check'
                w['message'] = "View #{ss.domain} has NO-authorization check, but enforcement at controller side #{ds.domain}. ACL is #{raas}"  # TODO: get URL also
                w['file'] = t.filename # TODO: controller
                w['line'] = nil
                w['code'] = nil
                w['location'] = nil
                w['user_input'] = nil
                w['confidence'] = 'Weak'    # Weak Medium High
                $warning.add(w)
              elsif ds.cancan == true
                # TODO: check transition  with cancan guard or not
                $log.error "#{t.src_id} => #{t.dst_id} PEP => exist but no guard 2"
              end
            end
          end
        end
      end
    end

    # TODO: role based check
    # Emulate all transitions with PEP/PDP
    # 1) select role
    # 2) start trans
    # 3) check PEP/PDP
    # 4) error => Navigation error => Missing guard at View
    # 5) end. back too start page, loop,
    $trace_hop_max = 10
    $trace_count_max = 5

    def trace_trans(state, role, hop)
      return if state.nil?
      return if hop > $trace_hop_max

      # state --> trans
      $abst_transitions.each do |n, t|
        if t.src_id == state.id
          # find trans from this state
          ss = $abst_states[t.src_id]
          if t.dst_id.nil?
            $log.debug "UNKNOWN dst - Update Nav. model"
          else
            ds = $abst_states[t.dst_id]
            unless t.cancan.nil? # TODO: cancan
              # TODO: Check guard (PDP/PEP)
              # TODO: check gurd
              res = $authorization_module.pdp(role, ds.domain)
              if res == false
                @pep_count += 1
                return
              end
            end

            return if t.trace_count > $trace_count_max

            # Move to next state
            t.trace_count += 1
            # Check V->C PEP/PDP at state
            if !ds.nil? && !ds.authorize.nil? && ss.type == 'view'
              res = $authorization_module.pdp(role, ds.domain)
              if res == false
                raas = $authorization_module.get_role_and_action(ds.domain)
                $log.debug "#{hop} NAV ERROR #{t.id}    #{t.src_id} => #{t.dst_id}  (cancan guarded)"
                w = Hash.new
                w['warning_type'] = 'Missing view side authorization check'
                w['message'] = "#{ss.type} View #{ss.domain} has NO-authorization check, but enforcement at controller side #{ds.domain}. Rejected role is #{role}. ACL is #{raas}"  # TODO: get URL also
                w['file'] = t.filename # TODO: controller
                w['line'] = nil
                w['code'] = nil
                w['location'] = nil
                w['user_input'] = nil
                w['confidence'] = 'Weak'    # Weak Medium High
                $warning.add(w)
              else
                # PEP/PDP ok
                # p "#{hop} ACCESS #{t.id}    #{t.src_id} => #{t.dst_id}  (no cancan guard)"
              end
            else
              # TODO: NO PEP is OK
              # p "#{hop} NO PEP #{t.id}    #{t.src_id} => #{t.dst_id}  (no cancan guard)"
            end
            # Go next trans
            trace_trans(ds, role, hop + 1)
          end
        end
      end
    end

    #
    def check_inconsistent_authorization_cancan5
      $log.debug "check_inconsistent_authorization_cancan5"
      # check
      abort = false
      if $roles.nil?
        $log.error("Set $roles in railroadmap/requirements.rb")
        $log.error(" #{$authorization_module.subjects}")
        abort = true
      end

      if $start_state.nil?
        $log.error("Set $start_state in railroadmap/requirements.rb")
        abort = true
      end

      if abort
        $log.error "Abort check_inconsistent_authorization_cancan5"
        return
      end

      $roles.each do |role|
        # Reset trace_count
        $abst_transitions.each do |n, t|
          t.trace_count = 0
        end
        @pep_count = 0
        # Start
        $start_state.each do |s|
          ss = $abst_states[s]
          trace_trans(ss, role, 0)
        end
        # Summary, Coveradge
        sum = Hash.new
        $abst_transitions.each do |n, t|
          if sum[t.trace_count].nil?
            sum[t.trace_count] = 1
          else
            sum[t.trace_count] += 1
          end
          # if t.trace_count == 0
          #   p "#{t.src_id} =#{t.type}=> #{t.dst_id}"
          # end
        end
        puts "  role #{role} : trace coveradge on nav-model #{sum}, #{@pep_count} PEP blockes"
      end # roles
    end

    #---------------------------------------------------------------------------------
    # JSON out
    def save_json(filename)
      File.open(filename, "w") do |f|
        f.write(JSON.pretty_generate(@securitycheck))
      end
    end

    def load(requirements_req, requirements_file)
      require requirements_req
      $log.debug "loaded existing requirements file #{requirements_file}"

      # check 1
      unless $authentication_module.nil?
        puts "  authentication: #{$authentication_module.name}"
        # add assets
        # TODO: move to rails/devise
        # Sign in
        $authentication_module.set_access_control_table
      end

      if $use_cancan == true && $ac_type != 'rbac'
        puts "  ERROR - aplication using CanCan, set $ac_type to rbac"
      else
        puts "  authorizarion : CanCan"
      end

      # TODO: move to requirements.rb
      # check 2, req. vs. state prop
      remidiation  = "# railroadmap/requirements.rb\n"
      remidiation << "#   $assets\n"
      remidiation << "---\n"
      remidiation << "  #  From code\n"
      level = 30
      remidiation_count = 0

      $abst_states.each do |n, s|
        if s.type == 'controller'
          domain_name = "'#{s.domain}'"
          if $assets[s.domain].nil?
            # MISS => Default
            if s.is_protected != true && s.is_authenticated != true
              # Missing auth? in requirment
              $log.error "No auth for #{s.id}, add before_filter :authenticate_user OR add asset '#{s.domain}' => [['anon','r']] in requirement.rb"
              s.req_error = true
              remidiation << "  #{domain_name.rjust(level)} => [['anon','r']], # #{s.filename[0]}\n"
              remidiation_count += 1
            end
          else
            # Hit with assets[]
            # get ACL hash for this asset
            acl = $authorization_module.get_acls($assets[s.domain]) # hash
            if acl['anon'] == ''
              # authentication requires
              if s.is_authenticated != true
                # Missing auth? in requirment
                puts "    No auth 1 - #{s.id}"
                $log.error "No auth for #{s.id}, add before_filter :authenticate_user OR add asset '#{s.domain}' => [['anon','r']] in requirement.rb "
                s.req_error = true
                remidiation << "  #{domain_name.rjust(level)} => [['anon','r']],\n"
                remidiation_count += 1
              end
              # authorization
              if acl['admin'] != ''
                if s.authorize.nil?
                  puts "   No ACL code for #{s.id}"
                  $log.error "No ACL for #{s.id}, add authorize!"
                  s.req_error = true
                  remidiation_count += 1
                else
                  # TODO: set ACL for this state
                  puts "    ACL for #{s.id} is role == admin"  # TODO
                end
              end
            end
          end
        end  # controller
      end

      if remidiation_count > 0
        # Print remidiation
        puts "# #{remidiation_count} errors"
        remidiation << "  # Should be\n"
        remidiation << "---\n"
        puts remidiation
      end

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
          f.write "# Account, name => role\n"
          f.write "$users  = {\n"
          f.write "  'anon'  => 'anon',\n"
          f.write "  'user0' => 'user',\n"
          f.write "  'user1' => 'user',\n"
          f.write "  'admin' => 'admin',\n"
          f.write "}\n"
          f.write "\n"
          f.write "# Asset, name => [role,crud]\n"
          f.write "#   if you using devise, no need to specified assets for them.\n"
          f.write "$assets = {\n"
          f.write "  'default'  => [['user','crud'],['admin','crud']],\n"
          f.write "}\n"
          f.write "\n"
          f.write "# EOF\n"
        end # do
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
