# -*- coding: UTF-8 -*-
#  CanCan - Authorization
#
#  Ref:
#    https://github.com/ryanb/cancan
#    http://railscasts.com/episodes/192-authorization-with-cancan
#
#  Commands
#    authorize
#
#  Variables
#
#     role = {user, admin}
#
#  guard
#
#     role == user
#     role != admin
#
#  Behavior - defined by programer
#
#    authorize! --> exception -> ApplicationController -> redirect_to -> root
#
# Controller
#   app/controllers/specifications_controller.rb:    if @specification.archived? and (can? :delete_archived, Specification) then
#   load_and_authorize_resource
# View
#   app/views/specifications/show.html.erb:<% if can? :delete_archived, @specification then %>
#
# Model
#   app/models/user.rb:  ROLES = %w[admin reader contractor controller chief_contractor chief_controller]
#   TODO: get ROLES list from  app/models/user.rb
#
# TODO: this is tentative
# Commands
# used in Model, ability.rb
# CanCan can => $cancan.set_crud_entry()
#
class CanCommand < Abstraction::Command
  def initialize
    super
    @name = 'can'
    @type = 'pdp'
    @providedby = 'cancan'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    if $parse_cancan
      begin
        $authorization_module.set_crud_entry($block, sexp[2][1])
      rescue => e
        $log.error "#{@filename}"
        raise e
      end
    else
      $log.error "CANCAN ast"
      fail "TODO: CANCAN can command"
    end
  end
end

# used in Controller class
# CanCan before filter => this is var_ref => controller.rb
# TODO: set flag to each actions
#  1) action_list
#  2) check (define PDP common api)
class LoadAndAuthorizeResourceCommand < Abstraction::Command
  def initialize
    super
    @name = 'load_and_authorize_resource'
    @type = 'pep'
    @providedby = 'cancan'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super

    begin
      if sexp.nil?
        @authorize = true
        $cancan_bf = 'load_and_authorize_resource' # TBD
        #
        # ACL ckeck
        # acls = $authorization_module.get_crud_entry_by_subject(@class_name, nil)
      elsif sexp[2][0] == :args_add_block
        sexp_aab = sexp[2][1]
        if sexp_aab[0][0] == :bare_assoc_hash
          # load_and_authorize_resource :except => [:show]
          # load_and_authorize_resource :except => [ :index, :show, :new, :create ]
          $log.debug "CANCAN load_and_authorize_resource w/ EXCEPT"
          if sexp_aab[0][1][0][1][1][1][1] == 'except'
            # Except
            $cancan_except = {}
            as =  ssexp_aab[0][1][0][2][1]
            as.each do |a|
              $cancan_except[a[1][1][1]] = true
            end
            @authorize = true
            $cancan_bf = 'load_and_authorize_resource_with_except' # TBD
            # ACL ckeck
            # acls = $authorization_module.get_crud_entry_by_subject(@class_name, except)
          elsif sexp_aab[0][1][0][1][1][1][1] == 'only'
            # ONLY
            @authorize = true
            $cancan_bf = 'load_and_authorize_resource_with_only' # TBD
            # ACL ckeck
            # TODO: acls = $cancan.get_crud_entry_by_subject(@class_name, nil, only)
          elsif sexp_aab[0][1][0][0] == :assoc_new
            if sexp_aab[0][1][0][1][0] == :@label
              if sexp_aab[0][1][0][1][1] == 'class:'
                # If the model class is namespaced differently than the controller
                # specify the :class option.
                # e.g. load_and_authorize_resource class: Message
                model =  sexp_aab[0][1][0][2][1][1] if sexp_aab[0][1][0][2][0] == :var_ref && sexp_aab[0][1][0][2][1][0] == :@const
                $log.debug "CANCAN load_and_authorize_resource TODO: #{$filename} assinged #{model}'s' policy"
                puts "    CANCAN: load_and_authorize_resource => set '#{model}' policy to #{$filename}"
              else
                $log.error "CANCAN load_and_authorize_resource UNKNOWN #{$filename}"
                pp sexp[2]
              end
            else
              $log.error "CANCAN load_and_authorize_resource UNKNOWN #{$filename}"
              pp sexp[2]
            end
          else
            $log.error "CANCAN load_and_authorize_resource UNKNOWN #{$filename}"
            pp sexp[2]
            pp sexp_aab[0][0]
            # TODO: save to ERROR
          end
        else
          subject = sexp[2][1][0][1][1][1]
          @authorize = true
          $cancan_bf = 'load_and_authorize_resource' # TBD
          # ACL ckeck
          # acls = $authorization_module.get_crud_entry_by_subject(@class_name, nil)
        end
      else
        pp sexp  # with raise
        fail "CANCAN load_and_authorize_resource TBD #{@filename}"
      end
    rescue => e
      $log.error "Unknwon load_and_authorize_resource"
      pp sexp # with $log.error
      raise e
    end
  end
end

# skip_authorize_resource
class SkipAuthorizeResourceCommand < Abstraction::Command
  def initialize
    super
    @name       = 'skip_authorize_resource'
    @type       = 'pep'
    @providedby = 'cancan'
    @is_sf      = true
  end

  def abstract(sexp, sarg, filename)
    super
    # $log.error "CanCan.skip_authorize_resource #{$modelname} #{$filename} "
    # skip_authorize_resource :only => [:following, :followers, :deleted_user]
    if sexp[2][0] == :args_add_block
      sexp_aab = sexp[2][1]
      if sexp_aab[0][0] == :bare_assoc_hash && sexp_aab[0][1][0][0] == :assoc_new
        sexp_an = sexp_aab[0][1][0]
        if sexp_an[1][0] == :symbol_literal &&  sexp_an[1][1][0] == :symbol &&  sexp_an[1][1][1][0] == :@ident
          if sexp_an[1][1][1][1] == 'only'
            type = 'only'
            $cancan_bf = 'load_and_authorize_resource_with_only'
            $cancan_bf_list = {}
          end
        else
          $log.error "TODO:"
        end

        if sexp_an[2][0] == :array
          sexp_an[2][1].each do |a|
            if a[0] == :symbol_literal && a[1][0] == :symbol && a[1][1][0] == :@ident
              $cancan_bf_list[a[1][1][1]] = type
            else
              $log.error "TODO:"
            end
          end
        else
          $log.error "TODO:"
        end
      else
        $log.error "TODO:"
      end
    else
      $log.error "TODO:"
    end
  end
end

# load_resource
# TODO
class LoadResourceCommand < LoadAndAuthorizeResourceCommand
  def initialize
    super
    @name = 'load_resource'
  end
end

# used in Controller class/method
# e.g.
#  authorize! :index, @user, :message => 'Not authorized as an administrator.'
class AuthorizeCommand < Abstraction::Command
  def initialize
    super
    @name       = 'authorize!'
    @type       = 'pep'
    @providedby = 'cancan'
    @is_sf      = true
  end

  def abstract(sexp, sarg, filename)
    super
    # v0.1.0
    # $log.error "CanCan.authorize! state=#{$state.id} #{$transition}"
    # $state.authorize = 'TBD'  # TODO: obsolute
    # acls = $authorization_module.get_crud_entry(sexp[2][1])  # sexp => subj/action/obj
    # $log.error "CANCAN ACL=#{acls}"
    # acls.each do |acl|
    #  $state.add_cancan('command', acl[0], acl[1], acl[2]) # subj/action/obj
    # end

    # v0.2.0 set code policy automatically
    $state.code_policy.is_authorized = true

    # TODO: check args
    # TODO: add trans for error w/ message
    # authorize! :update, @user, :message => 'Not authorized as an administrator.'

  end
end

# CanCan condition check / controller or view
class CanQCommand < Abstraction::Command
  def initialize
    super
    @name = 'can?'
    @type = 'pep'
    @providedby = 'cancan'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    $log.debug "CanCan.can! state=#{$state.id} #{$transition}"

    # acls = $authorization_module.get_crud_entry(sexp[2][1])
    # acls.each do |acl|
    #   $state.add_cancan('guard', acl[0], acl[1], acl[2])
    # end
  end
end

# has_role?
class HasRoleQCommand < Abstraction::Command
  def initialize
    super
    @name = 'has_role?'
    @type = 'pep'
    @providedby = 'cancan'
    @is_sf = true
  end

  def abstract(sexp, sarg, filename)
    super
    dst_code = get_ruby($transition.dst_hint)
    # $log.error "CanCan.has_role?  state=#{$state.id} trans=#{$transition.id}, dst=#{dst_code}"
    subject = sexp[4][1][0][1][1][1]
    if $state.type == 'view'
      # view with authorization check
      # TODO: this must set trans, not a state => Or both
      # $state.add_cancan('guard', subject, 'unknwon', 'unknwon')

      # has nav check $transition is previous trans, this filter applied to the following trans
      # TODO: check args
    else
      fail "CANCAN has_role? for #{$state.type}"
    end
  end
end

#################################################################################
# Main Class for CanCan
#
module Rails
  # PDP: CanCan
  class CanCan < Rails::PDP
    def initialize
      super
      @name = 'cancan'
      @type = 'rbac'
      @exist = true

      # set the name of filter used at Guard
      $authorization_filter_list = ['has_role?']

      # class level bf, load_and_authorize_resource
      # type
      #  all
      #  only
      #  except
      $cancan_bf = nil
    end

    # Requiremrnts
    def access_control_table
      super
    end

    # Abstraction::SecurityFunction
    def add_commands
      super
      # CanCan commands
      c1 = AuthorizeCommand.new
      $abst_commands[c1.name] = c1

      c2 = CanQCommand.new
      $abst_commands[c2.name] = c2

      c3 = CanCommand.new
      $abst_commands[c3.name] = c3

      c4 = LoadAndAuthorizeResourceCommand.new
      $abst_commands[c4.name] = c4

      c5 = SkipAuthorizeResourceCommand.new
      $abst_commands[c5.name] = c5

      c5 = HasRoleQCommand.new
      $abst_commands[c5.name] = c5
    end

    #
    # TODO
    #
    def get_roles
      return ['anon', 'user', 'admin']
    end

    # table to hash
    def get_acls(table)
      h = {}
      h['anon'] = ''
      h['user'] = ''
      h['admin'] = ''
      table.each do |t|
        h[t[0]] = t[1]
      end
      return h
    end

    # color
    def get_color(table)
      h = get_acls(table)
      if h['anon'] != ''
        return '#ff7070'  # red
      end
      if h['user'] != ''
        return '#70ff70'  # green
      end
      if h['admin'] != ''
        return '#00ff00' # dirk green
      end
      return '#d0d0d0'  # gray
    end

    # TODO
    def add_variable
      p = Abstraction::Parser::AstParser.new
      v = p.add_variable('cancan', 'devise#user_signed_in?', 'string', 'model/dummy.rb')
      v.origin = 'auto'
      $map_variable = {} if $map_variable.nil?
      $map_variable['devise#user_signed_in?'] = ['boolean', 'signed_in']
      $log.info "Added variables, devise#user_signed_in? for devise. "
    end

    # parse and set ACL
    #
    # also check the weakness of PDP style
    def set_crud_entry(condblk, sexp)
      action  = 'unknown'
      object  = 'unknown'
      subject = 'unknown'

      if sexp[0][0] == :array
        # multiple action
        actions = sexp[0][1]
        action = []
        actions.each do |a|
          action << a[1][1][1]
        end

        if sexp[1][0] == :var_ref
          object = sexp[1][1][1]
          object_type = 'domain' # TODO
        elsif sexp[1][0] == :symbol_literal
          object = sexp[1][1][1][1]
          object_type = 'ident'
        elsif sexp[1][0] == :array
          # multiple objects
          object = []
          ao = sexp[1][1]
          ao.each do |o|
            object << o[1][1]
            if o[0] == :var_ref
              object_type = 'domain' # TODO: multiple!!!
            else
              object_type = 'ident'
            end
          end
        else
          pp sexp
          fail "CANCAN unkown"
        end
      elsif sexp[0][0] == :symbol_literal && sexp[1][0] == :array
        # multiple object
        action = sexp[0][1][1][1]
        object = []
        ao = sexp[1][1]
        ao.each do |o|
          object << o[1][1]
          if o[0] == :var_ref
            object_type = 'domain' # TODO: multiple!!!
          else
            object_type = 'ident'
          end
        end
      else
        # Single action/object
        # Get action
        action = sexp[0][1][1][1] if sexp[0][0] == :symbol_literal

        # Get object
        if sexp[1][0] == :symbol_literal
          object = sexp[1][1][1][1]  # :@ident
          object_type = 'ident'
        elsif sexp[1][0] == :var_ref
          object = sexp[1][1][1]     # :@const
          object_type = 'domain'
        end
      end

      # DEBUG
      if action == 'unknown'
        pp sexp
        fail "CANCAN no action?"
      end
      if object == 'unknown'
        pp sexp
        fail "CANCAN no object?  action is #{action}"
      end

      # Get subject from block.cond
      #
      # if user.matriculations.joins(:course).where(:enabled => true, :courses => {:enabled => true}).present?
      # can :read, Alert, :course => {:matriculations => {:enabled => true, :user_id => user.id}}
      # ------------------------------------------------------------------------
      # PDP - simplicity check
      # if/elsif/else
      # to supress this warning set $cancan_exclusive_subject_condition = true
      if condblk.type != 'if' && $cancan_exclusive_subject_condition == false
        $log.debug "Complex ACL"
        if condblk.abst_condition.nil?
          guard = Sorcerer.source(condblk.cond)
        else
          guard = condblk.abst_condition
        end

        # TODO: this is v010
        w = {}
        w['warning_type'] = 'Ambiguous policy definition'
        w['message'] = "ACL definition with #{condblk.type}, #{guard}, #{action}, #{object}(#{object_type})"
        w['file'] = nil # TODO: condblk.filename is nil
        w['line'] = nil
        w['code'] = nil
        w['location'] = nil
        w['user_input'] = nil
        w['confidence'] = 'Weak'    # Weak Medium High
        # $warning.add(w)
      end

      # nested condition
      if condblk.level >= 1 && condblk.parent.type != 'root' && $cancan_nested_subject_condition == false
        $log.error "Complex ACL (nested)"
        if condblk.abst_condition.nil?
          guard = Sorcerer.source(condblk.cond)
        else
          guard = condblk.abst_condition
        end

        # TODO: this is v010
        w = {}
        w['warning_type'] = 'Ambiguous policy definition'
        w['message'] = "Nested ACL definition with #{condblk.type}, #{guard}, #{action}, #{object}(#{object_type})"
        w['file'] = nil # TODO: condblk.filename is nil
        w['line'] = nil
        w['code'] = nil
        w['location'] = nil
        w['user_input'] = nil
        w['confidence'] = 'Weak'    # Weak Medium High
        # $warning.add(w)
      end

      begin
        if condblk.cond.nil?
          # No block => Global
          subject = 'all'
        elsif condblk.cond[0] == :command_call
          subject = condblk.cond[4][1][0][1][1][1]
          $log.debug "CANCAN WHO <#{subject}> can #{action} #{object}(#{object_type})"
        elsif condblk.cond[0] == :var_ref
          subject = condblk.cond[1][1] + '(no role?)'
        elsif condblk.cond[0] == :binary
          if condblk.cond[1][0] == :call && condblk.cond[2] == :== && condblk.cond[3][1][1] == 'true'
            subject = condblk.cond[1][3][1].scan(/(\w+)/)[0][0]
            # remove last ?
          elsif condblk.cond[1][0] == :call && condblk.cond[2] == :== && condblk.cond[3][0] == :string_literal
            subject = condblk.cond[3][1][1][1]
          else
            $log.error "unknown block 3"
            pp condblk.cond
            subject = "TBD too complex"
            w = {}
            w['warning_type'] = 'Complex policy definition'
            w['message'] = "TBD"  # TODO: ?
            w['file'] = nil # TODO: controller
            w['line'] = nil
            w['code'] = nil
            w['location']   = nil
            w['user_input'] = nil
            w['confidence'] = 'Weak'    # Weak Medium High
            $warning.add(w)
          end
        elsif condblk.cond[0] == :call
          # if user.owner?
          if condblk.cond[1][0] == :var_ref
            subject = condblk.cond[3][1].scan(/(\w+)/)[0][0]
            # remove last ?
          else
            $log.error "unknown block 4"
            fail "CANCAN unknown block 4"
          end
        else
          $log.error "unknown block 1"
          fail "CANCAN unknown block 1"
        end
      rescue => e
        $log.error "unknown block 2"
        pp condblk.cond
        pp sexp
        subject = "too complex"
      end

      #
      # TODO: Trace block to get real condition of object
      # 20121231 how to?
      if @subjects[subject].nil?
        @subjects[subject] = 1
      else
        @subjects[subject] += 1
      end

      if @objects[object].nil?
        @objects[object] = 1
      else
        @objects[object] += 1
      end

      if @actions[action].nil?
        @actions[action] = 1
      else
        @actions[action] += 1
      end

      if @acl_table[object][action].nil?
        # New
        @acl_table[object][action] = { subject => 1 }
      else
        # add
        if @acl_table[object][action][subject].nil?
          # New subject
          @acl_table[object][action][subject] = 1
        else
          # Exist
          @acl_table[object][action][subject] += 1
        end
      end
    end

    #
    # Look up subject(hash)
    # return [subj, action, obj]
    #
    #  <% if can? :edit, @item %> ==> Subject
    #
    def get_crud_entry(sexp)
      action = 'unknown'
      object = 'unknown'
      action = sexp[0][1][1][1] if sexp[0][0] == :symbol_literal
      if sexp[1][0] == :symbol_literal
        object = sexp[1][1][1][1]  # :@ident
        object_type = 'ident'
      elsif sexp[1][0] == :var_ref
        object = sexp[1][1][1]     # :@const
        object_type = 'domain'
      end

      # Look up subjects for defined at Ability.rb
      subjects = @acl_table[object][action] # Hash
      if subjects.nil?
        # object = All?
        # action = manage?
        @acl_table.each do |o, v1|
          v1.each do |a, v2|
            v2.each do |s, v3|
              if o.class == Array
                $log.error "CANCAN TODO: object array"
              else
                if o.downcase == 'all' && a == 'manage'
                  $log.debug "CANCAN #{s}/manage/all found."
                  @acl_table[o][a][s] = 0  # TODO: Used flag
                  return [[s, action, object]]
                end
              end
            end
          end
        end
        $log.error "CANCAN get_crud_entry(), No Subject found for #{action} #{object} file #{$filename}"
        return [['unknown', action, object]]
      else
        # HIT
        acls = []
        subjects.each do |k, v|
          acls << [k, action, object]
          # Used tag =>  N=> 0
          @acl_table[object][action][k] = 0  # TODO: Used flag
          $log.error "CANCAN Subject(#{k}) found for #{action} #{object}"
        end
        return acls
      end
    end

    # BF -> used flag
    # TODO: change name
    # TODO: all > hoge
    # except : hash of except class < TODO: How to set?
    def get_crud_entry_by_subject(classname, except)
      $log.error "CANCAN except == nil" unless except.nil?

      # TODO: JUST set used flag
      hit = false
      @acl_table.each do |o, v1|
        v1.each do |a, v2|
          v2.each do |s, v3|
            if o.class == Array
              # TODO:  Array => split to each object
              o.each do |o2|
                if o2.downcase + 'scontroller' == classname  # TODO: BAD
                  # HIT
                  hit = true
                  @acl_table[o][a][s] = 0 # TODO
                else
                  $log.error "TODO: get_crud_entry_by_subject(#{classname},#{except}) #{o} #{a} #{s}"
                  pp @acl_table
                  fail "TODO:"
                end
              end
            else
              # single?
              if o.downcase + 'scontroller' == classname  # TODO: BAD
                # HIT
                hit = true
                @acl_table[o][a][s] = 0
              else
                $log.debug "get_crud_entry_by_subject, MISS, #{o} #{a} #{s} #{classname}"
              end
            end
          end
        end
      end

      $log.error "CANCAN #{classname} no ACL" if hit == false
    end

    #
    # Get action   [action, used|NA]
    #
    # TODO: what is the best way for the ACL table @acl_table?
    #
    def get_action(subject, object)
      action_list = []
      @acl_table.each do |o, v1|
        v1.each do |a, v2|
          v2.each do |s, v3|
            if subject == s && object == o
              if v3 == 0
                # this ACL is used in code.
                # raise "DEBUG #{action_list} #{v3}"
                action_list << [a, 'used']
              else
                # this ACL is not used in the code
                action_list << [a, 'NA']
              end
            end
          end
        end
      end
      return action_list
    end

    # Dashboard
    # unused array[subject, object] and count
    def setup4dashboard
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

    # PDP/ACL is used by PEP.
    # NA(Unused) => True
    # Used => False
    def is_unused(subject, object)
      return @unused_table[subject][object]
    end

    # get role and action from object(domain)
    # call from security_check
    def get_role_and_action(domain)
      obj = domain.split('#')[0]
      object = lookupObject(obj)

      return nil if object.nil?

      # ACL Table
      # H[Subject][Action] = Object
      role_action_list = []
      @acl_table.each do |o, v1|
        v1.each do |a, v2|
          v2.each do |s, v3|
            role_action_list << [s, a] if object == o
          end
        end
      end
      return role_action_list
    end

    # lowcase => object Key
    def lookup_object(obj)
      object = nil
      @objects.each do |o, v|
        object = o if o.downcase == obj.downcase
      end
      return object
    end

    # rails action => PDP action
    def lookup_action(act)
      return 'create' if act == 'new'
      return 'read'   if act == 'show'
      return 'read'   if act == 'index'
      return 'update' if act == 'edit'
      return act
    end

    # Check
    # domain = object+action
    def pdp(role, domain)
      hit = false
      # Domain => onject & action
      obj    = domain.split('#')
      object = lookup_object(obj[0])
      action = lookup_action(obj[1])

      # Check
      # ACL Table
      # O->A->S->count
      as = @acl_table[object]
      as.each do |a, s|
        if a.class == String
          s.each do |s2, count|
            hit = true if a == action && s2 == role
          end
        else
          a.each do |a2|
            s.each do |s2, count|
              hit = true if a2 == action && s2 == role
            end
          end
        end
      end
      return hit
    end

    def set_used_acl(subject, object, action)
    end

    #--------------------------------------------------------------------------
    # Code side
    # set PEP defined by class scope
    def pep_assignment
      unless $cancan_bf.nil?
        if $cancan_bf == 'load_and_authorize_resource'
          $action_list.each do |k, v|
            v[1].code_policy.is_authorized = true unless v[1].nil?
          end
        elsif $cancan_bf == 'load_and_authorize_resource_with_only'
          $action_list.each do |k, v|
            unless v[1].nil?
              if $cancan_bf_list[k] == 'only'
                v[1].code_policy.is_authorized = true
              else
                v[1].code_policy.is_authorized = false
              end
            end
          end
        else
          $log.error "TODO: #{$cancan_bf}"
        end
        $cancan_bf = nil
      end
    end

    # call
    def compleate_pep_assignment
      super
      puts "    CanCan: compleate PEP assignment TODO"

      # Global Controller
      # $log.error "TODO"
    end

    #--------------------------------------------------------------------------
    # Req. side
    def print_sample_requirements_base_policies
      puts "  'role' => {         # CanCan"
      puts "    is_authenticated: true,"
      puts "    is_authorized:    true, # Admin only"
      puts "    level: 15,  # Mandatory?"
      puts "    color: 'red',"
      puts "    roles:  ["
      puts "      { role: 'admin',  action: 'CRUD' },"
      puts "      { role: 'user',   action: 'R' } ]"
      puts "  },"
      puts "  'users_role' => {   # CanCan (model only)"
      puts "    is_authenticated: true,"
      puts "    is_authorized:    true,"
      puts "    level: 15,  # Mandatory?"
      puts "    roles:  [ { role: 'user', action: 'CRUD' } ]"
      puts "  },"
      puts "  'ability' => {      # CanCan (model only)"
      puts "    is_authenticated: true,"
      puts "    is_authorized:    true,"
      puts "    level: 15,  # Mandatory?"
      puts "    roles:  [ { role: 'user', action: 'CRUD' } ]"
      puts "   },"
      return ['role', 'users_role', 'ability']
    end

    def print_sample_requirements_mask_policies
      puts ""
      return []
    end
  end
end
