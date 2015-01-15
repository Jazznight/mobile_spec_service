require 'yaml'

module STORAGE_CONFIG

    cfgFile = './conf/storage.yml'
    CONFIG={}
    
    @@other_options = {
        'other_key' => 'other_value',
        'DUMMY' => 'DUMMY_VALUE'
    }
    
    unless File.exist?(cfgFile)
        raise FileNotFoundException.new("File '#{cfgFile}' not found")
        else
            CONFIG = YAML.load_file(cfgFile)
            @@other_options.each { | key, value |
                CONFIG[key] = value
            }
    end
end
