# -*- coding: UTF-8 -*-
# Common class for security functions
#   Devise
#   Authlogic
#
#   PDP
#     CanCan
#     TheRole
#
# 1 create new security function class
# 2 load abstruct.rb
#
# Abstraction::SecurityFunction

module Abstraction
  #
  class SecurityFunction
    def initialize
      @name = nil
      @type = nil
    end
    attr_accessor :name, :type

    # Obsolete => define the behaviors by Hash use get_commands()
    def add_commands
    end

    # return commands in Hash
    def get_commands
      return nil
    end
  end
end
