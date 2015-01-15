load './lib/agent_scrap_include.rb'
require 'set'

@root="./agent_data"
@handset_url='http://www.handsetdetection.com/'

@crawler = Crawler.new
vendorDOC    = @crawler.scrap('http://www.handsetdetection.com/properties/vendormodel')
vendorDOCs = vendorDOC.xpath("//div[@class='vendors']/ul/li")

def getPageAgents(url)

    pageAgentSet = Set.new

    detailDOC    = @crawler.scrap(url)
    agentDOCs    = detailDOC.xpath("//div[@class='roundblock']/table/tr")
    nextDOC        = detailDOC.xpath("//div[@class='paging'][1]/span[last()]")

    agentDOCs.drop(1).each {|agent| pageAgentSet.add ( agent.xpath("td[2]/text()") ) }

    if (nextDOC.xpath("@class").to_s == "next") 
        nextUrl = nextDOC.xpath("a/@href").to_s
        pageNum = nextUrl.split(":")[1].to_i
        pageAgentSet.merge( getPageAgents(@handset_url + nextUrl) ) if pageNum < 30
    end

    return pageAgentSet

end

#vendorDOCs.drop(468).each {|vDoc| 
vendorDOCs.each {|vDoc| 
    vendor        = vDoc.xpath("a/text()").to_s
    next if vendor==".mobi"
    vendor.gsub(/\ /,"_")
    system 'mkdir', '-p', "#{@root}/#{vendor}"
    vendorUrl = vDoc.xpath("a/@href").to_s


    vendorDevices    = @crawler.scrap(@handset_url + vendorUrl)
    deviceDOCs         = vendorDevices.xpath("//div[@class='row'][1]//table//td")
    deviceDOCs.each {|dDoc|

        device         = dDoc.xpath("div/a/text()").to_s
        device_url = dDoc.xpath("div/a/@href").to_s
        model            = device_url.split('/').last
        model.gsub(/\ /,"_")

        if vendor=="Android" && model=="Generic"
            puts "Skip [#{vendor} #{model}] ..."
            next
        else
            puts "Working on [#{vendor} #{model}] now..."
        end

        agentSet = Set.new
        agentSet.merge( getPageAgents(@handset_url + device_url) )

        File.open("/tmp/test.dat","w") {|file| 
            agentSet.each {|agentString| file.puts agentString }
        }
            #puts "#{vendor} .. #{device}:#{model} -> #{device_url}"
        
    }

}



# doc=cralwer.scrap('http://www.handsetdetection.com/properties/vendormodel/HTC')
# td=doc.xpath("//div[@class='row'][1]//table//td")
# td[1].xpath("div/a/@href").to_s
