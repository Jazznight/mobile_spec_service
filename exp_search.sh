#!/bin/sh

#curl -i -XGET 'http://localhost:9200/device/models/_search?pretty' -d '{ "query": { "match": { "general_vendor": "HTC" } } } '


#curl -i -XGET 'http://localhost:9200/device_mongo/models/_search?pretty' -d "
curl -i -XGET 'http://localhost:9200/devices/models/_search?pretty' -d "
{ 
  \"query\": { 
    \"multi_match\": {
      \"tie_breaker\": 0.3,
      \"query\":\"$1\",
      \"fields\":[\"general_model^4\",\"search_alias^4\",\"general_vendor^3\",\"general_aliases^2\",\"general_platform\"]
    }  
  } 
}"
