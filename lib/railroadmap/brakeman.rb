# -*- coding: UTF-8 -*-
# brakeman.rb
#
#  $ gem update brakeman
#  $ brakeman -f json > brakeman.json
#
# Brakeman reports --(json)-+
#                           |
#                           V
#                       blank map  -> hazard map (Abuse model)
#
#
class Brakeman
  def initialize
    @brakeman_hash = nil
    @warnings = {}
    @errors = {}
    @hit_state_count = 0
  end
  attr_accessor :warnings, :errors

  def load_json_result(filename)
    open(filename, 'r') { |fp| @brakeman_hash = JSON.parse(fp.read) }

    @warnings = @brakeman_hash['warnings']
    @errors   = @brakeman_hash['errors']

    # to Dashboard. TODO: use $brakeman.warnings
    $brakeman_warnings = warnings
  end

  def set_hazard_map
    id = 0
    @warnings.each do |w|
      # copy
      type    = w['warning_type']
      message = w['message']
      file    = w['file']
      line    = w['line']

      # add attribute to brakeman warning
      w['id'] = id
      id += 1
      w['hit_state'] = ''
      w['hit_variable'] = ''
      # shorten filename, remove $approot_dir
      w['file2'] = file.sub($approot_dir, '.')

      if $verbose == 1
        puts "    id       : #{id}"
        puts "    type    : #{type}"
        puts "    message : #{message}"
      end

      # TODO: controller has multiple def (=states) => use line# to identify the exact state.
      # TODO: use hash to fined states?
      hit_state = nil
      $abst_states.each do |k, state|
        state.filename.each do |f|
          if f == file
            if state.start_linenum < line
              # last hit is the state we are looking for.
              hit_state = state
            end
          end
        end
      end
      unless hit_state.nil?
        # Set flag to the state
        mark = Abstraction::Mark.new('brakeman')
        mark.brakeman(type, message, line)
        hit_state.add_mark(mark)
        # Update attribute to brakeman warning
        w['hit_state'] = hit_state.id
        @hit_state_count += 1
      end
    end
  end

  def update_gems
    return if $gems.nil?

    @warnings.each do |w|
      if w['file'] == 'Gemfile'
        # Gem
        message = w['message']
        /(\w+) ([0-9.]+)/ =~ message
        gem_name = Regexp.last_match[1].downcase
        version = Regexp.last_match[2]

        if $gems.gems[gem_name].nil?
          # MISS
          $log.error "#{gem_name} is missing"
        else
          # HIT
          g = $gems.gems[gem_name]
          g[:warnings] ||= []
          g[:warnings] << message
          print "\e[31m"  # red
          puts "      #{gem_name} #{version} #{message}"
          print "\e[0m" # reset
        end
      end
    end
  end

  def print_stat
    if @warnings.size > 0
      print "\e[31m"  # red
      puts "    warnings  : #{@warnings.size} (brakeman)"
      print "\e[0m" # reset
    else
      print "\e[32m"  # green
      puts "    warnings  : #{@warnings.size} (brakeman)"
      print "\e[0m" # reset
    end

    if @errors.size > 0
      print "\e[31m"  # red
      puts "    errors    : #{@errors.size} (brakeman)"
      print "\e[0m" # reset
    else
      print "\e[32m"  # green
      puts "    errors    : #{@errors.size} (brakeman)"
      print "\e[0m" # reset
    end

    puts "    Hit states: #{@hit_state_count} (total)"
  end
end
