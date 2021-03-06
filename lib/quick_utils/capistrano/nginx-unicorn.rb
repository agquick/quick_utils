Capistrano::Configuration.instance.load do

  _cset :root, "#{deploy_to}/current/public"
  _cset :unicorn_binary, "unicorn"
  _cset :unicorn_config, "#{current_path}/config/unicorn.rb"
  _cset :unicorn_pid_file, "#{current_path}/tmp/pids/unicorn.pid"

  namespace :deploy do
    task :start do ; end
    task :stop do ; end
    task :restart, :roles => :app, :except => { :no_release => true } do
      unicorn.restart
    end
  end

  def unicorn_pid
    "`cat #{unicorn_pid_file}`"
  end

  def remote_process_exists?(pid_file)
    "[ -e #{pid_file} ] && kill -0 `cat #{pid_file}` > /dev/null 2>&1"
  end
  
  def unicorn_is_running?
    remote_process_exists?(unicorn_pid_file)
  end

  def unicorn_send_signal(signal, pid=unicorn_pid)
    "kill -s #{signal} #{pid}"
  end

  def kill_unicorn(signal)
    script = <<-END
      if #{unicorn_is_running?}; then
        echo "Stopping Unicorn...";
        #{unicorn_send_signal(signal)};
      else
        echo "Unicorn is not running.";
      fi;
    END

    script
  end

  def start_unicorn
    script = <<-END
      echo "Starting Unicorn...";
      cd #{current_path} && bundle exec #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D;
    END

    script
    
  end

  def duplicate_unicorn
    script = <<-END
      if #{unicorn_is_running?}; then
        echo "Duplicating Unicorn...";
        #{unicorn_send_signal('USR2')};
      else
        #{start_unicorn}
      fi;
    END

    script
  end
  
    

  namespace :unicorn do

    task :start, :roles => :app, :except => { :no_release => true } do 
      run start_unicorn
    end

    task :stop, :roles => :app, :except => { :no_release => true } do 
      run kill_unicorn('TERM')
    end

    task :graceful_stop, :roles => :app, :except => { :no_release => true } do
      run kill_unicorn('QUIT')
    end

    task :reload, :roles => :app, :except => { :no_release => true } do
      #run "kill -s USR2 `cat #{unicorn_pid}`"
    end

    task :restart, :roles => :app, :except => { :no_release => true } do
      run duplicate_unicorn
    end

  end

end
