project_home = "/home/rakelley/www/rakelley.us"
project_name = "rakelley"
pid_file = "#{project_home}/pids/unicorn.pid"

working_directory "#{project_home}"

pid pid_file

stderr_path "#{project_home}/logs/unicorn.log"
stdout_path "#{project_home}/logs/unicorn.log"

listen "/tmp/unicorn.#{project_name}.sock"

worker_processes 4

timeout 30

# zero downtime deploy magic
before_fork do |server, worker|
  old_pid = pid_file + '.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
