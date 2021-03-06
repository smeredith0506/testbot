require File.expand_path(File.join(File.dirname(__FILE__), "/helpers/ruby_env"))

class Rspec2Adapter

  def self.command(project_path, ruby_interpreter, files)
    spec_command = RubyEnv.ruby_command(project_path,
      :bin => "rspec",
      :ruby_interpreter => ruby_interpreter)
   
    if File.exists?("#{project_path}/spec/spec.opts")
      spec_command += " -O spec/spec.opts"
    end
    "export RSPEC_COLOR=true; #{spec_command} --failure-exit-code 99 #{files}"
  end

  def self.test_files(dir)
    if ENV['SELENIUM_SPECS']
      puts 'running selenium specs'
      test_files = FileList['spec/selenium/**/*_spec.rb'] + FileList['{gems,vendor}/plugins/*/spec_canvas/selenium/*_spec.rb'] 
    elsif ENV['PLUGIN_SPECS']
      puts 'running plugin specs'
      test_files = FileList['{gems,vendor}/plugins/*/spec_canvas/**/*_spec.rb'].exclude(%r'spec_canvas/selenium') + FileList['spec/**/*_spec.rb'].exclude(%r'spec/selenium') 
    else
      puts 'normal pattern'
      test_files = Dir["#{dir}/#{file_pattern}"]
    end
    test_files
  end

  def self.get_sizes(files)
    files.map { |file| File.stat(file).size }
  end

  def self.requester_port
    2299
  end

  def self.pluralized
    'specs'
  end

  def self.base_path
    "spec"
  end

  def self.name
    'RSpec2'
  end

  def self.type
    'rspec'
  end

private

  def self.file_pattern
    '**/**/*_spec.rb'
  end

end
