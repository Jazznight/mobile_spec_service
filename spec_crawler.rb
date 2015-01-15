require 'elasticsearch'
require 'mongo'
require 'multi_json'
require 'set'

# Exclude Vendors:
# Klondike
# CheckCom
# WinWAP Technologies
# Wapsilon
# UCWEB
# GENERIC
# LYNX
# Polaris

# Exclude Models:
# WAP Browser
# MAUI WAP Browser
# WinWAP Browser
# WAP SDK

load './lib/hsd_service_include.rb'
load './lib/config.rb'


include HandsetDetection
include HandsetDetection::InstanceMethods

CFG = STORAGE_CONFIG::CONFIG
DBNAME = 'device'
TBNAME = 'models'

VERSION="0.8"

excludeVendors = 
    Set.new [ 
        "klondike" ,
        "checkcom" ,
        "winwap technologies" ,
        "wapsilon" ,
        "ucweb" ,
        "generic" ,
        "lynx", 
        "m3 gate", 
        "polaris", 
        "novarra", 
        "skyfire", 
        "openwave", 
        "doris"
    ]

excludeModels = 
    Set.new [ 
        "wap browser",
        "maui wap browser", 
        "winwap browser", 
        "wap sdk", 
        "generic wap 2"
    ]

#client = Elasticsearch::Client.new log: true
@ec_client = Elasticsearch::Client.new host: CFG['es_host'], log: true
@mongo_client = Mongo::Connection.new(CFG['mongo_host'],CFG['mongo_port']).db(DBNAME).collection(TBNAME)

def search(keyword)
    res = (
        @eclient.search \
            body:{
                query:{
                    multi_match:{
                        tie_breaker: '0.3',
                        query: keyword,
                        fields: ['general_model^4','search_alias','general_vendor^3','general_aliases^2','general_platform']
                    }
                }
            }
    )['hits']

    return nil if res['total'] == 0
    return res['hits'][1]['_source']
end

# Device.where(:supported => "SUPPORTED").each do |device|
# 
#     keyword="#{device.vendor.name} #{device.name}"
#     r=search(keyword)
# 
#     File.open("#{@root}/#{vendor}/#{model}.dat","w") {|file|
#         file.puts 
#     } if r==nil
# 
#     puts r
# end


vendors = MultiJson.load(deviceVendors)["vendor"]
vendorsDropCnt=0
offsetMode=false
vendors.each {|v| 
    if(v==ARGV[0])
        offsetMode=true
        break
    end
    vendorsDropCnt=vendorsDropCnt+1 
} if ARGV[0] != nil

vendors.drop(vendorsDropCnt).each {|vendor|

  next if excludeVendors.include?(vendor.downcase)

  vendor=vendor.gsub(/\ /,"%20")

  devices = MultiJson.load(deviceModels(vendor))["model"]
  devicesDropCnt=0
  devices.each {|d| break if( d==ARGV[1]); devicesDropCnt=devicesDropCnt+1 } if ARGV[1] != nil && offsetMode

  puts "#{vendor}/ #{devices}"

  seq=1
  devices.drop(devicesDropCnt).each {|device| 

    next if excludeModels.include?(device.downcase)

    device=device.gsub(/\ /,"%20")
    begin
        modelJson = MultiJson.load( deviceView(vendor,device) )
        model     = modelJson["device"]["general_model"]
    rescue
        model = "GENERAL-#{seq}"
        puts "Skip .. #{vendor} ...  <#{device}:#{model}>"
        next
    end
    puts "#{vendor} ...  <#{device}:#{model}>"


    #modelJson.each {|key| delete(key) if key=="message" || key=="status"}
    modelJson.delete("message") #if modelJson.has_key?("message")
    modelJson.delete("status") #if modelJson.has_key?("status")
    modelJson["_id"] = "#{vendor.gsub(/%20/," ")}_#{model.gsub(/%20/," ")}"
    modelJson["search_alias"] = Array.new ["#{vendor.gsub(/%20/,"")}#{model.gsub(/%20/,"")}"]
        
    modelJson["supported"]  = false
    modelJson["is_android"] = false

    begin
        if modelJson["device"]["general_platform"].downcase.include? "android" then
            modelJson["supported"]  = true
            modelJson["is_android"] = true
        end
    rescue

    end

    modelJson["crawler_ver"] = VERSION
    modelJson["is_verified"] = false

    begin
        @mongo_client.insert modelJson
        @ec_client.index index: DBNAME, type: TBNAME, id: modelJson["_id"], body: modelJson
    rescue
    end
  }


}


#devices=JSON.parse(`curl -u '#{user}:#{password}' --digest http://api.handsetdetection.com/apiv3/device/models/HTC`)
#devices["model"].each {|device|
#  puts device
#}
