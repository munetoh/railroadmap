# -*- coding: UTF-8 -*-
# The Role
#   Authorization for Rails 4 + admin UI. Semantic, Flexible, Lightweight
#   https://github.com/the-teacher/the_role
#
# Design pattern?
#   *
#   * provides admin controller and view (Haml. CSS) for role model
#   * before_filter
#
# Controller
#   before_action :login_required, except: [:index, :show]
#   before_action :role_required,  except: [:index, :show]
#   before_action :owner_required, only: [:edit, :update, :destroy]
#   before_action :set_page,       only: [:edit, :update, :destroy]
#
# View
#  @user.has_role?(:pages, :show)
#  <% if @user.has_role?(:twitter, :button) %>
#  <% if @user.has_role?(:apptyps, :index) %>   =>
# [:if,
#  [:method_add_arg,
#   [:call,
#    [:var_ref, [:@ivar, "@user", [9, 6]]],
#    :".",
#    [:@ident, "has_role?", [9, 12]]],    <<<<  call @ident
#   [:arg_paren,
#    [:args_add_block,
#     [[:symbol_literal, [:symbol, [:@ident, "apptyps", [9, 23]]]],
#      [:symbol_literal, [:symbol, [:@ident, "index", [9, 33]]]]],
#     false]]],

#
module Rails
  # Commands
  # has_role?(model,asset)
  class HasRoleQCommand < Abstraction::Command
    def initialize
      super
      @name       = 'has_role?'
      @type       = 'filter'
      @is_sf      = true
      @sf_type    = "authorization"
      @providedby = 'the_role'
    end

    # Abst
    def abstract(sexp, sarg, filename)
      super
    end

    # Verify call
    def verify_call(sexp, dst_id)
      s = get_sexp(sexp, :arg_paren)
      if s.nil?
        $log.error "TODO s == nil"
        pp sexp
      else
        model  = s[1][1][0][1][1][1].singularize
        action = s[1][1][1][1][1][1]
        state = $abst_states[dst_id]
        if state.nil?
          $log.error "TODO"
        else
          if state.model ==  model && state.action == action
            return true
          elsif state.model == $alias_model[model] && state.action == action
            $log.debug "TODO alias #{model}->#{$alias_model[model]} #{action}"
            return true
          else
            $log.error "TODO bad call #{model} #{action}"
          end
        end
      end
      $log.error "verify_call(#{dst_id})  fail"
      return false
    end
  end

  # PDP class of The_Role
  class TheRole < Rails::PDP
    # init
    def initialize
      super
      @name = 'the_role'
      @type = 'rbac'
      @exist = true

      $authorization_filter_list = ['has_role?']
    end

    # commands
    def add_commands
      c1 = HasRoleQCommand.new
      $abst_commands[c1.name] = c1
    end

    # 20130813 TODO: edit_admin_role_path is not a command, but a path
    def get_command_list
      the_role_commands = {
        # app/models/concerns/the_role_base.rb:  def any_role? roles_hash = {}
        'any_role?' => {
          type:       'unknown_filter',
          providedby: 'the_role'
        },

        # 20130815
        # The_Role do alias "has?"" => "has_role?", so put has? dummy here , "any?" also
        'has?' => {
          type:       'unknown',
          providedby: 'the_role'
        },
        'any?' => {
          type:       'unknown',
          providedby: 'the_role'
        },

        # {"filename"=>"the_role/app/controllers/the_role_controller.rb"}
        'role_required' => {
          type:       'filter',
          is_sf:      true,
          sf_type:    'authorization',
          providedby: 'the_role'
        },

        # {"filename"=>"the_role/app/controllers/admin/role_sections_controller.rb"}
        'section_rule_names' => {
          type:       'unknown_filter',
          providedby: 'the_role'
        },

        # {"filename"=>"the_role/app/controllers/admin/roles_controller.rb"}
        'role_find' => {
          type:       'unknown_filter',
          providedby: 'the_role'
        },

        # {"filename"=>"the_role/app/controllers/the_role_controller.rb"}
        'owner_required' => {
          type:       'filter',
          is_sf:      true,
          sf_type:    'owner_authorization',
          providedby: 'the_role'
        },

        # lib/the_role/config.rb:    config_accessor :layout, :default_user_role
        'layout' => {
          type:       'unknown_filter',
          providedby: 'the_role'
        },

        # the_role/app/controllers/admin/role_sections_controller.rb
        'redirect_to_edit' => {
          type:            'transition',
          subtype:         'redirect_to',
          transition_path: 'edit_admin_role_path',
          providedby:      'the_role' },

        # app/controllers/the_role_controller.rb:  def role_access_denied
        'role_access_denied' => {
          type:       'unknown_filter',
          providedby: 'the_role'
        },

        # IGNORE
        'edit_admin_role_path' => {
          type:       'path',
          providedby: 'the_role'
        },
      }
    end

    # Requiremrnts
    #
    def access_control_table
      super
    end

    # lookup the policy list
    def is_listed?(role_list, role)
      role_list.each do |r|
        return true if r[:role] == role
      end
      return false
    end

    # PDP
    # true   Allow
    # false  Deny
    # nil    no auth
    def is_authorized?(state, role)
      if state.req_policies.length == 1
        p = state.req_policies[0]
        if p.role_list.nil?
          return nil
        else
          p.role_list.each do |r|
            if r[:role] == role
              # hit
              action = r[:action]
              if action == 'CRUD'
                # any action => OK
                return true
              elsif action == 'CRU'
                if state.action == 'destroy'
                  return false
                else
                  return true
                end
              elsif action == 'R'
                # index show
                if state.action == 'index' || state.action == 'show'
                  return true
                end
              else
                $log.error "is_authorized?() TODO unknown action=#{action}"
              end
            end # hit
          end # role list
        end
      else
        $log.error "is_authorized?() TODO not support multiple policies"
      end
      return false
    end

    def generate_pdp(filename)
      filename = 'railroadmap/seed.rb' if filename.nil?

      open(filename, 'w') do |f|
        f.write("# The_Role ACL seed generated by RailroadMap from railroadmap/requirements\n")
        $roles.each do |role, v1|
          desc = v1[:description].gsub(/[ \/]/, '_')  # no space etc
          if role == 'admin'
            f.write("Role.create!(\n")
            f.write("  name:        :admin,\n")
            f.write("  title:       :admin,\n")
            f.write("  description: :#{desc},\n")
            f.write("  the_role: {\n")
            f.write("    system: {\n")
            f.write("      administrator: true \n")
            f.write("    }\n")
            f.write("  }\n")
            f.write(")\n")
          else
            f.write("Role.create!(\n")
            f.write("  name:        :#{role},\n")
            f.write("  title:       :#{role},\n")  # TODO: ?
            f.write("  description: :#{desc},\n")
            f.write("  the_role: {\n")

            # Model
            $assets_base_policies.each do |model, v2|
              if is_listed?(v2[:roles], role)
                models = model.pluralize
                f.write("      #{models}: {\n")
                # Model - Controller => action:   true|false
                $abst_states.each do |k, s|
                  if s.type == 'controller' && s.model == model
                    action = s.action + ':'
                    ans    = is_authorized?(s, role)
                    if ans.nil?
                      action = '# ' + s.action + ' does not have authorization check (public access)'
                      f.write("        #{action.rjust(10)} #{ans},\n")
                    else
                      f.write("        #{action.rjust(10)} #{ans},\n")
                    end
                  end
                end
                f.write("      }\n")
              else
                f.write("      # no ACL for #{models}\n")
              end
            end

            f.write("    }\n")
            f.write("  }\n")
            f.write(")\n")
            f.write("\n")
          end
        end
        f.write("p \"Roles created\"\n")
      end # open
      puts "    PDP file: #{filename}"
    end
  end
end
