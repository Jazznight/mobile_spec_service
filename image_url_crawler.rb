require 'mechanize'

# This class part is only for class definition
class Crawler

    def initialize
        @crawler = Mechanize.new { |agent| agent.user_agent_alias = 'Windows Mozilla' }
    end

    def get(url)
        @crawler.get(url)
    end

    def login(login_url,user,password, form_id)
        @crawler.get(login_url) do |page|
            login_page = page.form_with(:id => form_id) do |f|
                f.login    = user
                f.password = password
            end.click_button
        end
    end

    def scrap(url)
        begin
            html_body = @crawler.get(url).parser
        rescue
            retry
        end

        return Nokogiri::HTML( html_body.to_s  )
    end

end

# Program start from here
gsm_url='http://www.gsmarena.com/'

cw = Crawler.new
page = cw.get(gsm_url)

search_result = 
    page.form_with(:id => 'topsearch') do |search|
        search.sName = ARGV[0]
    end.submit

phoneDoc = search_result.parser

if search_result.uri.to_s.include? "www.gsmarena.com/results.php3"
    res = phoneDoc.xpath("//div[@class='st-text']/p[0]/text()").to_s

    return nil if res.downcase.include? "no phones found!"

    phoneLink = phoneDoc.xpath("//div[@class='makers']/ul/li[1]/a/@href").to_s
    phoneDoc  = cw.scrap("#{gsm_url}/#{phoneLink}")
end

puts phoneDoc.xpath("//div[@id='specs-cp-pic']/a/img/@src").to_s
