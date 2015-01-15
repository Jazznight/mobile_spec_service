require 'mechanize'

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


