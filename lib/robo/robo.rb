
module Robo
  def Robo.stop(c=nil,e=1)
    c[:browser].close if not c.nil?
    puts "STOP"
    exit
  end

  def Robo.start(c)
    if not c[:driver][:proxy].nil?
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.proxy = Selenium::WebDriver::Proxy.new :http => c[:driver][:proxy], :ssl => c[:driver][:proxy]
      c[:browser] = Watir::Browser.new c[:driver][:browser],:profile=>profile
    else
      c[:browser] = Watir::Browser.new c[:driver][:browser]
    end
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
      end if not c[a[0].to_sym].empty?
    end
  end

  def Robo.jsproper(c)
    c[:browser].execute_script("window.alert = function() {}")
    c[:browser].execute_script("window.prompt = function() {return null}")
    c[:browser].execute_script("window.confirm = function() {return true}")
    c[:browser].execute_script("window.confirm = function() {return false}")
    c[:browser].execute_script("window.onbeforeunload = null")
  end

  def Robo.actions(c)
    return if c[:actions].empty?
    return if c[:args].empty?

    br = c[:browser]
    actions = c[:args].dup

    if c[:args].shift == "task"
      task = c[:args].shift || 'default'
      actions = c[:tasks][task.to_sym][:actions]
    end

    actions.each do |act|
      action = act.to_sym
      opts = c[:actions][action]
      case action.to_s
      when "stop"
        Robo::stop(c)

      when "pry"
        binding.pry

      when "wait"
        puts "#{action} #{opts}"
        sleep(opts)
        next
      end

      # window switch
      if opts.has_key?(:use)
        win = br.windows.find{ |w| w.title =~ /#{opts[:use]}/ }
        win.use
        puts "#{action} use #{win.inspect}"
      end

      # url goto
      if opts.has_key?(:goto)
        br.goto opts[:goto]
        puts "#{action} goto #{opts[:goto]}"
      end

      # page timeout
      opts[:timeout].each do |xpath,opts|
        puts "#{action} wait #{xpath}"
        begin
          br.wait_until{br.element(:xpath,xpath.to_s).exists?}
        rescue Exception => ex
          STDERR.puts ex.inspect
          binding.pry
        end
      end if opts.has_key?(:timeout)

      # assert
      opts[:assert].each do |xpath,opts|
        puts "#{action} assert #{xpath}"
        assert(br.element(:xpath,xpath.to_s).exists?)
      end if opts.has_key?(:assert)

      # process xpath
      opts[:xpath].each do |xpath,cmds|
        elem = br.element(:xpath=>xpath.to_s).to_subtype
        puts "#{action} type => #{elem.inspect}"

        cmds.each do |cmd,val|
          puts "#{action} #{cmd} => #{val}"
          begin
            case cmd.to_s
            when "flash"
              val.times {elem.flash}

            when "wait"
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

      # process element
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
