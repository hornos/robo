
module Robo
  def Robo.stop(c=nil,e=1)
    c[:browser].close if not c.nil?
    puts "STOP"
    exit(e)
  end

  def Robo.start(c)
    # puts c[:driver]
    c[:browser] = Watir::Browser.new c[:driver][:browser]
    # c[:driver][:options].each do |b|
    #   c[:browser].send(b.to_sym)
    # end
  end

  def Robo.list(c,a=nil)
    case
    when a[0].nil?
      puts "actions:"
      c[:actions].each do |action,opts|
        puts action.to_s
      end if not c[:actions].empty?
    when c.has_key?(a[0].to_sym)
      puts "#{a[0].to_s}:"
      c[a[0].to_sym].each do |action,opts|
        puts "#{action.to_s} - #{opts[:info]}"
        puts "  #{opts[:actions]}"
        # puts action.to_s
      end if not c[a[0].to_sym].empty?
    end
  end

  def Robo.jsproper(c)
    c[:browser].execute_script("window.alert = function() {}")
    # c[:browser].execute_script("window.prompt = function() {return 'jsproper'}")
    c[:browser].execute_script("window.prompt = function() {return null}")
    c[:browser].execute_script("window.confirm = function() {return true}")
    c[:browser].execute_script("window.confirm = function() {return false}")
    c[:browser].execute_script("window.onbeforeunload = null")
  end

  def Robo.actions(c)
    return if c[:actions].empty?
    return if c[:args].empty?

    # c[:actions].keep_if do |action|
    #   c[:args].include? action.to_s
    # end if not c[:args].empty?

    br = c[:browser]
    actions = c[:args].dup

    if c[:args].shift == "task"
      task = c[:args].shift || 'default'
      actions = c[:tasks][task.to_sym][:actions] if c[:tasks][task.to_sym].has_key?(:actions)
    end

#    c[:actions].each do |action,opts|
#    puts c[:actions].keys
#    c[:args].each do |act|
    actions.each do |act|
      begin
        action = act.to_sym
        if not c[:actions].has_key?(action) then
          puts "action not found #{act}"
          next
        end
        opts = c[:actions][action]
        Robo::stop(c) if action.to_s == "stop"
        binding.pry if action.to_s == "pry"
      rescue Exception => ex
        STDERR.puts ex.backtrace
        binding.pry
      end
      # open a new window
      # if opts.has_key?(:new)

      # switch to window with the title
      if opts.has_key?(:use)
        win=br.windows.find{|w| w.title =~ /#{opts[:use]}/}
        win.use
        puts "#{action} use #{win.inspect}"
      end

      # navigate to this url
      if opts.has_key?(:goto)
        br.goto opts[:goto]
        puts "#{action} goto #{opts[:goto]}"
      end

      # main page timeout
      opts[:timeout].each do |xpath,opts|
        puts "#{action} wait #{xpath}"
        begin
          br.wait_until{br.element(:xpath,xpath.to_s).exists?}
        rescue Exception => ex
          STDERR.puts ex.inspect
          pry
        end
      end if opts.has_key?(:timeout)

      # same by assert
      opts[:assert].each do |xpath,opts|
        puts "#{action} assert #{xpath}"
        assert(br.element(:xpath,xpath.to_s).exists?)
      end if opts.has_key?(:assert)

      # xpath data
      opts[:xpath].each do |xpath,cmds|
        elem = br.element(:xpath=>xpath.to_s).to_subtype
        puts "#{action} type => #{elem.inspect}"

        cmds.each do |cmd,val|
          puts "#{action} #{cmd} => #{val}"
          begin
            case
            when cmd.to_s == "flash"
              val.times {elem.flash}
            when cmd.to_s == "wait"
              br.wait_until{br.element(:xpath,xpath.to_s).exists?}
            else
              elem.when_present.send cmd,val
            end
          rescue Exception => ex
            STDERR.puts ex
            binding.pry
          end
        end
      end if opts.has_key?(:xpath)

      # element data
      opts[:elem].each do |elem,cmds|
        path = cmds.shift
        cmd  = cmds.shift
        puts "#{action} #{elem} => #{path} => #{cmd}"
        try = 0
        begin
          try += 1
          _elem = br.send elem,path[0],/#{path[1]}/
          puts _elem.inspect
          _cmd,_val = cmd
          _elem.when_present(3).send _cmd,_val
        rescue Exception => ex
          retry if try < 3
          STDERR.puts ex.inspect
          binding.pry
        end
      end if opts.has_key?(:elem)

      # last entry
      br.windows.find{|w| w.title =~ /#{opts[:close]}/}.close if opts.has_key?(:close)
    end
  end
end
