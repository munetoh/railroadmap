# -*- coding: UTF-8 -*-
# Security Assurance Model (=Security dashboard)
#
#  * Overall summary
#  * Detail
#  * Raional
#
#  TODO: be common OR just for Rails?
#  TODO: be global?
#  TODO: update to v020
#
# List of weakness  => Dashboard
#
class Weakness
  def initialize(name)
    @name = name
    @feature = ''  # Function or Countermeasure
    @covered_percent = 0
    @locations = []  # TODO: remove
    @assets = []     # TODO:  domain+type?
    @testcases = []  # TC-XXX
    @note = ''
  end
  attr_accessor :name, :feature, :covered_percent, :locations, :assets, :testcases, :note
end

#
# Commands
#
class Command
  def initialize(name, support, feature, comment)
    @name = name
    @support = support
    @feature = feature
    @comment = comment
    @unclear = false
  end
  attr_accessor :name, :support, :feature, :comment, :unclear
end

#
# Design
#  1. M-V-C  list with AA status
#  2. Commands
#
#                       PDP
#                       roles
#              +-----> +policy(level/categories)
#              |
#  Code --> Assets --> PEP
#
#   Controller -- PEP placement check
#
class Design
  # init
  def initialize
    @c_assets = {}
    @m_assets = {}
    @v_assets = {}

    @c_assets_count = 0
    @m_assets_count = 0
    @v_assets_count = 0

    @unclear_pep = 0
    @unclear_acg = 0
    @unclear_ppep = 0

    $remidiation_req_list = []

    # PDP
    if $authorization_module.nil?
      # TODO: NUL model?
      @pdp = Rails::PDP.new
    else
      # TODO: if CanCan
      @pdp = $authorization_module
    end

    #----------------------------------------------------------------------
    # Transitions
    # 1st pass, C and V-V
    $abst_states.each do |n, s|
      if s.type == 'controller'
        if s.is_private || s.is_protected
          $log.debug "Design.initialize() skip #{s.id}"
        else
          @c_assets[n]     = s
          @c_assets_count += 1
          @unclear_pep    += s.setup4dashboard_controller
        end
      elsif s.type == 'view'
        @v_assets[n] = s
        @v_assets_count += 1
        @unclear_acg    += s.setup4dashboard_view_pass1  # ACG :Access Control Guard
      elsif s.type == 'model'
      else
        $log.error "No type for #{s.id}"
      end
    end

    # 2nd pass, C-M and C-V
    $abst_states.each do |n, s|
      if s.type == 'view'
        @unclear_acg    += s.setup4dashboard_view_pass2  # ACG :Access Cntrol Guard, V->V
      elsif s.type == 'model'
        @m_assets[n]     = s
        @m_assets_count += 1
        @unclear_ppep   += s.setup4dashboard_model  # PPEP: Pre PEP, PEP at C
      end
    end

    #----------------------------------------------------------------------
    # Variables and Dataflow
    # set policy for variables
    @unclear_var = 0
    $abst_variables.each do |n, v|
      @unclear_var += v.setup4dashboard
    end

    # Check dataflow
    @unclear_dfp = 0  # dataflow policy
    $abst_dataflows.each do |n, df|
      # set policy
      if df.type == 'in'
        # policy of input state
        s = $abst_states[df.src_id]
        if s.nil?
          $log.error "TODO: path=in but no src state for #{df.src_id} #{df.type}"
          df.in_policy = { level: nil }
        else
          df.in_policy = { level: s.code_policy.level }
        end

        # policy of output v
        s2 = $abst_variables[df.dst_id]
        if s2.nil?
          $log.info "initialize() DATAFLOW POLICY no policy for #{df.dst_id} => try alias"
          # try alias
          dst_id = get_alias_id(df.dst_id)
          s2 = $abst_variables[dst_id]
          if s2.nil?
            # $log.error "initialize() DATAFLOW POLICY no policy for #{df.dst_id}"
            df.variable_policy = { level: nil }
          else
            $log.error "no policy for #{df.dst_id} => #{dst_id}"
            df.variable_policy = { level: s2.code_policy.level }
          end
        else
          # $log.error "policy for #{df.dst_id} => #{dst_id}"
          df.variable_policy = { level: s2.code_policy.level }
        end

        # TODO: where is the best place to check the policy
        # V-O policy check
        df.is_unclear_policy = false
        df.unclear_policy_comment = ""
        if df.in_policy[:level].nil?
          # No policy -> Any  => OK
        elsif df.variable_policy[:level].nil?
          # Policy -> no Policy
          $log.info "initialize() DATAFLOW POLICY  WARNING1?  #{df.in_policy[:level]}  -> #{df.variable_policy[:level]}  at #{df.src_id} -> #{df.dst_id}"
          df.is_unclear_policy = true
          df.unclear_policy_comment = "downstream policy from input to variable"
          @unclear_dfp += 1
        elsif df.in_policy[:level] > df.variable_policy[:level]
          # $log.error "WARNING2?  #{df.in_policy[:level]}  -> #{df.variable_policy[:level]}  at #{df.src_id} -> #{df.dst_id}"
          df.is_unclear_policy = true
          df.unclear_policy_comment = "downstream policy from input to variable"
          @unclear_dfp += 1
        end
      elsif df.type == 'control'
        # $log.error "control"
        # TODO: ?
      else # out
        # variable
        s2 = $abst_variables[df.src_id]
        if s2.nil?
          # $log.error "initialize() DATAFLOW POLICY no policy for #{df.src_id} => #{df.dst_id}"
          df.variable_policy = { level: nil }
        else
          # $log.error "set policy for #{df.src_id} level=#{s2.code_policy.level} => #{df.dst_id}"
          df.variable_policy = { level: s2.code_policy.level }
        end

        # policy of output state
        s = $abst_states[df.dst_id]
        df.out_policy = { level: s.code_policy.level } unless s.nil?

        # TODO: where is the best place to check the policy
        # V-O policy check
        df.is_unclear_policy = false
        df.unclear_policy_comment = ""
        if df.variable_policy[:level].nil?
          # No policy -> Any  => OK
        elsif df.out_policy[:level].nil?
          # Policy -> no Policy
          df.unclear_policy_comment = "Output policy level is low"
          @unclear_dfp += 1
        elsif  df.variable_policy[:level] > df.out_policy[:level]
          df.unclear_policy_comment = "Output policy level is low"
          @unclear_dfp += 1
        end
      end
    end

    if $remidiation_req_list.size > 0
      # Print remidiation
      print "\e[31m"  # red
      puts "    missing req.        : #{$remidiation_req_list.size} (view states)"
      puts "    add the following requirements to except the check."
      # v0.1.0
      # puts "# railroadmap/requireents.rb"
      # puts "---"
      # puts "$assets = {"
      # $remidiation_req_list.each do |r|
      #   puts r
      # end
      # puts "}"
      # puts "---"
      print "\e[0m"  # reset
    else
      # print "\e[32m"  # green
      puts "    missing requirments (view)  : 0"
    end

    # PDP
    # check unused roles
    @unused_role, missing_role_count = @pdp.setup4dashboard_roles

    # Update asset list for missing role
    @unclear_pep += missing_role_count

    # Sum up
    @unclear = @unused_role + @unclear_pep + @unclear_acg + @unclear_ppep

    print "\e[32m"  # green
    print "\e[31m" if @unclear_pep > 0   # red
    puts "    controller     : #{@c_assets_count}  (#{@unclear_pep} unclear PEP)"
    print "\e[0m"  # reset

    print "\e[32m"  # green
    print "\e[31m" if @unclear_acg > 0   # red
    puts "    view           : #{@v_assets_count}  (#{@unclear_acg} unclear ACG)"
    print "\e[0m"  # reset

    print "\e[32m"  # green
    print "\e[31m" if @unclear_ppep > 0   # red
    puts "    model          : #{@m_assets_count}  (#{@unclear_ppep} unclear Pre PEP)"
    print "\e[0m"  # reset

    print "\e[32m"  # green
    print "\e[31m" if @unclear_var > 0   # red
    puts "    variables      : #{$abst_variables.count}  (#{@unclear_var} unclear variables)"
    print "\e[0m"  # reset

    print "\e[32m"  # green
    print "\e[31m" if @unclear_dfp > 0   # red
    puts "    dataflows      : #{$abst_dataflows.count}  (#{@unclear_dfp} downstream dataflows)"
    print "\e[0m"  # reset

    # Commands <= cli.rb, ast.rb
    @unclear_command = 0 # TODO
    @commands = $abst_commands
    # count unclear
    $abst_commands.each do |k, c|
      if c.providedby == 'unknown'
        @unclear_command += 1
        c.unclear = true
      else
        c.unclear = false
      end
    end
  end
  attr_accessor :pdp, :c_assets, :m_assets, :v_assets, :commands, :unused_role, :unclear_pep, :unclear_acg, :unclear, :unclear_command

  def get_alias_id(id)
    return nil if id == 'unknown'
    $log.info "get_alias_id() POLICY TODO: get id for '#{id}'"
    # Missing
    return nil
  end
end

#---------------------------------------------------------------------------------
# SMODEL
class SecurityAssuranceModel
  #
  def initialize
    @source_files = []
    @groups = []
    @weaknesses = []
    @rational = []

    # TODO: added  by config?
    #   weakness <= config
    #    feature <= auto?
    #
    w1 = Weakness.new('Improper Authentication')
    w1.feature = 'Devise'  # TODO: ?
    @weaknesses << w1

    w2 = Weakness.new('Improper Authorization')
    w2.feature = 'CanCan'  # TODO: ?
    @weaknesses << w2

    w3 = Weakness.new('Mass Assignment')
    w3.feature = 'Rails'  # TODO: ?
    @weaknesses << w3

    w4 = Weakness.new('Cross-site scripting')
    w4.feature = 'Rails'  # TODO: ?
    @weaknesses << w4

    w5 = Weakness.new('SQL injecton')
    w5.feature = 'Rails'  # TODO: ?
    @weaknesses << w5

    w6 = Weakness.new('CSRF')
    w6.feature = 'Rails'  # TODO: ?
    @weaknesses << w6

    #
    # Design
    #
    @design = Design.new

    #
    # Dataflow
    #
    @downsteram_policy_count = 0
    @dataflows, @raw_out_count = get_dataflows

  end
  attr_accessor :dataflows, :raw_out_count, :downsteram_policy_count

  def covered_percent
    # TODO: calc
    return 50
  end

  def source_files
    return @source_files
  end

  def groups
    return @groups
  end

  def command_name
    return 'TBD'
  end

  #
  # Dashboard - weakness
  #
  def weaknesses  # TODO: Overall
    return @weaknesses
  end

  # W
  def warnings
    if $warning.nil?
      $log.error "No warnings => check JSON?"
      return []
    else
      $log.debug "warnings #{$warning.count}"
      # TODO: Array => Hash
      return $warning.warnings # Array
    end
  end

  # W count
  def warning_count
    if $warning.nil?
      return 0
    else
      cnt = $warning.count - $warning.fp_count
      return cnt
    end
  end

  # E
  def errors
    if $errors.nil?
      $log.error "No errors => check JSON?"
      return []
    else
      $log.debug "errors #{$warning.count}"
      # TODO: Array => Hash
      return $errors.errors # Array
    end
  end

  def errors_count
    $errors.severity2_count + $errors.severity3_count
  end

  # Brakeman
  def brakeman_warnings
    if $brakeman_warnings.nil?
      $log.debug "No brakeman warnings => TODO"
      return []
    else
      $log.debug "warnings #{$brakeman_warnings.length}"
      return $brakeman_warnings
    end
  end

  #
  # Design
  #   AC table + asset list
  def design
    return @design
  end

  # Nav Model
  # smodel.states, smodel.transitions, smodel.variables, smodel.dataflows
  # Dashboard->Nav model
  def transitions
    # TODO: missing contents after some step??? 2013-04-02
    # table.rb
    count = 0
    $abst_transitions.each do |n, t|
      if t.invalid == false
        bgcolor       = '#ffffff'
        tr_bgcolor    = '#ffffff'
        src_label = t.src_id + '[' + t.count.to_s + ']'
        src = $abst_states[t.src_id]

        # Type
        type = t.type
        #  select tr color
        if t.type == 'link_to'
          type = "link_to(#{t.title})"
          tr_bgcolor    = '#70ff70'
        elsif t.type == 'submit'
          type = "submit(#{t.title}, #{t.variables})"  # TODO: title is nil 2012/4/24, TODO: put variables too
          tr_bgcolor    = '#ff7070' # RED
        elsif t.type == 'redirect_to'
          tr_bgcolor    = '#ff7070' # RED
        elsif t.type == 'render'
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'render_def1'
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'render_def2'
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'render_with_scope'
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'render_def3'
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'render_def4'   # implicit action
          tr_bgcolor    = '#d0d0d0' # gray
        elsif t.type == 'button_to'
          tr_bgcolor    = '#ff7070' # RED
        else
          # TODO: else?
          $log.error "unknown #{t.type}"
        end

        if t.invalid
          tr_bgcolor    = '#d0d000' # YELLOW
          type = type + ' (INVALID)'
        end

        if t.nav_error
          tr_bgcolor    = '#F0F000' # YELLOW
        end

        guard_bgcolor = tr_bgcolor
        dst_bgcolor   = tr_bgcolor

        # Guard Condition
        # Block condition
        guard = t.block.abst_condition_success unless t.block.nil?
        if guard.nil?
          if !t.guard_add.nil?
            guard = t.guard_add
          else
            case src.type
            when 'controller'
              if t.guard.nil?
                guard = "true"
              else
                # Use given guard
                guard = "#{t.guard}"
              end
            when 'view'
              guard = "selected by user"
            else
              guard = "[block id=#{t.block.id}]"
              guard_bgcolor = '#ffff00'
              t.is_unclear_guard = true
            end
          end
        else
          unless t.guard_add.nil?
            # add guard
            guard = guard + ' and (' + t.guard_add + ')'
          end

          if src.type == 'view'
            guard = guard + " and selected by user"
          else
            # t.is_unclear_guard = true
          end
        end
        t.guard_abst = guard
        t.authorization_filter = t.block.get_authorization_filter

        # TODO: action
        # p t.block.id
        action = $abstmap_action[t.block.id]
        if action.nil?
          action = '(@' + t.block.id + ')'
        else
          action = action + '<br>(@' + t.block.id + ')'
        end

        dst = nil
        if t.dst_id.nil?
          # Still unknown
          dst_id = Sorcerer.source(t.dst_hint)
          dst_bgcolor = '#ffff00'
          t.is_unclear_dst = true
        else
          # Ok
          dst_id = t.dst_id
          dst = $abst_states[t.dst_id]
        end

        # copy to Dashboard
        t.db_src = src_label
        t.db_dst = dst_id
        t.db_type = type
        t.db_guard = guard
        t.db_id = t.index

        t.db_src_policy = "Lv:#{src.code_policy.level}" unless src.code_policy.level.nil?

        if !dst.nil? && !dst.code_policy.level.nil?
          t.db_dst_policy = "Lv:#{dst.code_policy.level}"
        else
          # $log.error "#{dst_id} Missing Policy"
        end

        if t.db_src_policy != t.db_dst_policy
          # $log.error " Trans #{t.db_id} #{t.db_src} -> #{t.db_dst}    #{t.db_src_policy} != #{t.db_dst_policy}"
          # TODO: check guard too
          if t.authorization_filter.nil?
            # NO AUTH
            t.inconsistent_policy = true
          else
            # TODO: check Filter command. model:action == DST
            # pp t.block.cond
            # TODO: v010 deprecated
            # rc = t.authorization.verify_call(t.block.cond, t.dst_id)
            # if rc
            #   # $log.error "SRC--PEP-->DST"
            #   t.comment = "PEP(#{t.authorization.name}) in guard"
            # else
            #   $log.error "SRC--PEP-->DST"
            #   t.comment = "PEP(#{t.authorization.name}) in guard, BUT BAD CALL"
            #   t.inconsistent_policy = true
            # end
          end
        end
      else # invalid
        t.db_src = t.src_id + '[' + t.count.to_s + ']'
        if t.invalid_type == 'loop'
          t.db_type = t.type
          t.db_dst =  '(loop)'
        else
          $log.debug "invalid trans #{t.src_id} #{t.type} #{t.invalid_type}"
          type = t.type + "(#{t.invalid_type})"
        end
        t.db_id = count
      end # if invalid
      count += 1
    end
    return $abst_transitions
  end

  def variables
    return $abst_variables
  end

  #------------------------------------------------------------------------
  # Dataflows
  #
  # Remap to new array for Dashboard table view
  #
  # 0  1           2    3        4     5        6    7            8       9
  # ID Input_state type Variable type  Variable type Output_state origin  color
  #
  # color = true if XSS(raw out)
  #
  def get_dataflows
    raw_out_count = 0
    dataflows = []

    # all
    $abst_dataflows.each do |n, df|
      id = df.index
      color = false

      # XSS fishy
      if df.type == 'raw_out'
        color = true
        raw_out_count += 1
      end

      # Table
      #  ID            'id'
      #  Input state   'IS'
      #  Input type    'IT'
      #  Variable type 'VT'
      t = {}
      t['id']     = id
      t['origin'] = df.origin
      t['color']  = color
      t['red']     = false
      t['xss_red'] = false
      # TODO: in_policy variable_policy df.out_policy
      t['IP'] = "na"
      t['VP'] = "na"
      t['OP'] = "na"

      # policy check
      @downsteram_policy_count += 1 if df.df_error
      t['red']   = df.df_error # df.is_unclear_policy
      t['title'] = df.unclear_policy_comment

      if df.type == 'in'
        t['IS']  = df.src_id
        t['IT']  = df.subtype
        t['IVT'] = df.dst_id
        t['IP']  = df.in_policy[:level].to_s       unless df.in_policy[:level].nil?
        t['VP']  = df.variable_policy[:level].to_s unless df.variable_policy[:level].nil?
        t['OP']  = ''
      elsif df.type == 'dataflow' && df.subtype == 'input'
        # v020
        # $log.error "v020  df type #{df.type} #{df.subtype}"
        t['IS']  = df.src_id
        t['IT']  = df.subtype
        t['IVT'] = df.dst_id
        t['IP']  = df.src_level
        t['VP']  = df.dst_level
        t['OP']  = ''
      elsif df.type == 'control' then
        t['IVT'] = df.src_id
        t['CT']  = df.subtype
        t['OVT'] = df.dst_id

        t['VP']  = "TBD"
      elsif  df.type == 'out'
        t['OVT'] = df.src_id
        t['OT']  = df.subtype
        t['OS']  = df.dst_id
        t['VP'] = df.variable_policy[:level].to_s unless df.variable_policy[:level].nil?
        # policy of output state
        s = $abst_states[df.dst_id]
        t['IP'] = ''
        t['OP'] = df.out_policy[:level].to_s unless  df.out_policy.nil?

        # V-O policy check
        t['xss_red']  = df.xss_trace
      else # out
        fail "unknown df type #{df.type}"
      end
      dataflows << t
    end
    $log.info "@downsteram_policy_count #{@downsteram_policy_count}"
    return dataflows, raw_out_count
  end

  # ==========================================================================
  # XSS check and gen test scenario
  # Check the View with render "form"
  # they has V1 --render-->V2(in) trans, use V1 as a start state
  def check_view_render(state_id)
    start = []
    $abst_transitions.each do |n, t|
      start << [t.src_id, t.id] if t.dst_id == state_id && t.type == 'render'
    end

    if start.size > 0
      start
    else
      []  # blank
    end
  end

  # list up all paths
  # TODO: return???
  def scan_transpath(start_state_id, end_state_id, hist, paths, depth)
    $abst_transitions.each do |n, t|
      if t.src_id == start_state_id
        if t.dst_id == end_state_id
          # HIT
          # TODO: this report 1st reached path only
          if t.trace_count == 0
            hist1 = hist.clone
            hist1 << [start_state_id, t.id]  # From
            hist1 << [end_state_id, nil]     # To (END)
            paths << hist1
          end
        else
          d2 = depth - 1
          if d2 > 0
            hist1 = hist.clone
            hist1 << [start_state_id, t.id]  # From
            scan_transpath(t.dst_id, end_state_id, hist1, paths, d2)
          else
            return false, []
          end
        end
      end
    end
    return false, []
  end

  # list of XSS dataflows
  #
  # 0             1          2      3          4       5                6
  # in_state  -> variable -> val2-> out_state  color   list_of_trans[]  warnings
  #
  # color = true if in_state was missing
  #
  def get_xss_testpaths
    $log.debug "get_xss_testpaths"
    id = 0
    xss_dataflows = []

    # step 1) Dataflow
    $abst_dataflows.each do |n1, df1|
      color = false
      if df1.type == 'raw_out'
        hit_count = 0
        # input or control
        $abst_dataflows.each do |n2, df2|
          # model direct (in->v1==v2->out)
          if df2.dst_id  == df1.src_id
            if df2.type2 == 'in'
              # input
              # lookup XSS warnings
              $log.error "HIT V-S-V #{df2.src_id} --> #{df1.dst_id}"
              wkey = $warning.get_key_of_xssout(df1.dst_id, df1.src_id)
              #                  in_state   val         val         out_state   color  trans  warnings
              xss_dataflows << [df2.src_id, df2.dst_id, df1.src_id, df1.dst_id, false, nil,   wkey]
              hit_count += 1
            elsif df2.type2 == 'control'  # TODO: internal
              # TODO: indirect (in->v1->v2->out)
              # control => input
              $abst_dataflows.each do |n3, df3|
                if df3.dst_id  == df2.src_id
                  # input
                  $log.error "HIT V-S-S-V #{df3.src_id} --> #{df1.dst_id}"
                  wkey = $warning.get_key_of_xssout(df1.dst_id, df1.src_id)
                  #                  in_state   val         val         out_state   color  trans  warnings
                  xss_dataflows << [df3.src_id, df3.dst_id, df1.src_id, df1.dst_id, false, nil,   wkey]
                  hit_count += 1
                end
              end
            end
          end
        end # df2
        if hit_count == 0
          $log.error "no input dataflow path for  #{df1.src_id} -> #{df1.dst_id}"
        end
      end # raw_out
    end # df

    # step 2) DF => Transitions (many)
    xss_testpaths = [] # Hash
    xss_dataflows.each do |df|
      if df[4] == false  # valid DF
        # Check the render "form"
        # they has V1 --render-->V2(in) trans, use V1 as a start state
        # TODO: add SID after the scan
        $log.debug "get_xss_testpaths #{df[0]} to #{df[3]}"

        # reset trace count
        $abst_transitions.each do |n, t|
          t.trace_count = 0
        end

        paths = []
        $xss_trans_search_depth = 10 if $xss_trans_search_depth.nil? # TODO: config valiable

        # Scan the transitions
        # TODO: if the home does not have submit, check parent view has the submit, then use parent as start
        # TODO: loop exist?
        scan_transpath(df[0], df[3], [], paths, $xss_trans_search_depth)

        # OK?
        if paths.size > 0
          # path exist
          # create new Hash array for the paths
          # Scan shortest path
          min_hop = $xss_trans_search_depth
          max_hop = 0
          min_hop_count = 0
          paths.each do |path|
            max_hop = path.size if path.size > max_hop
            if path.size < min_hop
              min_hop = path.size
              min_hop_count = 0
            elsif path.size == min_hop
              min_hop_count += 1
            end
          end

          # Check multiple source/parent View state of form input
          source_id = nil
          sss = check_view_render(df[0])
          if sss.size == 0
            # No source state
          elsif sss.size == 1
            # single
            source_id = sss[0]
          elsif sss.size == 2
            # multi   new and edit => select new, since new state is easy to gen a TC
            sss.each do |vs|
              source_id = vs if vs[0].include?('#new')
            end
          else
            $log.error "Too many states #{SSS}, not supported yet"
          end

          # path => xss_testpaths[id]
          count = 0
          paths.each do |path|
            id = 'XTP_' + df[0] + '_to_' + df[3] + '_' + count.to_s
            hop = path.size
            # selection is controlled by policy or manual selection
            # TODO: select test
            if hop == min_hop
              # Min
              flag = true
              $log.error "multiple min hop #{path}" if min_hop_count > 0
            else
              flag = false
            end

            # V -> Form
            path = [source_id] + path unless source_id.nil?

            # ID XTP_SRC_DST_INDEX <= Key
            # Flag #_of_hop path in_val, out_val path
            #                    t/f                            WarningKey
            xss_testpaths[id] = [flag, hop, df[1], df[2], path, df[6]]
            count += 1
          end
        else
          $log.error "no trans path for dataflow #{df[0]} => #{df[3]} by search depth #{$xss_trans_search_depth}"
        end  # path
      end  # valid DF
    end  # DF
    xss_testpaths # return
  end
end
