# -*- coding: UTF-8 -*-
# View
#

require 'rubygems'
require 'erb/stripper'
require 'ripper'
require 'pp'
require 'active_support/inflector' # String#pluralize  <-> String#singularize
require 'haml'

# Abstraction of View
module Abstraction
  module Parser
    # View states
    class View < Abstraction::Parser::AstParser

      #  parse AST
      def parse_sexp(level, sexp)
        if sexp.nil?
          $log.error "parse_sexp() esxp is null"
          fail "DEBUG"
          # return nil
        end

        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'command')
          return add_command(level, sexp, 'view')
        end

        # Block
        # TODO: add do_block
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'if')
          return add_block(level, sexp, 'if')
        end
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'elsif')
          return add_block(level, sexp, 'elsif')
        end
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'else')
          return add_block(level, sexp, 'else')
        end
        # MOD
        if (sexp[0].class == Symbol) && (sexp[0] == :if_mod)
          return add_block(level, sexp, 'if_mod')
        end

        if (sexp[0].class == Symbol) && (sexp[0] == :do_block)
          # add block_var
          if sexp[1].nil?
            # without block var
            $log.debug "parse_sexp do_block w/o var - start #{@filename}"
            parse_sexp_common(level, sexp)
            $log.debug "parse_sexp do_block w/o var - end"
          else
            var = sexp[1][1][1][0][1]
            $block_var << var
            $log.debug "parse_sexp do_block - start  $block_var = #{$block_var} #{@filename}"
            parse_sexp_common(level, sexp)
            $log.debug "parse_sexp do_block - end    $block_var = #{$block_var}"
            # remove block_var
            $block_var.delete_if { |x| x == var }
          end
          return
        end

        # TODO: SUBMIT
        if (sexp[0].class == Symbol) && (sexp[0] == :method_add_block)
          parse_sexp_common(level, sexp)
          return
        end

        if (sexp[0].class == Symbol) && (sexp[0] == :method_add_arg)
          if sexp[1][0] == :fcall
            return add_fcall(level, sexp, 'view')
          else
            $log.info "parse_sexp() method_add_arg"
            parse_sexp_common(level, sexp)
            return
          end
        end

        if (sexp[0].class == Symbol) && (sexp[0] == :command_call)
          return add_command_call(level, sexp, 'view')
        end
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'call')
          return add_call(level, sexp, 'view')
        end
        parse_sexp_common(level, sexp)
      end

      # Load view/*erb
      #  ERB -> Ruby -> AST -> abst. model
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        $filename = filename
        $is_private   = false
        $is_protected = false
        $form_target = nil # TODO

        $log.debug "load : #{modelname} #{filename}"
        # Model name, action
        if filename =~ /views\/(\w+)\/(\w+).erb/
          # app/views/HOGE/FOO.erb
          # app/views/catalog/sms.erb
          @model  = Regexp.last_match[1].singularize
          @action = Regexp.last_match[2]
          @format = 'html'  #  TODO
        elsif filename =~ /views\/(\w+)\/(\w+)\/(\w+).erb/
          # app/views/HOGE/HOGE/FOO.erb
          @model  = Regexp.last_match[1].singularize  +  ':' + Regexp.last_match[2].singularize
          @action = Regexp.last_match[3]
          @format = 'html'  #  TODO
        elsif filename =~ /views\/(\w+)\/(\w+).(\w+).erb/
          # app/views/line_items/_line_item.text.erb
          @model  = Regexp.last_match[1].singularize
          @action = Regexp.last_match[2]
          @format = Regexp.last_match[3]
        elsif filename =~ /views\/(\w+)\/(\w+)\/(\w+).(\w+).erb/
          # app/views/HOGE/HOGE/FOO.text.erb
          @model  = Regexp.last_match[1] + ':' + Regexp.last_match[2].singularize
          @action = Regexp.last_match[3]
          @format = Regexp.last_match[4]
        else
          $log.error "load(),  unknown action  filename=#{filename}"
        end

        if @format != 'html'
          @id = @model + '_' + @action + '_' + @format
          n = @model + "#" + @action + "#" + @format
        else
          @id = @model + '_' + @action
          n = @model + "#" + @action
        end

        # new View state
        s = add_state('view', n, @filename)
        $block_var = []

        # ERB ->  Ruby
        @erb = File.read(@filename)
        @ruby = Erb::Stripper.new.to_ruby(@erb)
        # Ruby -> AST
        $log.debug "Ruby -> AST"
        s = Ripper.sexp(@ruby)

        $log.debug "AST -> Model"
        parse_sexp(0, s)

        # DEBUG
        $log.debug "GUARD #{$state.filename}"
        pp $conditions if $debug
      end

      # Load view/*haml
      #  HAML -> Ruby -> AST -> abst. model
      def load_haml(modelname, filename)
        @modelname = modelname
        @filename = filename
        $filename = filename
        $is_private   = false
        $is_protected = false
        $form_target = nil # TODO

        $log.debug "load haml: #{modelname} #{filename}"
        # Model name, action
        if filename =~ /views\/(\w+)\/(\w+).haml/
          # app/views/HOGE/FOO.haml
          @model  = Regexp.last_match[1].singularize
          @action = Regexp.last_match[2]
          @format = 'html'  #  TODO
          $log.debug "load() HAML #{@model} #{@action} #{@format}"
        elsif filename =~ /views\/(\w+)\/(\w+)\/(\w+).haml/
          # app/views/HOGE/HOGE/FOO.haml
          @model  = Regexp.last_match[1].singularize  + ':' + Regexp.last_match[2].singularize
          @action = Regexp.last_match[3]
          @format = 'html'  #  TODO
          $log.debug "load() HAML #{@model} #{@action} #{@format}"
        elsif filename =~ /views\/(\w+)\/(\w+).(\w+).haml/
          # app/views/HOGE/XXX.html.haml
          @model  = Regexp.last_match[1].singularize
          @action = Regexp.last_match[2]
          @format = Regexp.last_match[3]
          $log.debug "load() HAML #{@model} #{@action} #{@format} #{filename}"
        elsif filename =~ /views\/(\w+)\/(\w+)\/(\w+).(\w+).haml/
          # app/views/HOGE/HOGE/FOO.html.haml
          @model  = Regexp.last_match[1] + ':' + Regexp.last_match[2].singularize
          @action = Regexp.last_match[3]
          @format = Regexp.last_match[4]
          $log.debug "load() HAML #{@model} #{@action} #{@format}"
        else
          $log.info "load() HAML unknown action  filename=#{filename}"
        end

        if @format != 'html'
          @id = @model + '_' + @action + '_' + @format
          n = @model + "#" + @action + "#" + @format
        else
          @id = @model + '_' + @action
          n = @model + "#" + @action
        end

        # new View state
        add_state('view', n, @filename)
        $block_var = []

        # HAML ->  Ruby -> AST
        haml_code = File.read(@filename)
        ruby_code = conv_haml2ruby(haml_code)

        s = Ripper.sexp(ruby_code)
        if s.nil?
          $log.error "HAML no code #{@filename}"
          fail "TODO:"
        else
          parse_sexp(0, s)
        end
      end

      # HAML to Ruby
      def conv_haml2ruby(haml_code)
        begin
          haml_version = Gem::Version.create(Haml::VERSION)
        rescue
          # Haml 3.X
          raise "Sorry. Haml #{Haml::VERSION} is not supported. Update the Rails to 3.2"
        end

        # p haml_version
        if haml_version > Gem::Version.create('4.0.0')
          # Haml 4.X
          @options = Haml::Options.new
          @haml = Haml::Parser.new(haml_code, @options)
        else
          fail "Haml 3.X is not supported"
          # @haml = Haml::Engine.new(@template)
        end

        @haml2ruby = "# haml2ruby\n"

        @haml.parse
        @node = nil
        @indent = 0
        compile(@haml.root)
        return  @haml2ruby
      end

      # Haml compile
      def compile(node)
        parent, @node = @node, node
        if node.children.empty?
          send(:"compile_#{node.type}")
        else
          send(:"compile_#{node.type}") { node.children.each { |c| compile c } }
        end
      ensure
        @node = parent
      end

      def compile_root
        yield if block_given?
      end

      def compile_tag
        $log.error "TODO: tag text" unless @node.value[:text].nil?

        code = @node.value[:value]
        if @node.value[:parse] == true
          haml2ruby_add("#{code}  # tag value #{@indent}")
        else
          haml2ruby_add("# #{code}  # tag parse==false")
        end

        if block_given?
          @indent += 1
          yield
          @indent -= 1
          haml2ruby_add(" end  # tag: #{code}") unless code.nil?
        end
      end

      def compile_silent_script
        code = @node.value[:text]
        haml2ruby_add("#{code}  # silent_script #{@indent}")
        if block_given?
          @indent += 1
          yield
          @indent -= 1
          haml2ruby_add(" end  # silent_script: #{code}")
        end
      end

      def compile_script
        code = @node.value[:text]
        haml2ruby_add("#{code}  # script")
        if block_given?
          @indent += 1
          yield
          @indent -= 1
          haml2ruby_add(" end  # script: #{code}")
        end
      end

      def compile_haml_comment
        haml2ruby_add("# haml_comment")
      end

      def compile_plain
        haml2ruby_add("# plain")
      end

      def compile_doctype
        haml2ruby_add("# doctype")
      end

      def compile_comment
        haml2ruby_add("# comment")
      end

      def compile_filter
        haml2ruby_add("# filter")
      end

      def haml2ruby_add(code)
        code = "# nil" if code.nil?
        indent = "  "
        indent = "    " if @indent == 1
        indent = "       " if @indent == 2
        indent = "          " if @indent == 3
        indent = "             " if @indent == 4
        indent = "               " if @indent > 4

        @haml2ruby += indent  + code + "\n"
      end

    end  # class view
  end # mod
end # mod
