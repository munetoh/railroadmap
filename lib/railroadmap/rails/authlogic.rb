# -*- coding: UTF-8 -*-
# Authlogic
#   https://github.com/binarylogic/authlogic
#
# Examples
#   https://github.com/binarylogic/authlogic_example
#   https://github.com/bitcababy/authlogic-example-for-rails-3
#   https://github.com/gustavoglz/Authlogic-Rails-3.1.1-Example
#   https://github.com/brianviveiros/Rails31-Authlogic-CanCan-Capistrano-Template
#   https://github.com/miyohide/authlogic_sample

###############################################
#
#
module Rails
  # Authentication, PEP
  class Authlogic < Abstraction::SecurityFunction
    def initialize
      super
      @name = 'authlogic'
      @type = 'access control'
      # Global
      $authentication_method = 'authlogic'
    end

    def get_command_list
      authlogic_commands = {
        # AUthlogic side
        # App side (ApplicationController)
        'current_user_session' => {
          type:       'object',
          providedby: 'app'
        },
        'current_user' => {
          type:       'helper_method',
          providedby: 'app'
        },
        'require_user' => {
          type:       'filter',
          providedby: 'app'
        },
        'require_no_user' => {
          type:       'anti_filter',
          providedby: 'app'
        }
      }
    end
  end
end
