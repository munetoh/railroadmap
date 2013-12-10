# -*- coding: UTF-8 -*-
#  Devise
#

#
# Commands
#
class DeviseCommand < Abstraction::Command
  def initialize
    super
    @name = 'devise'
    @type = 'config'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
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
  end
end

# TODO: sign_up/in/out
# def in app/controllers/devise/registrations_controller.rb
class SignUpCommand < Abstraction::Command
  def initialize
    super
    @name = 'sign_up'
    @type = 'operation'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
  end
end

class SignInCommand < Abstraction::Command
  def initialize
    super
    @name = 'sign_in'
    @type = 'operation'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
  end
end

class SignOutCommand < Abstraction::Command
  def initialize
    super
    @name = 'sign_out'
    @type = 'operation'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
  end
end

# set_flash_message
# app/controllers/devise_controller.rb
#
# need for the testcase?
class SetFlashMessageCommand < Abstraction::Command
  def initialize
    super
    @name = 'set_flash_message'
    @type = 'operation'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
  end
end

# require_no_authentication
# TODO: disable auth?, so explicit?, how to handle?
#
# Using this is a good practice to define explicit SF in the code.
#
# TODO: Count is not incremented. Since managed by before filter?? => FIX
class RequireNoAuthenticationCommand < Abstraction::Command
  def initialize
    super
    @name = 'require_no_authentication'
    @type = 'filter'
    @subtype = 'TODO'
    @providedby = 'devise'
    @is_sf = true
    @sf_type = "except_authentication"
    @status = 'beta'
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
    $log.error "RequireNoAuthenticationCommand()"
  end
end

# authenticate_user!
# TODO: how to handle except?
class AuthenticateUserExclamationCommand < Abstraction::Command
  def initialize
    super
    @name = 'authenticate_user!'
    @type = 'filter'
    @subtype = 'TBD'
    @providedby = 'devise'
    @is_sf = true
    @sf_type = "authentication"
    @status = 'TODO'
    # TODO: add trans
    # c.dst_table
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
    $log.error "AuthenticateUserExclamationCommand()"
  end
end

# authenticate_scope!
class AuthenticateScopeExclamationCommand < Abstraction::Command
  def initialize
    super
    @name = 'authenticate_scope!'
    @type = 'filter'
    @subtype = 'TBD'
    @providedby = 'devise'
    @is_sf = true
    @sf_type = "authentication"
    @status = 'TODO'
    # TODO: add trans
    # c.dst_table
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
    $log.error "AuthenticateScopeExclamationCommand()"
  end
end

# allow_params_authentication!
# lib/devise/controllers/helpers.rb
class AllowParamsAuthenticationCommand < Abstraction::Command
  def initialize
    super
    @name = 'allow_params_authentication!'
    @type = 'filter'
    @subtype = 'TBD'
    @providedby = 'devise'
    @is_sf   = true
    @sf_type = "params_authentication"  # TODO
    @status  = 'TODO'
    # TODO: add trans
    # c.dst_table
  end

  def abstract(sexp, sarg, filename)
    super
    # TODO: add abstracted operation
    $log.error "AllowParamsAuthenticationCommand()"
  end
end

# after_sign_in_path_for
# lib/devise/controllers/helpers.rb:

# after_sign_out_path_for
# lib/devise/controllers/helpers.rb:

# is_navigational_format?
# lib/devise/failure_app.rb:

# clean_up_passwords
# lib/devise/models/database_authenticatable.rb:

# serialize_options
# app/controllers/devise/sessions_controller.rb:

# after_sign_up_path_for
# app/controllers/devise/registrations_controller.rb:

# unlockable?
# app/controllers/devise/passwords_controller.rb:

# after_sending_reset_password_instructions_path_for
# app/controllers/devise/passwords_controller.rb:

# new_session_path
# ??? FW?

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
    end

    def get_commands
      fail "use get_command_list()"
    end

    def get_command_list
      devise_commands = {
        # app/controllers/devise/passwords_controller.rb:    def after_resetting_password_path_for(resource)
        # TODO: Path?
        'after_resetting_password_path_for?' => {
          type:       'path',
          providedby: 'the_role'
        },
      }
    end

    def add_command(c)
      $abst_commands[c.name] = c
    end

    def add_command_todo(name, type)
      c = Abstraction::Command.new
      c.name = name
      c.type = type
      c.providedby = 'devise'
      c.status = 'TODO'
      add_command(c)
      return c
    end

    def add_commands
      super
      # Devise commands
      add_command(DeviseCommand.new)
      add_command(SignUpCommand.new)
      add_command(SignInCommand.new)
      add_command(SignOutCommand.new)
      add_command(SetFlashMessageCommand.new)

      add_command(RequireNoAuthenticationCommand.new)
      add_command(AuthenticateUserExclamationCommand.new)
      add_command(AuthenticateScopeExclamationCommand.new)
      add_command(AllowParamsAuthenticationCommand.new)

      # helper
      add_command_todo('after_sign_in_path_for', 'helper')
      add_command_todo('after_sign_out_path_for', 'helper')
      add_command_todo('signed_in_root_path', 'helper')
      add_command_todo('expire_session_data_after_sign_in!', 'helper')

      # lib
      add_command_todo('is_navigational_format?', 'lib')
      add_command_todo('clean_up_passwords', 'lib')
      add_command_todo('respond_to?', 'lib')

      # controller
      add_command_todo('after_sign_up_path_for', 'controller')
      add_command_todo('unlockable?', 'controller')
      add_command_todo('after_sending_reset_password_instructions_path_for', 'controller')
      add_command_todo('respond_with_navigational', 'controller')
      add_command_todo('after_update_path_for', 'controller')
      add_command_todo('update_needs_confirmation?', 'controller')
      add_command_todo('after_inactive_sign_up_path_for', 'controller')
      add_command_todo('successfully_sent?', 'controller')
      add_command_todo('build_resource', 'controller')
      add_command_todo('serialize_options', 'controller')

      # devise-3.0.3/app/controllers/devise/passwords_controller.rb
      add_command_todo('after_resetting_password_path_for', 'controller')
      # devise-3.0.3/app/controllers/devise/sessions_controller.rb
      add_command_todo('sign_in_params', 'controller')
      # devise-3.0.3/app/controllers/devise/registrations_controller.rb
      add_command_todo('sign_up_params', 'controller')
      add_command_todo('account_update_params', 'controller')
      # app/views/devise/registrations/new.html.erb
      add_command_todo('display_base_errors', 'controller')

      # app/controllers/devise/omniauth_callbacks_controller.rb
      add_command_todo('after_omniauth_failure_path_for', 'controller')
      add_command_todo('failed_strategy', 'controller')
      add_command_todo('failure_message', 'controller')
      # app/controllers/devise/unlocks_controller.rb
      add_command_todo('after_sending_unlock_instructions_path_for', 'controller')
      add_command_todo('after_unlock_path_for', 'controller')
      # app/controllers/devise/confirmations_controller.rb
      add_command_todo('after_resending_confirmation_instructions_path_for', 'controller')
      add_command_todo('after_confirmation_path_for', 'controller')
      # app/controllers/devise/sessions_controller.rb
      add_command_todo('auth_options', 'controller')
      # app/controllers/devise/passwords_controller.rb
      add_command_todo('assert_reset_token_passed', 'controller')

      add_command_todo('new_registration_path', 'TODO')
      add_command_todo('new_session_path', 'TODO')
    end

    #
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

    def add_variable
      p = Abstraction::Parser::AstParser.new
      v = p.add_variable('devise', 'devise#user_signed_in?', 'string', 'model/dummy.rb')
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
    def print_sample_requirements_base_policies
      puts "  'user' => {"
      puts "    model_alias: { # map devise to appmodel"
      puts "      'devise:registration'      => 'user',"
      puts "      'devise:session'           => 'user',"
      puts "      'devise:password'          => 'user',"
      puts "      'devise:confirmation'      => 'user',"
      puts "      'devise:unlock'            => 'user',"
      puts "      'devise:omniauth_callback' => 'user' },"
      puts "    is_authenticated: true,"
      puts "    level:            10,  # admin"
      puts "    color: 'orange',"
      if $authorization_module.nil?
        puts "  # no authorization"
      else
        puts "    is_authorized:    true,"  # TODO: check
        puts "    roles: ["
        puts "      { role: 'admin', action: 'CRUD' },"
        puts "      { role: 'user',  action: 'CRU', is_owner: true } ]"
      end
      puts "   },"
      return ['user']
    end

    def print_sample_requirements_mask_policies
      puts "# Devise"
      puts "# public"
      puts "  'C_devise:session#new'         => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:session#create'      => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:session#destroy'     => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:registration#new'    => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:registration#create' => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:registration#cancel' => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:unlock#new'          => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:unlock#show'         => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:unlock#create'       => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:confirmation#new'    => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:confirmation#show'   => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:confirmation#create' => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:password#new'        => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:password#edit'       => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:password#create'     => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:password#update'     => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:omniauth_callback#passthru'  => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  'C_devise:omniauth_callback#failure'   => { is_authenticated: false, level: 0, color: 'green' },"
      puts "  # any role"
      puts "  'C_devise:registration#edit'    => { is_authenticated: true, is_authorized: false, level: 15, color: 'red' },"
      puts "  'C_devise:registration#update'  => { is_authenticated: true, is_authorized: false, level: 15, color: 'red' },"
      puts "  'C_devise:registration#destroy' => { is_authenticated: true, is_authorized: false, level: 15, color: 'red' },"
      puts "   # ignore"
      puts "  'V_devise#_links'                             => { ignore: true },"
      puts "  'V_devise:mailer#reset_password_instructions' => { ignore: true },"
      puts "  'V_devise:mailer#unlock_instructions'         => { ignore: true },"
      puts "  'V_devise:mailer#confirmation_instructions'   => { ignore: true },"

      return []
    end
  end
end
