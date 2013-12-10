# -*- coding: UTF-8 -*-
# Class to hold the all warnings
#
# Hash
#   key  : RRMW0000
#   value: Hash
#          warning_type
#          file
#          file2
#          message
#          confidence
#          test_type
#          test_result

# Warning holder
class Warning
  def initialize
    @count = 0
    @fp_count = 0  # False positive count
    @fp_warnings = [] # Array
    # Key is ID  e.g. RRMW0007
    @warnings = {} # Hash
  end
  attr_accessor :count, :fp_count, :warnings

  # Add new warning
  # w : hash
  def add(w)
    w['id'] = @count
    key = format("RRMW%04d", @count)
    @count += 1
    @warnings[key] = w
  end

  # def suppressFalsePositive
  def suppress_falsepositive
    if @count > 0 && !$fp_list.nil?
      print "Suppress false positive warning"
      @warnings.each do |k, w|
        msg = w['message']
        unless $fp_list[msg].nil?
          w['confidence'] = 'FalsePositive'
          w['falspositive'] = $fp_list[msg]
          @fp_count += 1
        end
      end
    end
  end

  # def printFalsePositiveMask
  def print_falsepositive_mask
    if (@count - @fp_count) > 0
      puts "The following example can be used to supress Fals Positive warnings"
      puts "  railroadmap/requirements.rb"
      puts "---"
      puts "  $fp_list = Hash.new"
      @warnings.each do |k, w|
        if w['confidence'] != 'FalsePositive'
          msg = w['message']
          puts "  $fp_list['#{msg}'] = 'TBD'"
        end
      end
      puts "---"
    end
  end

  # return number of warnings
  def size
    @warnings.size
  end

  # shorten the filename
  def update_file2(rootdir1, rootdir2)
    @warnings.each do |k, w|
      filenames =  w['file']
      if filenames.nil?
        # SKIP
      elsif filenames.class == Array
        cont = false
        f2 = ''
        filenames.each  do |f|
          if f.nil?
            $log.error "update_file2 #{rootdir1}  #{rootdir2}"
          else
            if cont
              f2 += ','
            else
              cont = true
            end
            f2 += f.sub(rootdir1, rootdir2)
          end
        end
        # remove last ','
        w['file2'] = f2
      else
        $log.debug "Unknown file class #{filenames.class}"
      end
    end
  end

  # 2013-04-11 added
  # return key of XSS warning by state, variable
  def get_key_of_xssout(state, variable)
    @warnings.each do |key, warning|
      return key if (warning['hit_state'] == state) && (warning['hit_variable'] == variable)
    end
    nil
  end

  # after test update the warning
  def set_xss_test_tp(key)
    warning = @warnings[key]
    warning['test_type'] = "XSS"
    warning['test_result'] = "True-positive"
  end
end  # class
