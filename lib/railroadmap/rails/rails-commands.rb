# -*- coding: UTF-8 -*-
# Commands of Rails Framework
#
# TODO: commonization and generalization => asb.rb

#
module Rails

  # protected
  class ProtectedCommand < Abstraction::Command
    def initialize
      super
      @name       = 'protected'
      @type       = 'TODO'
      @subtype    = 'TODO'
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      super
      $is_private   = false
      $is_protected = true
    end
  end

  # private
  class PrivateCommand < Abstraction::Command
    def initialize
      super
      @name = 'private'
      @type = 'TODO'
      @subtype = 'TODO'
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      super
      $is_private   = true
      $is_protected = false
    end
  end

  # C->V
  # TODO
  # http://railsdoc.com/references/respond_to
  # http://www38.atwiki.jp/eyes_33/pages/51.html
  #
  # add trans at the end of this block
  # see controller.rb
  class RespondToCommand < Abstraction::Command
    def initialize
      super
      @name = 'respond_to'
      @type = 'transition'
      @subtype = 'render(TODO)'  # TODO: HTML, JSON...?
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      super
      $log.debug "ast.rb command, respond_to"

      # Flag to indicate respond_to block
      $respond_to = true
    end
  end

  # respond_with
  # from 3.0
  # C->V render
  #
  # http://apidock.com/rails/ActionController/MimeResponds/respond_with
  # http://asciicasts.com/episodes/224-controllers-in-rails-3
  # http://blog.livedoor.jp/sasata299/archives/51804693.html
  class RespondWithCommand < Abstraction::Command
    def initialize
      super
      @name = 'respond_with'
      @type = 'transition'
      @subtype = 'render(TODO)'  # TODO: HTML, JSON...?
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      super
      # TODO: add trans
      # respond_with(@users)
      #
      # respond_with(@user) do |format|
      #   format.html { render }
      # end
      #
      # respond_with(@product, :location => products_url)
    end
  end

  ####################################
  # Security commands
  class RawCommand < Abstraction::Command
    def initialize
      super
      @name = 'raw'
      @type = 'dataflow'
      @subtype = 'anti-filter'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      $xss_raw_count += 1
      $xss_raw_region = true
      $xss_raw_files << filename
      $log.debug "AST/command  raw exist!!"

      # TODO: Dataflow
    end
  end

  class HCommand < Abstraction::Command
    def initialize
      super
      @name = 'h'
      @type = 'dataflow'
      @subtype = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      # TODO: old rails?
      # TODO: dataflow

    end
  end

  # sanitize
  # http://railsdoc.com/references/sanitize
  class SanitizeCommand < Abstraction::Command
    def initialize
      super
      @name = 'sanitize'
      @type = 'dataflow'
      @subtype = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      # TODO: old rails?
      # TODO: dataflow
    end
  end

  # SSL
  # ssl_required
  class SslRequiredCommand < Abstraction::Command
    def initialize
      super
      @name = 'ssl_required'
      @type = 'pep'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      if sarg.nil?
        @ssl_required = true
      else
        @ssl_required = get_hash(sarg)
      end
    end
  end

  # ssl_allowed
  class SslAllowedCommand < Abstraction::Command
    def initialize
      super
      @name = 'ssl_allowed'
      @type = 'pep'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      if sarg.nil?
        @ssl_allowed = true
      else
        @ssl_allowed = get_hash(sarg)
      end
      # @ssl_allowed = true #get_hash()
      # TODO: hash
    end
  end

  # attr_accessible
  class AttrAccessibleCommand < Abstraction::Command
    def initialize
      super
      @name = 'attr_accessible'
      @type = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf = true
    end

    def abstract(sexp, sarg, filename)
      super
      # Mass injection
      # TODO: list -> each variable at model.rb
      $attr_accessible = sarg
    end
  end

  #############################################################################
  # before_filter
  class BeforeFilterCommand < Abstraction::Command
    def initialize
      super
      @name = 'before_filter'
      @type = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf      = true
    end

    def abstract(sexp, sarg, filename)
      super
      # ActionController::Filters::ClassMethods
      # when 'before_filter'
      # Devise
      #  before_filter :authenticate_user!
      #  before_filter :authenticate_user!, :only => [:edit, :update, :destroy]
      # TODO: set trans. to the each action
      arg = get_ruby(sexp[2])
      $log.debug "BeforeFilterCommand.abstract() ast.rb command, before_filter #{arg}"

      common_beforebilter_parser(@name, sexp[2], filename, nil)
    end

    # 20130721 robust parser
    # TODO: => def CommonBeforeFilter?  Abstraction::Command
    #
    # $list_filter[name] = [only|except, [list of methods]]   =>  complete_filter()
    # CommonBeforeFilterParser
    def common_beforebilter_parser(filter_name, sexp, filename, option)
      filter = []
      type   = nil
      list   = []
      todo   = false

      if sexp == []
        $log.info "common_beforebilter_parser() - '#{filter_name}' has null sexp #{filename}"
        return
      end

      # 1 parse AST
      if sexp[0].to_s == 'args_add_block'
        bexp = sexp[1]  # list

        bexp.each do |b|
          if b[0].to_s == 'symbol_literal'
            # filter
            if b[1][0].to_s == 'symbol' && b[1][1][0].to_s == '@ident'
              filter << b[1][1][1]
            else
              $log.error "common_beforebilter_parser() TODO"
            end
          elsif b[0].to_s == 'bare_assoc_hash'
            hexp = b[1][0]
            if hexp[0].to_s == 'assoc_new'

              # type = only|except
              if hexp[1][0].to_s == 'symbol_literal' && hexp[1][1][0].to_s == 'symbol' && hexp[1][1][1][0].to_s == '@ident'
                type = hexp[1][1][1][1]
              elsif hexp[1][0] == :@label
                # only:
                type = hexp[1][1]
              else
                $log.error "common_beforebilter_parser() TODO: be robust"
                pp hexp
              end

              # list
              if hexp[2][0].to_s == 'symbol_literal' && hexp[2][1][0].to_s == 'symbol' && hexp[2][1][1][0].to_s == '@ident'
                # single
                list << hexp[2][1][1][1]
              elsif hexp[2][0].to_s == 'array'
                # many
                aexp =  hexp[2][1]
                aexp.each do |a|
                  if a[0].to_s == 'symbol_literal' && a[1][0].to_s == 'symbol' && a[1][1][0].to_s == '@ident'
                    list << a[1][1][1]
                  else
                    $log.error "common_beforebilter_parser() TODO"
                    pp a[0]
                    pp a[1][0]
                    pp a[1][1][0]
                  end
                end  # each
              else
                $log.error "common_beforebilter_parser() TODO: be robust"
              end
            else
              $log.error "common_beforebilter_parser() TODO"
              todo = true
            end
          else
            $log.error "common_beforebilter_parser() TODO"
          end  # b[0]
        end # bexp list
      else
        $log.error "common_beforebilter_parser() TODO: #{filter_name}"
        p sexp[0]
        pp sexp
      end

      # 2 POST process
      if filter.size > 0
        # Update command/filter ref count
        filter.each do |f|
          c = $abst_commands[f]
          if c.nil?
            $log.error "TODO: #{f} is missing"
          else
            c.count += 1
          end
        end

        # TODO: = true
        if todo
          $log.error "common_beforebilter_parser() filter = #{filter} type=#{type}  methods=#{list}"
          ruby_code = get_ruby(sexp)
          p ruby_code
          pp sexp
        end

        # add to global list
        # the list must be cleared at the start of the controller class
        # TODO: AppCon => $list_global_filter
        if $class_name == 'applicationcontroller'
          # scope: Global
          filter.each do |f|
            if $list_global_filter[f].nil?
              if type.nil?
                # no selection
                $list_global_filter[f] = ['all', nil]
              else
                $list_global_filter[f] = [type, list]
              end
            else
              $log.error "TODO: #{f} exist "
            end
          end
        else
          # scope: Class
          filter.each do |f|
            if type.nil?
              # no selection
              $list_filter[f] = ['all', nil]
            else
              $list_filter[f] = [type, list]
            end
          end
        end
      else
        ruby_code = get_ruby(sexp)
        $log.error "common_beforebilter_parser() unknown filter #{ruby_code} <<< PEP?"
        pp sexp
        fail "DEBUG"
      end

      if $class_name == 'applicationcontroller'
        # $log.error "common_beforebilter_parser() GLOBAL #{filter_name} #{$list_global_filter}  #{$class_name}"
      else
        $log.debug "common_beforebilter_parser() #{filter_name} #{$list_filter}  #{$class_name}"
      end
    end  # def common_beforebilter_parser
  end

  # skip_before_filter
  # 20130730 Redmine use this
  # http://apidock.com/rails/ActionController/Filters/ClassMethods/skip_before_filter
  class SkipBeforeFilterCommand < BeforeFilterCommand # < Abstraction::Command
    def initialize
      super
      @name = 'skip_before_filter'
      @type = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf      = true
    end

    def abstract(sexp, sarg, filename)
      # ActionController::Filters::ClassMethods
      # when 'before_filter'
      # Devise
      #  before_filter :authenticate_user!
      #  before_filter :authenticate_user!, :only => [:edit, :update, :destroy]
      # TODO: set trans. to the each action
      # TODO: DEBUG
      arg = get_ruby(sexp[2])
      $log.error "SkipBeforeFilterCommand() TODO:  #{arg} class=#{$class_name}"

      filter_name = sexp[2][1][0][1][1][1]

      if $list_global_filter.size == 0
        # new
        $list_global_filter[filter_name] = ['except', $class_name]
      else
        # already
        $log.error "SkipBeforeFilterCommand() TODO:  #{arg} class=#{$class_name}"
        fail "ADD CODE"
      end
    end
  end

  # prepend_before_filter
  # http://apidock.com/rails/ActionController/Filters/ClassMethods/prepend_before_filter
  # http://d.hatena.ne.jp/favril/20100722/1279781635
  class PrependBeforeFilterCommand < BeforeFilterCommand # < Abstraction::Command
    def initialize
      super
      @name = 'prepend_before_filter'
      @type = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf      = true
    end

    def abstract(sexp, sarg, filename)
      arg = get_ruby(sexp[2])
      $log.debug "command prepend_before_filter #{arg} #{$filename}"

      common_beforebilter_parser(@name, sexp[2], filename, nil)
    end
  end

  # Rails4
  class BeforeActionCommand < BeforeFilterCommand # < Abstraction::Command
    def initialize
      super
      @name       = 'before_action'
      @type       = 'filter'  # TODO
      @providedby = 'rails'
      @is_sf      = true
    end
  end

  # alias_method
  # http://apidock.com/ruby/Module/alias_method
  class AliasMethodCommand < Abstraction::Command
    def initialize
      super
      @name       = 'alias_method'
      @type       = 'alias'  # TODO
      @providedby = 'rails'
      @status     = 'beta'
    end

    def abstract(sexp, sarg, filename)
      if sexp[2][0] == :args_add_block
        if sexp[2][1][0][0] == :symbol_literal && sexp[2][1][0][1][1][0] == :@ident
          origc =  sexp[2][1][0][1][1][1]
        else
          $log.error "TODO: be robust"
        end
        if sexp[2][1][1][0] == :symbol_literal && sexp[2][1][1][1][1][0] == :@ident
          newc =  sexp[2][1][1][1][1][1]
        else
          $log.error "TODO: be robust"
        end
      else
        $log.error "TODO: be robust"
      end

      if origc.nil? || newc.nil?
        # ERROR
        $log.error "alias_method unknown AST"
        pp sexp
        fail "Update parser"
      else
        $log.debug "alias_method #{origc} #{newc}"
        # lookup
        fail "Unknown original command #{origc}" if $abst_commands[origc].nil?
        # fail "Unknown aliased command #{newc}"

        if $abst_commands[newc].nil?
          # add to cmd list
          c = Abstraction::Command.new
          c.name  = newc
          c.type  = 'unknown_filter'
          c.count = 1  # include this
          c.filenames << $filename
          c.status = 'unknown'
          $abst_commands[newc] = c
          $unknown_command += 1
          return
        end

        # OK, lets alias
        $abst_commands[origc] = $abst_commands[newc]
        $abst_commands[origc].comment += "aliased #{origc} to #{newc}, "
      end
    end
  end

  #----------------------------------------------------------------------------
  # has_many Page
  #   Control DF   Pagetype --has_many--> Page#Pagetype
  #
  #   Policy
  #   MLS        MCS       PEP@Guard
  #   src  dst   src dst
  #   ----------------------------------
  #   high high  A    A    no
  #   ----------------------------------
  #   high low   B    B    -
  #   high low   B    C    Read OK => no
  #   high low   B    A    -
  #   ----------------------------------
  #   low  high  C    C    ??? CAUTION?
  #   ----------------------------------
  #   low  low   D    D    no
  #   ----------------------------------
  class HasManyCommand < Abstraction::Command
    def initialize
      super
      @name = 'has_many'
      @type = 'model_association'  # TODO
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      s = get_sexp(sexp, :args_add_block)
      if s.nil?
        $log.error "TODO"
      else
        model = s[1][0][1][1][1]
        if !model.nil? && !$class_name.nil?
          # add DF
          src_id = "S_" + $class_name + "#id"
          dst_id = "S_" + model.singularize + "#" + $class_name
          df = add_dataflow('control', @name, src_id, nil, dst_id, nil, filename)
        else
          $log.info "HasManyCommand.abstract() DATAFLOW TODO: missing model or class"
        end
      end
    end
  end

  # belongs_to
  class BelongsToCommand < Abstraction::Command
    def initialize
      super
      @name = 'belongs_to'
      @type = 'model_association'  # TODO
      @providedby = 'rails'
    end

    def abstract(sexp, sarg, filename)
      s = get_sexp(sexp, :args_add_block)
      if s.nil?
        $log.error "TODO"
      else
        model = s[1][0][1][1][1]
        if !model.nil? && !$class_name.nil?
          # add DF
          src_id = "S_" + model.singularize + "#id"
          dst_id = "S_" + $class_name + "#" + model.singularize
          df = add_dataflow('control', @name, src_id, nil, dst_id, nil, filename)
        else
          $log.info "BelongsToCommand.abstract() TODO: DATAFLOW missing model or class"
        end
      end
    end
  end

  # ============================================================================
  # add  to the list
  class Commands < Abstraction::Parser::AstParser
    def initialize
      fail "ERROR" if $abst_commands.nil?

      # 20130801
      add_command_to_list(Rails::ProtectedCommand.new)
      add_command_to_list(Rails::PrivateCommand.new)

      # TODO
      add_command_to_list(Rails::RespondToCommand.new)
      add_command_to_list(Rails::RespondWithCommand.new)

      # Command/View/Sefurity Functions
      add_command_to_list(Rails::RawCommand.new)
      add_command_to_list(Rails::HCommand.new)
      add_command_to_list(Rails::SanitizeCommand.new)

      add_command_to_list(Rails::AttrAccessibleCommand.new)

      add_command_to_list(Rails::BeforeFilterCommand.new)  # Rails3
      add_command_to_list(Rails::BeforeActionCommand.new)  # Rails4
      add_command_to_list(Rails::SkipBeforeFilterCommand.new)
      add_command_to_list(Rails::PrependBeforeFilterCommand.new)

      # TODO: not executed 20130630
      add_command_to_list(Rails::SslRequiredCommand.new)
      add_command_to_list(Rails::SslAllowedCommand.new)

      # 20130815
      add_command_to_list(Rails::AliasMethodCommand.new)

      # 20130819
      add_command_to_list(Rails::HasManyCommand.new)
      add_command_to_list(Rails::BelongsToCommand.new)

      # Common?
      # Transition
      # C->C
      add_trans_command_to_list('redirect_to', 'redirect_to')

      # C->V, V->V
      add_trans_command_to_list('render', 'render')
      # V->C
      # TODO: get or keep original command? keep orig name for now <= easy to check the nav model table
      add_trans_command_to_list('link_to',   'link_to')
      add_trans_command_to_list('button_to', 'button_to')  # TODO: def is post, set by method

      # Dataflow
      # name, cmd_name, is_inbound(POST=>), is_outbound(GET=>)
      #-----------------------------------------------------------
      # In
      add_dataflow_command_to_list('input', 'input', true, false)
      # Out
      add_dataflow_command_to_list('label', 'label', false, true)
      add_dataflow_command_to_list('javascript_tag', 'javascript_tag', false, true)
      add_dataflow_command_to_list('stylesheet_link_tag', 'stylesheet_link_tag', false, true)
      add_dataflow_command_to_list('javascript_include_tag', 'javascript_include_tag', false, true)

      # http://rubydoc.info/github/plataformatec/simple_form/master/SimpleForm/FormBuilder
      add_dataflow_command_to_list('error_notification', 'error_notification', false, true)

      #-----------------------------------------------------------
      # Out/In
      add_dataflow_command_to_list('text_field', 'text_field', true, true)   # TODO: text_field => string
      add_dataflow_command_to_list('text_field_tag', 'text_field_tag', true, true)

      # text_area_tag
      # http://railsdoc.com/references/text_area_tag
      add_dataflow_command_to_list('text_area', 'text_area', true, true)
      add_dataflow_command_to_list('text_area_tag', 'text_area_tag', true, true)
      add_dataflow_command_to_list('password_field', 'password_field', true, false)
      add_dataflow_command_to_list('select_tag', 'select_tag', true, true)
      add_dataflow_command_to_list('content_tag', 'content_tag', true, true)

      # hidden_field_tag
      # http://railsdoc.com/references/hidden_field
      add_dataflow_command_to_list('hidden_field', 'hidden_field', true, true)
      add_dataflow_command_to_list('hidden_field_tag', 'hidden_field_tag', true, true)
      add_dataflow_command_to_list('check_box', 'check_box', true, true)
      add_dataflow_command_to_list('email_field', 'email_field', true, true)

      # TODO
      # ActiveSupport::Deprecation.warn
      # http://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html
      # http://d.hatena.ne.jp/kitokitoki/20110507/p1
      add_todo_command_to_list('warn', 'warn')

      # select
      # http://railsdoc.com/references/select
      add_todo_command_to_list('select', 'TODO')

      # radio_button
      # http://railsdoc.com/references/radio_button
      # TODO: skip?
      add_todo_command_to_list('radio_button', 'TODO')

      # cycle
      # http://railsdoc.com/references/cycle
      # TODO: skip?
      add_todo_command_to_list('cycle', 'TODO')

      # fields_for
      # http://railsdoc.com/references/fields_for
      # Block -> variable -> POST
      add_todo_command_to_list('fields_for', 'TODO')

      # error_messages_for
      # Model error -> view
      # http://apidock.com/rails/ActionView/Helpers/ActiveRecordHelper/error_messages_for
      add_todo_command_to_list('error_messages_for', 'TODO')

      # in_place_editor
      # OLD
      # http://apidock.com/rails/ActionView/Helpers/JavaScriptMacrosHelper/in_place_editor_field
      add_todo_command_to_list('in_place_editor', 'TODO')

      # send_file
      # http://railsdoc.com/references/send_file
      # download file
      add_todo_command_to_list('send_file', 'TODO')

      # code
      add_todo_command_to_list('include', 'TODO_rails_command')
      add_todo_command_to_list('require', 'TODO_rails_command')
      add_todo_command_to_list('extend', 'TODO_rails_command')

      # Exception
      # TODO: what happen?
      add_todo_command_to_list('raise', 'TODO_rails_command')

      #
      # Model
      #
      add_todo_command_to_list('has_and_belongs_to_many', 'TODO_rails_command')

      # accepts_nested_attributes_for
      # http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
      #   Nested attributes allow you to save attributes on associated records through the parent.
      add_todo_command_to_list('accepts_nested_attributes_for', 'TODO_rails_command')

      # serialize
      # http://d.hatena.ne.jp/kusakari/20100810/1281474933
      add_todo_command_to_list('serialize', 'TODO_rails_command')

      # read_attribute
      # http://apidock.com/rails/ActiveRecord/Base/read_attribute
      # http://blog.eiel.info/blog/2012/12/17/read-attribute-activerecord/
      add_todo_command_to_list('read_attribute', 'TODO_rails_command')

      # validate
      # TODO: SF? behavior?
      add_todo_command_to_list('validate', 'TODO_rails_command')
      add_todo_command_to_list('validates_presence_of', 'TODO_rails_command')
      add_todo_command_to_list('validates_format_of', 'TODO_rails_command')
      add_todo_command_to_list('validates_uniqueness_of', 'TODO_rails_command')
      add_todo_command_to_list('validates_associated', 'TODO_rails_command')
      add_todo_command_to_list('validates_inclusion_of', 'TODO_rails_command')

      # http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates_length_of
      add_todo_command_to_list('validates_length_of', 'TODO_rails_command')

      # http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates_numericality_of
      add_todo_command_to_list('validates_numericality_of', 'TODO_rails_command')

      # validates_exclusion_of
      # http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates_exclusion_of
      # TODO: add  Trans w/ error msg
      add_todo_command_to_list('validates_exclusion_of', 'TODO_rails_command')

      # validates_confirmation_of
      # http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates_confirmation_of
      # TODO: add trans, nav
      add_todo_command_to_list('validates_confirmation_of', 'TODO_rails_command')

      # write_attribute
      # http://apidock.com/rails/ActiveRecord/AttributeMethods/Write/write_attribute
      # update
      add_todo_command_to_list('write_attribute', 'TODO_rails_command')

      # attr_protected
      # http://apidock.com/rails/ActiveRecord/Base/attr_protected/class
      add_todo_command_to_list('attr_protected', 'TODO_rails_command')

      # before_validation
      # http://apidock.com/rails/ActiveRecord/Callbacks/before_validation
      add_todo_command_to_list('before_validation', 'TODO_rails_command')

      # after_destroy
      # http://apidock.com/rails/ActiveRecord/Callbacks/after_destroy
      add_todo_command_to_list('after_destroy', 'TODO_rails_command')

      # attribute_present?
      # http://apidock.com/rails/ActiveRecord/Base/attribute_present%3F
      add_todo_command_to_list('attribute_present?', 'TODO_rails_command')

      # cattr_accessor
      # http://apidock.com/rails/Class/cattr_accessor
      # http://rubyist.g.hatena.ne.jp/yamaz/20070107
      add_todo_command_to_list('cattr_accessor', 'TODO_rails_command')

      # class_eval
      # http://ref.xaio.jp/ruby/classes/module/class_eval
      # TODO: hard to conv to model. so ???
      add_todo_command_to_list('class_eval', 'TODO_rails_command')

      # before_destroy after_update
      # http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
      # http://ameblo.jp/axio9da/entry-10810821007.html
      add_todo_command_to_list('before_destroy', 'TODO_rails_command')
      add_todo_command_to_list('after_update', 'TODO_rails_command')

      # delete_all
      # http://apidock.com/rails/ActiveRecord/Base/delete_all/class
      # http://railsdoc.com/references/delete_all
      add_todo_command_to_list('delete_all', 'TODO_rails_command')

      # delegate
      # http://apidock.com/rails/Module/delegate
      # http://maeshima.hateblo.jp/entry/20101031/1288539329
      # mmethod...
      add_todo_command_to_list('delegate', 'TODO_rails_command')

      # assign_attributes
      # http://apidock.com/rails/ActiveRecord/Base/assign_attributes
      add_todo_command_to_list('assign_attributes', 'TODO_rails_command')

      # instance_variable_defined?
      # http://apidock.com/ruby/Object/instance_variable_defined%3F
      add_todo_command_to_list('instance_variable_defined?', 'TODO_rails_command')

      # default_scope
      # http://apidock.com/rails/ActiveRecord/Base/default_scope/class
      # http://railsdoc.com/references/default_scope
      # http://d.hatena.ne.jp/sinsoku/20110620/1308496688
      # control DB scope
      add_todo_command_to_list('default_scope', 'ignore')

      # require_dependency
      # http://apidock.com/rails/ActiveSupport/Dependencies/Loadable/require_dependency
      # http://d.hatena.ne.jp/sai-ou89/20081218/1208940536
      add_todo_command_to_list('require_dependency', 'ignore')

      # has_one
      # http://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_one
      # http://railsdoc.com/references/has_one
      # http://blog.digital-squad.net/article/278843296.html   has_one VS belong_to
      add_todo_command_to_list('has_one', 'TODO_rails_command')

      # update_attribute
      # http://apidock.com/rails/ActiveRecord/Base/update_attribute
      # http://d.hatena.ne.jp/LukeSilvia/20080816/p2   update_attribute VS update_attributes
      add_todo_command_to_list('update_attribute', 'TODO_rails_command')

      # update_all
      # http://apidock.com/rails/ActiveRecord/Base/update_all/class
      # http://d.hatena.ne.jp/zucay/20121026/1351219598
      add_todo_command_to_list('update_all', 'TODO_rails_command')

      # class_attribute
      # http://apidock.com/rails/Class/class_attribute
      add_todo_command_to_list('class_attribute', 'TODO_rails_command')

      # include?
      # e.g. seen.include?(name)
      add_todo_command_to_list('include?', 'TODO_rails_command')

      # join
      add_todo_command_to_list('join', 'TODO_rails_command')

      # http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
      # http://qiita.com/yaotti/items/87cfdabf7f1e7b3d83a8
      # Block
      add_todo_command_to_list('before_save', 'TODO_rails_command')
      add_todo_command_to_list('before_create', 'TODO_rails_command')
      add_todo_command_to_list('after_create', 'TODO_rails_command')
      add_todo_command_to_list('after_save', 'TODO_rails_command')
      add_todo_command_to_list('after_commit', 'TODO_rails_command')

      # View
      # C->V->C

      # url_for
      # http://railsdoc.com/references/url_for
      # TODO: link to?
      add_todo_command_to_list('url_for', 'TODO_rails_command')

      # http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html
      # TODO: add trans
      add_todo_command_to_list('link_to_if', 'TODO_rails_command')
      add_todo_command_to_list('link_to_unless', 'TODO_rails_command')
      add_todo_command_to_list('link_to_unless_current', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/AssetTagHelper/favicon_link_tag
      add_todo_command_to_list('favicon_link_tag', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/FormTagHelper/label_tag
      # TODO: dataflow?
      add_todo_command_to_list('label_tag', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/FormTagHelper/password_field_tag
      add_todo_command_to_list('password_field_tag', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/CaptureHelper/content_for
      add_todo_command_to_list('content_for', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/FormTagHelper/check_box_tag
      add_todo_command_to_list('check_box_tag', 'TODO_rails_command')

      # http://apidock.com/rails/ActionView/Helpers/JavaScriptHelper/escape_javascript
      # TODO: security func
      add_todo_command_to_list('escape_javascript', 'TODO_rails_command')

      #
      # Controller
      #
      add_todo_command_to_list('rescue_from', 'TODO_rails_command')

      # http://apidock.com/rails/ActionController/Filters/ClassMethods/append_before_filter
      add_todo_command_to_list('append_before_filter', 'TODO_rails_command')

      # http://apidock.com/rails/ActionController/Filters/ClassMethods/after_filter
      # http://apidock.com/rails/AbstractController/Callbacks/ClassMethods/after_filter
      add_todo_command_to_list('after_filter', 'TODO_rails_command')

      # http://apidock.com/rails/ActionController/Streaming/send_data
      # Sends the given binary data to the browser
      add_todo_command_to_list('send_data', 'TODO_rails_command')

      # http://apidock.com/rails/ActionController/Caching/Actions
      # http://apidock.com/rails/ActionController/Caching/Actions/ClassMethods/caches_action
      # Declares that actions should be cached.
      add_todo_command_to_list('caches_action', 'TODO_rails_command')

      # load_resource
      add_todo_command_to_list('load_resource', 'TODO_rails_command')

      # render_to_string
      # http://railsdoc.com/references/render_to_string
      add_todo_command_to_list('render_to_string', 'TODO_rails_command')

      #
      # Ruby?
      #
      # http://api.rubyonrails.org/classes/ActionController/Head.html
      add_todo_command_to_list('head', 'TODO_rails_command')
      add_todo_command_to_list('send', 'TODO_rails_command')
      add_todo_command_to_list('to_s', 'TODO_rails_command')

      # http://ref.xaio.jp/ruby/classes/module/attr_accessor
      add_todo_command_to_list('attr_reader', 'TODO_rails_command')
      add_todo_command_to_list('attr_accessor', 'TODO_rails_command')

      # image_tag
      add_todo_command_to_list('image_tag', 'ignore')

      # cache_sweeper
      # http://apidock.com/rails/ActionController/Caching/Sweeping/ClassMethods/cache_sweeper
      # http://devml.blogspot.jp/2011/01/rails3sweep.html
      add_todo_command_to_list('cache_sweeper', 'ignore')

      rails_command_list = {
        'protect_from_forgery' => {
          type:       'unknown_filter',
          providedby: 'rails',
        },
        # RAILS_ROOT/lib/authenticated_system.rb?
        'login_required' => {
          type:       'unknown_filter',
          providedby: 'rails',
        },
        # http://railsdoc.com/references/validates
        # TODO: Dataflow?
        'validates' => {
          type:       'unknown_filter',
          providedby: 'rails',
        },
        'puts' => {
          type:       'unknown',
          providedby: 'ruby',
        },
        'p' => {
          type:       'unknown',
          providedby: 'ruby',
        },
        # Get Test
        't' => {
          type:       'unknown',
          providedby: 'ruby',
        },
        'helper_method' => {
          type:       'unknown',
          providedby: 'rails',
        },

        # Be generic
        # From
        'form_for' => {
           type:       'input_dataflow',  # form_for form_tag
           subtype:    'form',
           providedby: 'rails',
        },
        'form_tag' => {
           type:       'input_dataflow',  # form_for form_tag
           subtype:    'form',
           providedby: 'rails',
        },
        # submit/POST

        'submit' => {
          type:       'transition',
          subtype:    'post',
          providedby: 'rails',
        },
        'submit_tag' => {
          type:       'transition',
          subtype:    'post',
          providedby: 'rails',
        },
        'button' => {
          type:       'transition',
          subtype:    'post',
          providedby: 'rails',
        },
      }
      add_command_list(rails_command_list)

      # simple_form
      # https://github.com/plataformatec/simple_form
      simple_form_command_list = {
        'simple_form_for' => {
           type:       'input_dataflow',  # form_for form_tag
           subtype:    'form',
           providedby: 'simple_form',
        },
      }
      add_command_list(simple_form_command_list)

      # semantic_menu
      # https://github.com/danielharan/semantic-menu
      semantic_menu_command_list = {
        'semantic_menu' => {
           type:       'input_dataflow',
           subtype:    'form',
           providedby: 'semantic_menu',
        },

        'add' => {
           type:       'transition',
           subtype:    'link_to',
           providedby: 'semantic_menu',
        },
      }
      add_command_list(semantic_menu_command_list)
    end
  end
end
