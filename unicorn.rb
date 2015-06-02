deploy_to = "/home/rakelley/www/rakelley.us"
pid_file = "#{deploy_to}/pids/unicorn.pid"
old_pid = pid_file + '.oldbin'

# Set the working application directory
# working_directory "/path/to/your/app"
working_directory "#{deploy_to}"

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid pid_file

# Path to logs
# stderr_path "/path/to/logs/unicorn.log"
# stdout_path "/path/to/logs/unicorn.log"
stderr_path "#{deploy_to}/logs/unicorn.log"
stdout_path "#{deploy_to}/logs/unicorn.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
listen "/tmp/unicorn.rakelley.sock"

# Number of processes
# worker_processes 4
worker_processes 4

# Time-out
timeout 30

# zero downtime deploy magic:
# if unicorn is already running, ask it to start a new process and quit.
before_fork do |server, worker|
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
