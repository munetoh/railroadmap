#
# Abstraction => HTML5 (table, diagrams)
#
#  JointJS
#    http://www.jointjs.com
#  Canvas2image - not used yet. may not work with JointJS?
#    http://www.nihilogic.dk/labs/canvas2image/
#
module Abstraction
  module Output 
    
    ###########################################################################
    # HTML5
    #   index.html
    #   table.html
    #   bsd.html
    #   dfd.html
    #
    class Html5
      
      def debug(msg)
        puts "#{msg}" if $debug
      end
      def error(msg)
        puts "ERROR #{msg}"
        raise "abstraction::Output::Html5 fail"
      end
      
      # Escape bad char for HTML5/JS
      def escape(id)
        id.gsub(/[#:?!]/,"_")
      end
      
      
      ##############################################
      # index.html
      #  js_type
      #    jointjs (default)
      #    else
      def html(base_dir, js_type)
        index_file = base_dir + '/index.html'
        open(index_file, "w") {|f| 
          f.write '<html>'
          f.write '<body>'
          f.write '<h2>Railroadmap</h2>'
          f.write '<h3>Summary</h3>'
          f.write "  State      : #{$abst_states.size}<br>"   
          f.write "  variables  : #{$abst_variables.size}<br>"
          f.write "  trans      : #{$abst_transitions.size}<br>"
          f.write "  dataflows  : #{$abst_dataflows.size}<br>"
          f.write '<h3>Global Security Properties</h3>'
          f.write "  protect_from_forgery : #{$protect_from_forgery}<br>"
          f.write "  authentication_method : #{$authentication_method}<br>"
          
          f.write '<h3>Details</h3>'
          f.write '<a href="table.html">Table</a><br>'
          f.write '<a href="bsd.html">Behavior state diagram</a><br>'
          f.write '<a href="dfd.html">Data flow diagram</a><br>'
          f.write '</body>'
          f.write '</html>'
        }
        
        html_table(base_dir + '/table.html')
        html5_jointjs_bsd(base_dir)
        html5_jointjs_dfd(base_dir)      
      end
      
      def to_ruby(sexp)
        begin
          Sorcerer.source(sexp) 
        rescue => e
          p e
          'UNKNOWN'
        end
      end
    
      ###########################################################################
      # HTML Table  table.html
      #   States
      #   Variables
      #   Transitions
      #   Dataflows
      #
      def html_table(filename)
        open(filename, "w") {|f|
          f.write '<html><head><meta http-equiv="content-type" content="text/html;charset=utf-8"><title>Railroadmap:TableView</title></head>'
          f.write '<body>'
          f.write '<style type="text/css">'
          f.write 'table.t {border:1px solid #000000; border-collapse:collapse;}'
          f.write 'table.t td{border:1px solid #000000;font-size:x-small;text-align:left;word-break:break-all;}'
          f.write 'table.t th{border:1px solid #000000;font-size:small;text-align:left;}'
          f.write 'table.t th{background-color:#00008b;color:#ffffff;}'
          #f.write 'table.t tr:nth-child(odd)  td{background-color:#f0fff0;color:#000000;}'
          #f.write 'table.t tr:nth-child(even) td{background-color:#e0ffff;color:#000000;}'
          f.write '</style>'
  
          #######################################################################
          # States
          f.write '<h3>State</h3>'
          f.write '<table class="t" style="text-align:center;">'
          f.write '<thead><tr>'
          f.write '<th>A</th><th>S</th><th>s</th><th>p</th><th>P</th>'
          f.write '<th style="width:5em">Type</th><th style="width:2em">Domain</th><th style="width:5em">Class</th>'
          #f.write '<th style="width:5em">Source code</th>'
          f.write '</tr></thead>'
  
          f.write '<tbody>'
          # #{@type.ljust(12)} #{flag} #{@domain.ljust(40)}  #{@controller_class} < #{@base_controller_class} #{filename}"
          $abst_states.each do |n,s|
            case s.type
            when 'controller'
              bgcolor = '#ff7070'
            else
              bgcolor = '#d0d0d0'
            end
            if s.is_authenticated then aFlag = 'A'; bgcolor = '#70ff70';
            else                       aFlag = '-'  
            end
                        
            if s.ssl_required then srFlag = 'S'; bgcolor = '#a0ffa0';
            else                   srFlag = '-'  
            end
      
            if s.ssl_allowed then saFlag = 's'
            else                  saFlag = '-'  
            end      
                
            if s.is_private   then pFlag = 'p'; bgcolor = '#707070';
            else                   pFlag = '-'
            end      
            
            if s.is_protected then ptFlag = 'P'; bgcolor = '#707070';
            else                   ptFlag = '-'
            end
  
            f.write "<tr bgcolor=\"#{bgcolor}\">"         
            f.write "<td>#{aFlag}</td> <td>#{srFlag}</td> <td>#{saFlag}</td> <td>#{pFlag}</td> <td>#{ptFlag}</td>"
            f.write "<td>#{s.type}</td> <td>#{s.domain}</td> <td>#{s.controller_class}</td>"
            #f.write "<td>#{s.filename}</td>"
            f.write '</tr>'
          end        
          f.write '</tbody>'
          f.write '</table>'
  
          #######################################################################
          # Variables
          f.write '<h3>Variables</h3>'
          f.write '<table class="t" style="text-align:center;">'
          f.write '<tbody>'
          f.write '<thead><tr>'
          f.write '<th>MA</th>'
          f.write '<th style="width:5em">Type</th><th style="width:2em">Domain</th><th>abstraction</th>'
          #f.write '<th style="width:5em">Source code</th>'
          f.write '</tr></thead>'        
          $abst_variables.each do |n,v|
            # #{@type.ljust(12)} #{flag} #{@domain.ljust(40)}  #{filename}"
            case v.type
              when 'model'
                bgcolor = '#ff7070';
              else
                bgcolor = '#d0d0d0';
            end       
            if v.attr_accessible then flag = '-'; 
            else                      flag = 'P'; bgcolor = '#707070';
            end
            
            map = $abstmap_variable[v.domain] 
            
            f.write "<tr bgcolor=\"#{bgcolor}\">"
            f.write "<td>#{flag}</td>"
            f.write "<td>#{v.type}</td> <td>#{v.domain}</td> "
            if map == nil
              f.write "<td></td>"
            else
              f.write "<td>#{map[0]} #{map[1]}</td>"
            end
            f.write '</tr>'
          end
          f.write '</tbody>'
          f.write '</table>'
          
          ###########################################################
          # abstraction
          ###########################################################
          f.write '<h3>abstractions (guard)</h3>'
          
          if $abstmap_guard.size == 0 then
            f.write 'no abstraction map for the guard condition'
          else
            # Show
            f.write '<table class="t" style="text-align:center;">'
            f.write '<tbody>'
            f.write '<thead><tr>'
            f.write '<th style="width:5em">Ruby code</th>'
            f.write '<th style="width:5em">abstracted code</th>'
            f.write '</tr></thead>'
 
            $abstmap_guard.each do |r,a|
              bgcolor       = '#ffffff'
              
              f.write "<tr bgcolor=\"#{bgcolor}\">"
              f.write "<td>#{r}</td>"
              f.write "<td>#{a}</td>"
              f.write '</tr>'
            end
            f.write '</tbody>'
            f.write '</table>'
          end
          
          f.write '<h3>abstractions (action)</h3>'
          if $abstmap_action.size == 0 then
            f.write 'no abstraction map for the action'
          else
            # Show
            f.write '<table class="t" style="text-align:center;">'
            f.write '<tbody>'
            f.write '<thead><tr>'
            f.write '<th style="width:5em">Block location</th>'
            f.write '<th style="width:5em">abstracted code</th>'
            f.write '</tr></thead>'
 
            $abstmap_action.each do |blk,a|
              bgcolor       = '#ffffff'
              
              f.write "<tr bgcolor=\"#{bgcolor}\">"
              f.write "<td>#{blk}</td>"
              f.write "<td>#{a}</td>"
              f.write '</tr>'
            end
            f.write '</tbody>'
            f.write '</table>'
          end
          
          
          ###########################################################
          # TRANSITION
          ###########################################################
          f.write '<h3>Transitions (abstracted)</h3>'
          f.write '<table class="t" style="text-align:center;">'
          f.write '<tbody>'
          f.write '<thead><tr>'
          f.write '<th>id</th>'
          f.write '<th style="width:5em">Src</th><th style="width:5em">Dst</th>'
          f.write '<th style="width:5em">Type</th><th>Guard(abst)</th><th>Action(abst)</th>'
          f.write '</tr></thead>'
          
          count = 0
          invalid = 0
          $abst_transitions.each do |n,t|
            if t.invalid == false then
              bgcolor       = '#ffffff'
              tr_bgcolor    = '#ffffff'
              
              src_label = t.src_id + '[' + t.count.to_s + ']'
              
              src = $abst_states[t.src_id]
              
              # Type
              type = t.type
              #  select tr color
              if t.type == 'link_to' then
                type = "link_to(#{t.title})"
                tr_bgcolor    = '#70ff70'
              elsif t.type == 'submit' then
                type = "submit(#{t.title}, #{t.variables})"  # TODO title is nil 2012/4/24, TODO put variables too 
                tr_bgcolor    = '#ff7070' # RED
              elsif t.type == 'redirect_to' then
                tr_bgcolor    = '#ff7070' # RED
              elsif t.type == 'render' then
                tr_bgcolor    = '#d0d0d0' # gray
              elsif t.type == 'render_def2' then
                tr_bgcolor    = '#d0d0d0'
              elsif t.type == 'render_with_scope' then
                tr_bgcolor    = '#d0d0d0'
              elsif t.type == 'render_def3' then
                tr_bgcolor    = '#d0d0d0'
              else
                # TODO
              end
              if t.invalid 
                tr_bgcolor    = '#d0d000' # YELLOW
                type = type + ' (INVALID)'
              end
              guard_bgcolor = tr_bgcolor
              dst_bgcolor   = tr_bgcolor
              
              # Condition
              guard = t.block.abst_condition_success if t.block != nil
              #guard_abst = t.block.abst_condition_success if t.block != nil
              #p guard
              if guard == nil then
                case src.type
                when 'controller'
                  guard = "true"
                when 'view'
                  guard = "selected by user"
                else
                  guard = "[block id=#{t.block.id}]"
                  guard_bgcolor = '#ffff00'
                end
              else
                if src.type == 'view'
                  guard = guard + " and selected by user"
                end
              end
    
              # TODO action
              # p t.block.id
              action = $abstmap_action[t.block.id]
              if action == nil then
                action = '(@' + t.block.id + ')'
              else
                action = action + '<br>(@' + t.block.id + ')'
              end
              
              
              
        
              if t.dst_id != nil then  
                # Ok
                dst_id = t.dst_id + '<br>(' + to_ruby(t.dst_hint) + ')'
                #dst_bgcolor = '#ffffff'
              else
                # Still unknown
                dst_id = to_ruby(t.dst_hint)
                dst_bgcolor = '#ffff00'
              end
              # #{type.ljust(30)} #{src.ljust(33)} -> #{@dst_id.ljust(30)} #{guard.ljust(40)} #{filename}"
              f.write "<tr bgcolor=\"#{tr_bgcolor}\">"
              f.write "<td style=\"word-break:normal;text-align:right;\">#{count}</td>"
              f.write "<td>#{src_label}</td>"
              f.write "<td bgcolor=\"#{dst_bgcolor}\">#{dst_id}</td>"
              f.write "<td>#{type}</td>"
              f.write "<td bgcolor=\"#{guard_bgcolor}\">#{guard}</td>"
              #f.write "<td bgcolor=\"#{guard_bgcolor}\">#{guard_abst}</td>"
              f.write "<td>#{action}</td>"
              f.write "</tr>\n"
              
              count = count + 1
            else
              invalid = invalid + 1
            end  # if
          end # DO
          
          f.write '</tbody>'
          f.write '</table>'
          f.write "#{invalid} invalid trans. check the tool."
  
          ###########################################################
          f.write '<h3>Dataflow</h3>'
          f.write '<table class="t" style="text-align:center;">'
          f.write '<tbody>'
          f.write '<thead><tr>'
          f.write '<th>Inbound</th><th>Type</th><th>Variables</th><th>Type</th><th>Outbound</th>'
          f.write '</tr></thead>'
          $abst_dataflows.each do |n,d|
            bgcolor = '#ffffff'
            
            src_id = d.src_id || 'TBD'
            dst_id = d.dst_id || 'TBD'
            #filename = ''
            #filename = @filename if $verbose > 2
          
            
            if d.type2 == 'out' then
              # C -> V
              td1 = ''
              td2 = ''
              td3 = src_id
              td4 = d.type
              td5 = dst_id
              vname = src_id
            elsif d.type2 == 'in' then
              # V ->C 
              td1 = src_id
              td2 = d.type
              td3 = dst_id
              td4 = ''
              td5 = ''
              vname = dst_id
            elsif d.type2 == 'control' then
              td1 = ''
              td2 = ''
              td3 = src_id
              td4 = d.type
              td5 = dst_id
              vname = src_id
            end
            
            # color
            v = $abst_variables[vname]
            if v != nil then
              if v.type == 'model' 
                if v.attr_accessible
                  mcolor = '#ff7070' # RED
                else
                  mcolor = '#70ff70' # Green
                end
              else
                mcolor = '#d0d0d0' # gray
              end
            else
              $log.info "DFD model #{vname} is missing?"
            end
        
            f.write "<tr bgcolor=\"#{mcolor}\">"          
            f.write "<td>#{td1}</td> <td>#{td2}</td>"
            f.write "<td>#{td3}</td>"
            f.write "<td>#{td4}</td><td>#{td5}</td>"
            f.write '</tr>'
          end
          f.write '</tbody>'
          f.write '</table>'
                  
          f.write ''
          f.write '</body></html>'
          
        }
      end
      
      ###########################################################################
      # JavaScript (or JSON)
      ###########################################################################
      
      #
      # Alignemnt parametors
      #
      
      
      #
      # State alignment - Y
      #
      def init_y_location()
        # Y location/alignment
        @y_locations = Hash.new  # hold controller's Y location
        @y_model_locations = Hash.new
        @y_last_model = ''
        @y_layout = 500
      end
      
      def set_y_location(label, y)      
        dy = 75
  
        l = label.split('#')
        if @y_last_model != l[0] then
          @y_last_model = l[0]
          dy = 150
        end
                
        @y_locations[label] = y + dy
        @y_model_locations[l[0]] =  y + dy
        
        return (y + dy)
      end
      
      def get_y_location(label)
        y = @y_locations[label]
        l = label.split('#')
              
        # layout -> top
        if l[0] == 'layout' then
          #puts "layout => top" 
          y = @y_layout
          @y_layout = @y_layout + 50
          return y  # center?
        end
              
        if y == nil then
          
          y = @y_model_locations[l[0]]
          if y == nil then        
            y = -1
          end
        end
          
        return y
      end
      
      
      ###########################################################################
      # Behavior State Diagram
      #      
      def html5_jointjs_bsd(basedir)
        
        canvas_width = 1100
               
        # JavaScript
        #  - put controller in the centor col
        # 
        #
        #
        open(basedir + '/bsd.js', "w") {|f|
          
          
          # 1. Prepare X alignment 
          #  Check all Transition for col position
          #
          #  - 5 col  V -> V -> C -> C -> V
          #           ---------------------
          #           V -> V
          #           V ------> C
          #                V -> C
          #                     C -> C
          #                     C ------> V
          #                          C -> V 
          #           ---------------------
          #
          # note) $abst_states is set by 
          $abst_transitions.each do |n,t|
            src = $abst_states[t.src_id]
            dst = $abst_states[t.dst_id]
            if src != nil and dst != nil then
              tt = src.type + '_' + dst.type
              case tt
              when 'view_view'
                debug "V->V #{t.dst_id}"
                src.is_VV_src = true
                dst.is_VV_dst = true
              when 'controller_controller'
                debug "C->C #{t.dst_id}"
                src.is_CC_src = true
                dst.is_CC_dst = true
              else
                #puts tt          
              end
            else
              #puts "SKIP #{t.src_id}  to #{t.dst_id}"
            end
          end
          
           
          init_y_location()
          
          
          # 2. Place controller states
          states = ''        
          all = []
          x = canvas_width/2 - 100
          cy = -50
          $abst_states.each do |n,s|
            bgcolor = 'red'
            domain = s.domain.split('#')
            case s.type
            when 'controller'            
              #if s.is_private or s.is_protected then
                # SKIP
                #puts "SKIP protected"
              #else
                # Place
                #puts "JS"
                bgcolor = 'grey' if s.is_private # Green
                bgcolor = 'grey' if s.is_protected # Green
                
                bgcolor = 'green' if s.is_authenticated # Green
                bgcolor = 'green' if s.ssl_required
                id = escape(s.id)
                
                if s.is_CC_dst then x2 = x + 200
                else                x2 = x
                end
                
                cy = set_y_location(s.domain, cy)
                #y = y + dy
                
                #label = s.type + '\n' + s.domain
                label = s.domain
                width = label.size * 4.5 + 40
                states << "var #{id} = uml.State.create({"
                states << "rect: {x: #{x2}, y: #{cy}, width: #{width}, height: 50},"
                states << "label: \"#{label}\","
                states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
                states << "shadow: true,"
                states << "}).toggleGhosting();"
                states << "\n"
                #states << "console.log(\"SM DEBUG #{x} #{y}\");\n"
                
                              
                all << id
              #end
            #when 'view'
            #  puts "SKIP #{s.type}"
            #else
            #  puts "SKIP #{s.type}"
            end
          end
          
          # State: View
          vstates = ''
          bgcolor = 'yellow'
          vxi = 50
          
          vy2  = 100
          $abst_states.each do |n,s|
            case s.type
            when 'view'            
              #label = s.type + '\n' + s.domain
              label = s.domain
              width = label.size * 4.5 + 40
              vxo = canvas_width - 10 - width
              
              vy = get_y_location(label)
              if vy < 0 then
                debug "missing y #{label}"     
              else
                debug "align #{label}"
                vy2 = vy 
              end
              
              
              l = label.split('#')
              # _form => inbound only
              ib_skip = false
              ob_skip = false
              if l[1] == '_form' then
                ob_skip = true
              end
              
              xoffset = 0
              if l[0] == 'layout' then
                ob_skip = true
                xoffset = - 30
                if ($bsd_display_layout == false)
                  ib_skip = true
                  debug "SKIP layout inb"
                end
                debug "SKIP layout"
              end
              
              
              
              # Place Inbound
              if ib_skip == false then
                id = escape(s.id) + '_inbound'
                
                if s.is_VV_dst then x2 = vxi + xoffset + 100
                else                x2 = vxi + xoffset
                end
                                
                states << "var #{id} = uml.State.create({"
                states << "rect: {x: #{x2}, y: #{vy2}, width: #{width}, height: 50},"
                states << "label: \"#{label}\","
                states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
                states << "shadow: true,"
                states << "}).toggleGhosting();"
                states << "\n"
                all << id
              end
              # Place Outbound
              if ob_skip == false then
                id = escape(s.id) + '_outbound'
                states << "var #{id} = uml.State.create({"
                states << "rect: {x: #{vxo}, y: #{vy2}, width: #{width}, height: 50},"
                states << "label: \"#{label}\","
                states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
                states << "shadow: true,"
                states << "}).toggleGhosting();"
                states << "\n"
                all << id
              end
              
              
              #states << "console.log(\"SM DEBUG #{x} #{y}\");\n"
              vy = vy + 75
            end
          end
          
          all2 = all.to_s.gsub(/"/,'')
          states << "var all = #{all2}\n"
          
          #######################################################################
          # Post: put Transitions
          tcount = 0
          $abst_transitions.each do |n,t|
            src = $abst_states[t.src_id]
            dst = $abst_states[t.dst_id]
            if src != nil and dst != nil and t.invalid == false then
              skip = false
              line_color = nil
              domain = src.domain.split('#')
              if (domain[0] == 'layout') then
                if ($bsd_display_layout == false) and (domain[0] == 'layout')
                  $log.info "HTML-BSD SKIP transition form layout"
                  skip = true
                else
                  line_color = 'green'
                end
              end
              
              if skip == false then                          
                tid = "t#{tcount}"
                
                src_id = escape(src.id)
                dst_id = escape(dst.id)
                
                tt = src.type + '_' + dst.type  # SRC/DST            
                case tt
                when 'view_view'
                  src_id = src_id + '_inbound'
                  dst_id = dst_id + '_inbound'
                  states << "var #{tid} = #{src_id}.joint(#{dst_id}, uml.arrow).register(all);\n"
                when 'view_controller'
                  src_id = src_id + '_inbound'
                  #dst_id = dst.id
                  states << "var #{tid} = #{src_id}.joint(#{dst_id}, uml.arrow).register(all);\n"
                when 'controller_view'
                  #src_id = src.id
                  dst_id = dst_id + '_outbound'
                  states << "var #{tid} = #{src_id}.joint(#{dst_id}, uml.arrow).register(all);\n"
                when 'controller_controller'
                  #src_id = src.id
                  #dst_id = dst.id
                  states << "var #{tid} = #{src_id}.joint(#{dst_id}, uml.arrow).register(all);\n"
                else
                  error "html5_jointjs_bsd, unknown SRC/DST pair, #{tt}"
                end
                
                # Transtion name
                # link_to(text)
                if (t.type == 'link_to') and (t.title != nil) and (t.title.class == String)
                  #puts "SM DEBUG link_to title  #{t.title} #{t.title.class}"
                  #title = 'TBD'
                  type = t.type + '(' + t.title + ')'
                elsif  (t.type == 'submit')
                  # TODO list
                  list = t.variables.to_s.gsub('"','')
                  type = 'submit(' + list + ')'
                else
                  type = t.type
                end 
                
                # puts t.guard
                guard = t.block.abst_condition_success if t.block != nil
                # TODO
                if guard == '(true)' then
                  # remove true
                  guard = nil
                elsif guard =~ /not \(([a-z_.]+)\s*==\s*true\)/ then
                  # not (A==true)  => A==false
                  # TODO 
                  guard = $1 + '==false'
                end
                if guard =~ /\(true\) and \(([a-z_.]+)==([a-z_.]+)\)/ then
                  guard = $1 + '==' + $2
                end
                
                
                # puts t.action
                # TODO
                
                # set label
                if guard != nil then
                  states << "#{tid}.label(\"#{type}\\n[#{guard}]\");\n"
                else
                  states << "#{tid}.label(\"#{type}\");\n"
                end
                
                
                
                # POST -> RED
                if t.type == 'submit' then
                  states << "#{tid}.highlight(\"green\").unhighlight().highlight(\"red\");\n"
                end
                
                if line_color != nil then
                  states << "#{tid}.unhighlight().highlight(\"#{line_color}\");\n"
                end
                
                # OK
                
                tcount = tcount + 1
              end  # SKIP
            else
              $log.info "HTML-BSD SKIP trans from #{t.src_id} to #{t.dst_id}"
            end
          end
          
          
          #######################################################################
          # Round up
          width = canvas_width
          height = cy + 100
          f.write "title('Railroadmap');"
          f.write "description('Bahevior State Diagram');"
          f.write "dimension(#{width}, #{height});"
          f.write "var uml = Joint.dia.uml;"
          f.write "var paper = Joint.paper(\"world\", #{width}, #{height});"
          f.write "\n"
          #f.write "console.log(\"SM DEBUG\");\n"
          f.write states
         
          #p all
        }
  
  
        # HTML
        open(basedir + '/bsd.html', "w") {|f|
          f.write <<-EOF
<!DOCTYPE html>
<html>
<head>
<meta http-equiv='cache-control' content='no-cache'>
<meta http-equiv='expires' content='0'>
<meta http-equiv='pragma' content='no-cache'>
<script src="http://www.jointjs.com/lib/json2.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/lib/raphael.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.arrows.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.serializer.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.fsa.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.uml.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.pn.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.devs.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.cdm.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.erd.js" type="text/javascript"></script>
<script src="http://www.jointjs.com/src/joint.dia.org.js" type="text/javascript"></script>
<title>Railroadmap: abstracted Behavior State Diagram</title>
<style type="text/css">
body {background-color: white}
#world       {background-color: white;width: 1000px;height: 1000px;border: 3px solid gray;border-radius: 30px;}
#title       {position: fixed;left: 50px;top: 10px;color: black;font-size: 14px;width: 300px}
#description {position: fixed;left: 60px;top: 25px;color: black;font-size: 12px;width: 300px}
#source      {position: fixed;left: 60px;top: 50px;color: black;font-size: 12px;width: 300px}
</style>
<script type="text/javascript">
function gup(name){
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(window.location.href);
  if (results == null)
    return "";
  else
    return results[1];
}
function init(){
  var sel = document.createElement("script");
  sel.type = "text/javascript";
  sel.src = "bsd.js?" + new Date;
  document.getElementById("source").href = "bsd.js";
  document.getElementsByTagName("head").item(0).appendChild(sel);
}    
function title(s) {document.getElementById('title').innerHTML = s;}
function description(s) {document.getElementById('description').innerHTML = s;}
function dimension(w, h) {
  var world = document.getElementById('world');
  world.style.width = w + 'px';
  world.style.height = h + 'px';
}
</script>
</head>
<body onload="init()">
<div id="headcontainer" style="display:block;">
<h1 id="title"></h1>
<p id="description"></p>
<a id="source" href="">(source)</a>
</div> 
<div id="world"></div>
</body></html>
EOF
        }
      end




      ###########################################################################
      # Data flow Diagram
      ###########################################################################
      #
      #   In  -----> Data -------> Out 
      #
      #
      #
      def html5_jointjs_dfd(basedir)
        
        canvas_width = 1000
        
        open(basedir + '/dfd.js', "w") {|f|
          
          #
          states = ''
          joints = '' 
          all = []
          x = canvas_width/2 - 50
          cy = 0
          
          # 0 pre
          # check busy variable to give some v space
          #
          
          # 1a. non-protected Valiables (center)          
          $abst_variables.each do |n,v|
            skip = false
            bgcolor = 'red'
            #domain = v.domain.split('#')
            case v.type
            when 'model'            
              if v.attr_accessible then
                # update by POST
                # Red                
              else
                # MA protected
                #puts "JS"
                bgcolor = 'green'   
                skip = true          
              end
            end
            
            if skip == false then
              cy = set_y_location(v.domain, cy)
              id = escape(v.id)
              
              #label = s.type + '\n' + s.domain
              label = v.domain
              width = label.size * 4.5 + 40
              states << "var #{id} = uml.State.create({"
              states << "rect: {x: #{x}, y: #{cy}, width: #{width}, height: 50},"
              states << "label: \"#{label}\","
              states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
              states << "shadow: true,"
              states << "}).toggleGhosting();"
              states << "\n"
              #states << "console.log(\"SM DEBUG #{x} #{y}\");\n"
              all << id
            end  
          end
          
          # 1b. protected Valiables (center)
          cy = cy + 50
          $abst_variables.each do |n,v|
            skip = true
            bgcolor = 'red'
            #domain = v.domain.split('#')
            case v.type
            when 'model'            
              if v.attr_accessible then
                # update by POST
                # Red
                
              else
                # MA protected
                #puts "JS"
                bgcolor = 'green'  
                skip = false           
              end
            end
            
            if skip == false then
              cy = set_y_location(v.domain, cy)
              id = escape(v.id)
              
              #label = s.type + '\n' + s.domain
              label = v.domain
              width = label.size * 4.5 + 40
              states << "var #{id} = uml.State.create({"
              states << "rect: {x: #{x}, y: #{cy}, width: #{width}, height: 50},"
              states << "label: \"#{label}\","
              states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
              states << "shadow: true,"
              states << "}).toggleGhosting();"
              states << "\n"
              #states << "console.log(\"SM DEBUG #{x} #{y}\");\n"
              all << id
            end  
          end
          
                    
          
          # 2. Dataflow Inbound and Outbound
          dfcount = 0
          dfids = Hash.new
          $abst_dataflows.each do |n,d|
            bgcolor = 'yellow'
            
            if d.src_id != nil and d.dst_id != nil then
              
              skip_state = false
              skip_joint = false
              
              if d.type2 == 'out' then
                # Variable -> State(View)
                x = canvas_width - 150
                # src
                src = $abst_variables[d.src_id]
                src_id = escape(d.src_id)
                y = get_y_location(src.domain)
                # dst                
                dst = $abst_states[d.dst_id]
                dst_id = escape(d.dst_id) + '_outbound'
                label = dst.domain
                #
                id = dst_id
                if dfids[id] == nil then
                  dfids[id] = true
                else
                  # duplicate
                  skip_state = true
                end
                
              elsif d.type2 == 'in' then
                # State (View) -> Variable
                x = 50
                # src
                src = $abst_states[d.src_id]
                src_id = escape(d.src_id) + '_inbound'
                label = src.domain
                # dst
                dst = $abst_variables[d.dst_id]
                dst_id = escape(d.dst_id)
                y = get_y_location(dst.domain)
                #
                id = src_id
                if dfids[id] == nil then
                  dfids[id] = true
                else
                  # duplicate
                  skip_state = true
                end
              elsif d.type2 == 'control' then
                x = canvas_width - 150
                src = $abst_variables[d.src_id]
                y = get_y_location(src.domain)
                id = escape(d.dst_id)
                # TODO
                skip_state = true
                skip_joint = true
              else
                skip_state = true
                skip_joint = true
                debug "html5_jointjs_dfd unknown dataflow type, #{d.type2}"
                raise "html5_jointjs_dfd unknown dataflow type, #{d.type2}" if $robust              
              end

              if skip_state == false then        
                width = label.size * 4.5 + 40
                states << "var #{id} = uml.State.create({"
                states << "rect: {x: #{x}, y: #{y}, width: #{width}, height: 50},"
                states << "label: \"#{label}\","
                states << "attrs: {fill: \"90-#000-#{bgcolor}:1-#fff\"},"
                states << "shadow: true,"
                states << "}).toggleGhosting();"
                states << "\n"
                #states << "console.log(\"SM DEBUG #{x} #{y}\");\n"
                all << id  
              end
              
              if skip_joint == false then
                dfid = "d#{dfcount}"
                joints << "var #{dfid} = #{src_id}.joint(#{dst_id}, uml.arrow).register(all);\n"
                joints << "#{dfid}.label(\"#{d.type}\");\n"
                dfcount = dfcount + 1
              end
            else
              debug "html5_jointjs_dfd  src=#{d.src_id} or dst=#{d.dst_id} is NIL"
            end
                        
          end

          # ALL  
          all2 = all.to_s.gsub(/"/,'')
          states << "var all = #{all2}\n"
          
          
          #######################################################################
          # Round up
          width = canvas_width
          height = cy + 100
          f.write "title('Railroadmap');\n"
          f.write "description('Data Flow Diagram');\n"
          f.write "dimension(#{width}, #{height});\n"
          f.write "var uml = Joint.dia.uml;\n"
          f.write "var paper = Joint.paper(\"world\", #{width}, #{height});\n"
          f.write "\n"
          #f.write "console.log(\"SM DEBUG\");\n"
          f.write states
          f.write joints
        }  # open
          
          
          
        # HTML
        open(basedir + '/dfd.html', "w") {|f|
          f.write <<-EOF
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv='cache-control' content='no-cache'>
        <meta http-equiv='expires' content='0'>
        <meta http-equiv='pragma' content='no-cache'>

        <script src="http://www.jointjs.com/lib/json2.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/lib/raphael.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.arrows.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.serializer.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.fsa.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.uml.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.pn.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.devs.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.cdm.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.erd.js" type="text/javascript"></script>
        <script src="http://www.jointjs.com/src/joint.dia.org.js" type="text/javascript"></script>
        <title>Railroadmap: Data Flow Diagram</title>
        <style type="text/css">
          body {
            background-color: white
          }
#world       {background-color: white;width: 1000px;height: 1000px;border: 3px solid gray;border-radius: 30px;}
#title       {position: fixed;left: 50px;top: 10px;color: black;font-size: 14px;width: 300px}
#description {position: fixed;left: 60px;top: 25px;color: black;font-size: 12px;width: 300px}
#source      {position: fixed;left: 60px;top: 50px;color: black;font-size: 12px;width: 300px}

        </style>
        <script type="text/javascript">
            function gup(name){
              name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
              var regexS = "[\\?&]" + name + "=([^&#]*)";
              var regex = new RegExp(regexS);
              var results = regex.exec(window.location.href);
              if (results == null)
                return "";
              else
                return results[1];
            }
            function init(){
              var sel = document.createElement("script");
              sel.type = "text/javascript";
              sel.src = "dfd.js?" + new Date;
                document.getElementById("source").href = "dfd.js";
                document.getElementsByTagName("head").item(0).appendChild(sel);
            }
            function title(s) {
              document.getElementById('title').innerHTML = s;
            }
            function description(s) {
              document.getElementById('description').innerHTML = s;
            }
            function dimension(w, h) {
              var world = document.getElementById('world');
              world.style.width = w + 'px';
              world.style.height = h + 'px';
            }
        </script>
    </head>
    <body onload="init()">
    <div id="world"></div>
    <h1 id="title"></h1>
    <p id="description"></p>
    <a id="source" href="">(source)</a>
    </body></html>
EOF

        }
      end  
               
    end  # class Html5
  end
end