#!/bin/sh

#curl -i -XGET 'http://localhost:9200/device/models/_search?pretty' -d '{ "query": { "match": { "general_vendor": "HTC" } } } '


#{   \"fuzzy\": { \"search_alias\": \"$1\" }},

#curl -i -XGET 'http://localhost:9200/device_mongo/models/_search?pretty' -d "
curl -i -XGET 'http://localhost:9200/devices/models/_search?pretty' -d "
{ 
    \"query\": {
        \"dis_max\": {
            \"queries\": [
                {   
                    \"fuzzy\": { 
                        \"search_alias\": {
                            \"value\": \"$1\",
                            \"fuzziness\": 100
                        }
                    }
                },
                {
                    \"match\":{
                        \"general_model\": {
                            \"query\": \"$1\",
                            \"boost\": 4
                        }
                    } 
                },
                {
                    \"match\":{
                        \"search_alias\": {
                            \"query\": \"$1\",
                            \"boost\":5 
                        }
                    } 
                },
                {
                    \"match\":{
                        \"general_vendor\": {
                            \"query\": \"$1\",
                            \"boost\":3 
                        }
                    } 
                },
                {
                    \"match\":{
                        \"general_aliases\": {
                            \"query\": \"$1\",
                            \"boost\":2 
                        }
                    } 
                }
            ],
            \"tie_breaker\": 0.3
        }
    }, 
    \"highlight\" : {
        \"fields\":{
            \"general_model\": {},
            \"search_alias\": {},
            \"general_vendor\": {},
            \"general_aliases\": {}
        } 
    }
}"
