require 'rubygems'
require 'git'
require 'zlib'
require 'fileutils'

class Gitbackup
  def initialize(configs_path, backup_path, repo_path, switches)
    @configs_path = configs_path
    @backup_path = backup_path
    @repo_path = repo_path
    @switches  = switches  
  end
    
  def run
    @switches.each do |switch|
      newconfigs = get_new_configs switch
      newconfigs.each do |config|
        config_content = ungzip "#{@configs_path}/#{switch}/#{config}"
        save_to_repo "#{switch}.txt", config_content 
        commit config
        FileUtils.mv "#{@configs_path}/#{switch}/#{config}", "#{@backup_path}/#{switch}/#{config}"
      end
    end
    push
  end	

private
  def get_new_configs(switch)
    dir = Dir.open "#{@configs_path}/#{switch}"
    dir.grep(/sw/).sort
  end

  def ungzip(file_path) 
    file = open file_path
    gz = Zlib::GzipReader.new(file)
    gz.read
  end
  
  def save_to_repo(filename,file)
    output_file = File.new("#{@repo_path}/#{filename}","w")
    output_file.write(file)
    output_file.close
  end

  def commit(message)
    g = Git.open(@repo_path)
    g.add('.')
    g.commit_all(message)
  end

  def push
    g = Git.open(@repo_path)
    g.push
  end
end

configs_path = '/home/juniper'
backup_path = '/home/juniper/backup'
repo_path = '/home/juniper/juniper/repo'
switches = [
'sw240133',
'sw240233',
'sw240333',
'sw240433',
'sw240533',
'sw240633',
'sw240733',
'sw240833',
'sw240933',
'sw241033',
'sw241233',
'sw480134',
'sw480234',
'sw480334',
'sw480434',
'sw480534',
'sw480634',
'sw480734',
'sw480834',
'sw480934',
'sw481034',
'sw481234' ]

backup = Gitbackup.new configs_path, backup_path, repo_path, switches
backup.run
