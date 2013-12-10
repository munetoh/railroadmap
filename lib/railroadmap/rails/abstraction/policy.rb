# -*- coding: UTF-8 -*-
# Policy
#
#  Object: state (M,V,C), variable
#
module Abstraction
  # Policy class for both req and code
  class Policy
    def initialize
      @policy_object_type = nil
      @policy_object_name = nil

      @has_policy_requirements = false

      # for req policy, keep the policy propagation flow
      @origin_type = nil
      @origin_id   = nil
      @ignore      = false

      # policy injection
      #
      #  type          source
      #  -----------------------
      #  direct        requirements
      #  derived       state or variable (automatic)
      #  exceptionally requirements
      @policy_assignment_type = nil # direct, derived, exceptionally
      @policy_source = nil # state or valiable

      # Req secure comm.
      @ssl_required = false   # state flag
      @ssl_allowed  = false   # state flag

      # Req Authentication
      @is_authenticated = nil   # e.g. Devise
      @is_public = nil
      @authentication = nil
      @authentication_req = nil

      # Req Authorizarion
      @is_authorized = nil
      @authorization = nil            # e.g. CanCan (bf command and view with guard)
      @authorization_req = nil

      # Policy level and categories
      @level = nil
      @category = nil  # TODO: single category => DELETE
      # Errors
      @is_unclear_pdp = false   # TODO: is_unclear_authentication
      @undefined_role = false

      # DAC
      @is_owner = false
      @is_member = false
      @membership = nil  # TODO: ist?

      # RBAC
      @role_list = nil # TODO: list?

      # Dashboard out
      @is_unclear_authentication = false
      @is_unclear_authorization = false

      # Reason and remidiations
      @authentication_comment = ""
      @authorization_comment = ""
      @is_unclear = false  # TODO: not only the policy bug

      # State-> Model
      @authenticated_action_list = []
      @no_authenticated_action_list = []
      @authorized_action_list = []
      @no_authorized_action_list = []

      # Graphviz
      @color = nil
    end
    attr_accessor :has_policy_requirements,
                  :ssl_required, :ssl_allowed,
                  :is_authenticated, :is_public, :is_authorized,
                  :authorize,
                  :is_unclear,
                  :authentication_comment, :authorization_comment,
                  :is_unclear_authentication, :is_unclear_authorization,
                  :authenticated_action_list, :no_authenticated_action_list,
                  :authorized_action_list, :no_authorized_action_list,
                  :level, :category, :is_unclear_pdp, :undefined_role, :role_list,
                  :origin_type, :origin_id,
                  :ignore, :color

    # Set policy for object
    def set_policy
    end

    def has_policy
    end

    # check existance of code policy
    def exist?
      return true if is_authenticated
      return true if is_authorized
      # TODO: else?
      return false
    end
  end
end
