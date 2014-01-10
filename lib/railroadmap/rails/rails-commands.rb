# -*- coding: UTF-8 -*-
# Commands of Rails Framework
#
# TODO: commonization and generalization => asb.rb
#
# 2013-12-18 SM before_filters => rails.json and ast.rb
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

      # TODO: not executed 20130630
      add_command_to_list(Rails::SslRequiredCommand.new)
      add_command_to_list(Rails::SslAllowedCommand.new)

      # 20130815
      add_command_to_list(Rails::AliasMethodCommand.new)

      # 20130819
      add_command_to_list(Rails::HasManyCommand.new)
      add_command_to_list(Rails::BelongsToCommand.new)
    end
  end
end
