# -*- coding: UTF-8 -*-
# PDP: Policy Decision Point

module Rails
  # PDP class
  class PDP  < Abstraction::SecurityFunction
    # init
    def initialize
      super
      @type = 'access control'
      @name = 'TBD'
      $authorization_method = 'none'
      $warning ||= Warning.new

      # ACL Table
      # H[Subject][Action] = Object
      # TODO: CanCan => conditional Subject may exist. so...
      @subjects = {}
      @objects = {}
      @actions = {}
      @acl_table = Hash.new { |hash, key| hash[key] = Hash.new { } }

      # boolean
      # TODO: remove cancan_
      $cancan_exclusive_subject_condition ||= false
      $cancan_nested_subject_condition ||= false

      # Dashboard
      @unused_table = Hash.new { |hash, key| hash[key] = Hash.new { } }
      @unused_count = 0
      @missing_role_count = 0
      @exist = false

      # 20130817 New! for  RBAC, level,categories
      # 1. set by APP/railroadmap/requirements.rb manually by User
      # 2. set from DB automatically
      # 3. set from seed.db automatically
      @roles = nil

      # set filter list
      $authorization_filter_list = []
    end
    attr_accessor :subjects, :objects, :actions, :acl_table, :unused_count, :exist, :roles

    def get_command_list
      commands = {}
    end
    # Obsolete
    # return ACL table
    def get_acls_old(table)
      $log.debug "get_acls() TODO define"

      # Typical ACL table,
      h = {}
      h['anon'] = ''
      h['user'] = ''
      h['admin'] = ''
      table.each do |t|
        h[t[0]] = t[1]
      end
      return h
    end

    # Pass 1
    # $assets level/categories => $abst_state
    def setup4dashboard_assets
      # level/categories definitions
      count = 0
      unless $assets.nil?
        $assets.each do |domain, policy|
          level    = policy['level']
          category = policy['category']
          if !level.nil? && !category.nil?
            # Controller key
            key = 'C_' + domain
            s = $abst_states[key]
            unless s.nil?
              # Hit
              s.level = level
              s.category = category
              count += 1
            end
          end
        end
      end
      puts "    load policy    : #{count} assets  (level/categories)"
    end

    # Pass 2
    # Dashboard
    def setup4dashboard_roles
      @unused_count = 0

      # Roles definitions  check existance
      if @roles.nil?
        # No
        @roles = {}
        if $roles.nil?
          $log.error "TODO set roles"
          fail "TODO"
        else
          set_roles_from_requirements
        end
      else
        # already defined by ?
      end

      # Prepare for Dashboard
      # 1. Scan assets list
      # 2. unused -> used if used
      return @unused_count, @missing_role_count
    end

    # 20130807
    # Check Role vs Assets
    def set_roles_from_requirements
      # Check Extra role
      count = 0
      @unused_count = 0
      if $roles.nil?
        $log.error "Missing $roles"
      else
        $roles.each do |name, defs|
          if is_unused_role?(name, defs['level'], defs['categories'])  # TODO
            defs['unused'] = true
            @unused_count += 1
          else
            defs['unused'] = false
          end
          @roles[name] = defs
          count += 1
        end
      end

      # Check Missing role (level, categories) (assets)
      @missing_role_count = 0
      $abst_states.each do |d, s|
        if s.type == 'controller' && is_undefined_role(s)
          @missing_role_count += 1
        end
      end

      # Overall score
      if @unused_count > 0 && @missing_role_count > 0
        print "\e[31m"  # red
        puts "    set PDP        : #{count} roles (#{@unused_count} unused, #{@missing_role_count} missing)"
        print "\e[0m"   # reset
      elsif @unused_count > 0
        print "\e[31m"  # red
        puts "    set PDP        : #{count} roles (#{@unused_count} unused)"
        print "\e[0m"   # reset
      elsif @missing_role_count > 0
        print "\e[31m"  # red
        puts "    set PDP        : #{count} roles (#{@missing_role_count} missing)"
        print "\e[0m"   # reset
      else
        print "\e[32m"  # green
        puts "    set PDP        : #{count} roles (all used)"
        print "\e[0m"   # reset
      end
    end

    # Check
    #
    #   Roles              Assets
    #   level categories   level categories      level   categories
    #   ----------------------------------------------------------------------
    #   5     10           5     10              5 == 5  10 == 10     Hit!
    #   5     10           1     10              5 >  1  10 == 10     Hit?
    #   5     10           10    10              5 <  10 10 == 10     Miss
    #   5     10           5     20              5 == 5  10 != 20     Miss
    #  -----------------------------------------------------------------------
    # 20131030 Update
    # categories => deprecated
    def is_unused_role?(name, level, categories)
      # check all controller
      hit_count = 0
      $abst_states.each do |d, s|
        if s.type == 'controller'
          s.req_policies.each do |p|
            unless p.role_list.nil?
              p.role_list.each do |r|
                hit_count += 1 if r[:role] == name
              end
            end
          end
        end
      end

      if hit_count > 0
        puts "    Role '#{name}' is used by #{hit_count} assets"
        return false # USED
      else
        print "\e[31m"  # red
        puts "    Role '#{name}' is not used by any assets"
        print "\e[0m"   # reset
        return true # UNUSED
      end
    end

    # check Asset
    #   level, category  <= $roles
    def is_undefined_role(state)
      if !$roles.nil? && !state.code_policy.level.nil? && !state.code_policy.category.nil?
        $roles.each do |name, defs|
          unless defs['level'].nil?
            if state.code_policy.level.class == String  # Missing
              # NA
              $log.error "is_undefined_role() state #{state.id} missing policy"
            elsif defs['level'] >= state.code_policy.level then
              defs['categories'].each do |c|
                if c == state.code_policy.category
                  # HIT
                  return false
                end
              end
            end
          end
        end
      else
        return false
      end

      # Miss
      state.undefined_role = true
      state.is_unclear_pdp = true
      print "\e[31m"  # red
      puts "    Asset '#{state.id}' has policy, level=#{state.level}, category=#{state.category}, but no role defined for this"
      print "\e[0m"   # reset
      return true
    end

    # Obsolete
    # Dashboard
    # unused array[subject, object] and count
    def setup4dashboard_old
      @unused_count = 0
      @acl_table.each do |o, v1|
        v1.each do |a, v2|
          v2.each do |s, v3|
            if v3 == 0
              # this ACL is used in code.
              @unused_table[s][o] = false
            else
              # this ACL is not used in the code
              @unused_table[s][o] = true
              @unused_count  += 1
            end
          end
        end
      end
    end

    def generate_pdp(filename)
      puts "    Generate PDP is not yet supported by our '#{@name}' library"
    end
  end # class
end
