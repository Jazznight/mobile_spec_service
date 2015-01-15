require "digest"
require 'socket'
require 'json'
require 'yaml'

module HandsetDetection

    class Configuration

      @@other_options = {'vendors' => '/device/vendors',
        'models' => '/device/models',
        'view' => '/device/view',
        'whathas' => '/device/whathas',
      }
      unless File.exist?('./conf/handset_detection.yml')
        raise HandsetDetectionConfigFileNotFoundException.new("File ./conf/handset_detection.yml not found")
      else
        HANDSET_DETECTION_CONFIG = YAML.load_file('./conf/handset_detection.yml')
        @@other_options.each { | key, value |
          HANDSET_DETECTION_CONFIG[key] = value
        }
      end

      def self.get(option)
        HANDSET_DETECTION_CONFIG[option]
      end
    end

    

    module InstanceMethods
        
      def deviceVendors
        rep = hd_remote(Configuration.get('vendors') + ".json", "")
        headers,body = rep.split("\r\n\r\n",2)
        return JSON.parse(body)
      end
#
      def deviceModels(vendor)
        rep = hd_remote(Configuration.get('models') +"/#{vendor}.json","")
        headers,body = rep.split("\r\n\r\n",2)
        return JSON.parse(body)
      end
#
      def deviceView(vendor, model)
        rep = hd_remote(Configuration.get('view') + "/#{vendor}/#{model}.json", "")
        headers,body = rep.split("\r\n\r\n",2)
        return JSON.parse(body)
      end
#
      def deviceWhatHas(key, value)
        rep = hd_remote(Configuration.get('whathas') + "/#{key}/#{value}.json", "")
        headers,body = rep.split("\r\n\r\n",2)
        return JSON.parse(body)
      end
#
      def siteDetect(data)
        id = Configuration.get('site_id')
		    rep = hd_remote("/site/detect/#{id}.json",data)
        headers,body = rep.split("\r\n\r\n",2)
        return JSON.parse(body)
	    end

    end
########################################################################################################################
 #  private
      def hd_remote(suburl, data)
        apiserver =  Configuration.get('apiserver')
		    url = "http://" + apiserver + "/apiv3" + suburl + ".json"
        serverip = apiserver
		    jsondata = data.to_json

        begin
          servers = Socket.gethostbyname(apiserver)
          #servers = servers.shuffle
          reply = "nothing"
          servers.each{|serverip|
            reply = hd_post(apiserver,serverip, url, jsondata,suburl)
            break if reply['status'] != 301
          }
        rescue
          retry
        end

        return reply
      end
#
      def hd_post(apiserver,serverip,url,jsondata,suburl)
        username = Configuration.get('username')
        realm = 'APIv3'
        secret = Configuration.get('password')

		    port = 80
		    nc = "00000001"

		    cnonce = Digest::MD5.hexdigest("#{Time.now}#{@secret}")
    		qop = 'auth'

    		ha1 = Digest::MD5.hexdigest("#{username}:#{realm}:#{secret}")

        ha2 = Digest::MD5.hexdigest("POST:/apiv3/#{suburl}.json")

    		response = Digest::MD5.hexdigest("#{ha1}:APIv3:#{nc}:#{cnonce}:#{qop}:#{ha2}")

        if Configuration.get('use_proxy') == 1
          pserver = Configuration.get('proxy_server')
          port = Configuration.get('proxy_port')
          user  = Configuration.get('proxy_user')
          pass = Configuration.get('proxy_pass')
          socket = TCPSocket.open(pserver,port)
        else
          socket = TCPSocket.open(serverip,port)
        end
        hd_request = "POST #{url} HTTP/1.0\r\n"
     	  hd_request = hd_request + "Host: #{apiserver}\r\n"
     	  
        if Configuration.get('use_proxy') == 1 
          u = Configuration.get('proxy_user')
          p = Configuration.get('proxy_pass')
          if !u.nil? and !p.nil?
			      hd_request = hd_request + "Proxy-Authorization:Basic " + base64_encode("#{u}:#{p}") + "\r\n"
			    end
		    end
    	  hd_request = hd_request +  "Content-Type: application/json\r\n";

   		  hd_request = hd_request +  'Authorization: Digest username='
        hd_request = hd_request + '"' + Configuration.get('username') + '"' + 'realm="APIv3", nonce="APIv3",'

        hd_request = hd_request + "uri=/apiv3/#{suburl}.json, qop=auth, nc=00000001, "
        hd_request = hd_request + 'cnonce="' + "#{cnonce}" + '", '
        hd_request = hd_request + 'response="' + "#{response}" + '", '

        hd_request = hd_request + 'opaque="APIv3"'
        hd_request = hd_request + "\r\n"
		    hd_request = hd_request +  "Content-length: #{jsondata.length}\r\n\r\n"
        hd_request = hd_request +  "#{jsondata}\r\n\r\n"
        socket.write(hd_request)

		    hd_reply = socket.read

        return hd_reply
      end
#
end
