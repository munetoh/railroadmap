# -*- coding: UTF-8 -*-
#  Devise
#
# 2013-12-19 commands => devise.json

###############################################
#
#
module Rails
  # SF Devise
  class Devise < Abstraction::SecurityFunction
    def initialize
      super
      @name = 'devise'
      @type = 'access control'

      $authentication_method = 'devise'
      $device_features = {}
      $device_features['confirmation'] = false
      $device_features['omniauth_callback'] = false
      $device_features['registration'] = true # TODO
      $device_features['session'] = true # TODO
      $device_features['password'] = true # TODO
      $device_features['unlock'] = false
      $device_features['mailer'] = false

      # TODO: add devise path, => set by conf
      $path2id['new_session_path']  = 'C_devise:session#new'    # user_session
      $path2id['new_password_path'] = 'C_devise:password#new'  # user_password
      $path2id['new_registration_path']   = 'C_devise:registration#new'  # user_registration
      $path2id['edit_registration_path']   = 'C_devise:registration#edit'

      $path2id['edit_password_url']   = 'C_devise:password#edit'

      # TODO: tentative
      $path2id['after_sign_out_path_for']   = 'C_devise:session#new'
      $path2id['after_unlock_path_for']   = 'C_devise:session#new'
      $path2id['after_omniauth_failure_path_for']   = 'C_devise:session#new'
      $path2id['after_confirmation_path_for']   = 'C_devise:session#new'
      $path2id['omniauth_authorize_path']   = 'C_devise:session#new'
      $path2id['new_confirmation_path']   = 'C_devise:session#new'
      $path2id['confirmation_url']   = 'C_devise:session#new'
      $path2id['new_unlock_path']   = 'C_devise:session#new'
      $path2id['unlock_url']   = 'C_devise:session#new'

      # "Cancel my account", registration_path(resource_name, ), :data => {:confirm => "Are you sure?"}, :method => :delete,
      $path2id['registration_path']   = 'C_devise:session#new'  # TODO: tentative
    end

    def get_commands
      fail "use get_command_list()"
    end

    def get_command_list
      nil
    end

    # Requirements
    # set ACL for devise states
    # 20130812 This list must be set by user.  move to $assets_remediation
    # 20130812 device v3 use explicit command require_no_authentication
    def set_access_control_table
      # Public states
      # Sihn in
      $asset_remediations['devise:session#new']         = [['anon', 'cr']]
      $asset_remediations['devise:session#create']      = [['anon', 'cr']]
      # Sign up
      $asset_remediations['devise:registration#new']    = [['anon', 'cr']]
      $asset_remediations['devise:registration#create'] = [['anon', 'cr']]
      $asset_remediations['devise:registration#cancel'] = [['anon', 'c']]
      # Reset PW
      $asset_remediations['devise:confirmation#new']    = [['anon', 'cr']]
      $asset_remediations['devise:confirmation#create'] = [['anon', 'cr']]

      $log.error "set_access_control_table"
      fail "DEBUG"
    end

    # called by ast.rb through device command at model
    def config(sexp, filename)
      sarg = sexp[2]
      flist = get_hash(sarg)
      $log.debug "command devise #{flist} #{filename}"
      if flist['rememberable']
        $log.debug "devise rememberable => add variable, boolean user#remember_me"
        add_variable('devise', 'user#remember_me', 'boolean', filename)
      end
      if flist['registerable']
        $log.debug "devise registerable => add variable, string  user#current_password"
        add_variable('devise', 'user#current_password', 'string', filename)
      end

      $device_features = flist

      # common
      v = add_variable('devise', 'devise#user_signed_in?', 'string', 'model/dummy.rb')
      v.origin = 'auto'
      $map_variable = {} if $map_variable.nil?
      $map_variable['devise#user_signed_in?'] = ['boolean', 'signed_in']
      $log.info "Added variables, devise#user_signed_in? for devise. "
    end

    #--------------------------------------------------------------------------
    # Code side
    # called after load
    def compleate_pep_assignment
      puts "    Devise: compleate PEP assignment"
      # Transitions
      # set V->C edge
      $abst_transitions.each do |k, t|
        src = $abst_states[t.src_id]
        dst = $abst_states[t.dst_id]
        if !src.nil? && !dst.nil?
          if src.type == 'view' && dst.type == 'controller'
            t.authentication_filter = t.block.get_authentication_filter
          end
        end
      end
    end

    def print_stat
      # commands
      puts ""
      puts "    #{@name} commands"
      puts "                                  Command    count"
      puts "  ------------------------------------------------------------------"
      $abst_commands.each do |k, c|
        # set color
        if c.providedby == @name # 'cancan'
          count = c.count.to_s
          puts "  #{c.name.rjust(40)}  #{count.rjust(6)}"
        end
      end
      puts "  ------------------------------------------------------------------"
    end

    #--------------------------------------------------------------------------
    # Req side
    # v023 uses JSON
    # RSpec: spec/rails/requirements/json_spec.rb
    def append_sample_requirements(json, model_list)
      # asset_base_policies
      model_alias = {}
      model_alias['devise:registration'] = 'user'
      model_alias['devise:session'] = 'user'
      model_alias['devise:password'] = 'user'
      model_alias['devise:confirmation'] = 'user'
      model_alias['devise:unlock'] = 'user'
      model_alias['devise:omniauth_callback'] = 'user'

      user = {}
      user['model_alias'] = model_alias
      user['is_authenticated'] = true
      user['level'] = 10
      user['color'] = 'orange'
      unless $authorization_module.nil?
        user['is_authorized'] = true

        r0 = {}
        r0['role'] = 'admin'
        r0['action'] = 'CRUD'

        r1 = {}
        r1['role'] = 'user'
        r1['action'] = 'CRU'
        r1['is_owner'] = true
        roles = [r0, r1]
        user['roles'] = roles
      end
      json['asset_base_policies']['user'] = user

      # asset_discrete_policies
      # public
      policy = {}
      policy['is_authenticated'] = false
      policy['level'] = 0
      policy['color'] = 'green'

      json['asset_discrete_policies']['C_devise:session#new'] = policy
      json['asset_discrete_policies']['C_devise:session#create'] = policy
      json['asset_discrete_policies']['C_devise:session#destroy'] = policy
      json['asset_discrete_policies']['C_devise:registration#new'] = policy
      json['asset_discrete_policies']['C_devise:registration#create'] = policy
      json['asset_discrete_policies']['C_devise:registration#cancel'] = policy
      json['asset_discrete_policies']['C_devise:unlock#new'] = policy
      json['asset_discrete_policies']['C_devise:unlock#show'] = policy
      json['asset_discrete_policies']['C_devise:unlock#create'] = policy
      json['asset_discrete_policies']['C_devise:confirmation#new'] = policy
      json['asset_discrete_policies']['C_devise:confirmation#show'] = policy
      json['asset_discrete_policies']['C_devise:confirmation#create'] = policy
      json['asset_discrete_policies']['C_devise:password#new'] = policy
      json['asset_discrete_policies']['C_devise:password#edit'] = policy
      json['asset_discrete_policies']['C_devise:password#create'] = policy
      json['asset_discrete_policies']['C_devise:password#update'] = policy
      json['asset_discrete_policies']['C_devise:omniauth_callback#passthru'] = policy
      json['asset_discrete_policies']['C_devise:omniauth_callback#failure'] = policy

      # any_role
      p2 = {}
      p2['is_authenticated'] = true
      p2['level'] = 15
      p2['color'] = 'red'
      json['asset_discrete_policies']['C_devise:registration#edit'] = p2
      json['asset_discrete_policies']['C_devise:registration#update'] = p2
      json['asset_discrete_policies']['C_devise:registration#destroy'] = p2

      # Ignore Views
      p3 = {}
      p3['ignore'] = true
      json['asset_discrete_policies']['V_devise:_links'] = p3
      json['asset_discrete_policies']['V_devise:mailer#reset_password_instructions'] = p3
      json['asset_discrete_policies']['V_devise:mailer#unlock_instructions'] = p3
      json['asset_discrete_policies']['V_devise:mailer#confirmation_instructions'] = p3

      model_list['user'] = true
    end
  end
end
