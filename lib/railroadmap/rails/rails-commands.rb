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

      # Load JSON command libraries
      Dir[File.join(File.dirname(__FILE__), '../command_library/*.json')].each do |path|
        $log.debug "load  JSON command libraries #{path}"
        add_json_command_list(path)
      end
    end
  end
end
