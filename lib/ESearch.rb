require 'elasticsearch'


module ESearch

    @eclient = Elasticsearch::Client.new log: false
    def ESearch.msearch(keyword)
        res = (
            @eclient.search index: 'devices', type: 'models', \
                body:{
                    query:{
                        multi_match:{
                            tie_breaker: 0.3,
                            query: keyword,
                            fields: ['general_model^4', 'search_alias^5', 'general_vendor^3', 'general_aliases^2']
                        }
                    }
                }
        )['hits']

        return nil if res['total'] == 0
        return res['hits'][0]['_source']
    end

    def ESearch.fuzzy(keyword)
        res = (
            @eclient.search index: 'devices', type: 'models', \
                body:{
                    query: {
                        dis_max: {
                            queries: [
                                {   
                                    fuzzy: { 
                                        search_alias: {
                                            value: keyword,
                                            fuzziness: 2
                                        }
                                    }
                                },
                                {   
                                    prefix: { 
                                        search_alias: {
                                            value: keyword
                                        }
                                    }
                                },
                                {
                                    match:{
                                        general_model: {
                                            query: keyword,
                                            boost: 4
                                        }
                                    } 
                                },
                                {
                                    match:{
                                        search_alias: {
                                            query: keyword,
                                            boost:5 
                                        }
                                    } 
                                },
                                {
                                    match:{
                                        general_vendor: {
                                            query: keyword,
                                            boost:3 
                                        }
                                    } 
                                },
                                {
                                    match:{
                                        general_aliases: {
                                            query: keyword,
                                            boost:2 
                                        }
                                    } 
                                }
                            ],
                            tie_breaker: 0.3
                        }
                    } 
                }
        )['hits']

        return nil if res['total'] == 0
        return res['hits'][0]['_source']

    end
end
