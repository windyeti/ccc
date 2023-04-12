namespace :redirect do
  task short_url: :environment do
    rows = CSV.read("#{Rails.public_path}/redir.csv", headers: true)
    CSV.open("#{Rails.public_path}/short_redir.csv", "a+") do |csv|
      rows.each do |row|
        csv << [row['Параметр: OLDLINK'], "https://#{Rails.application.credentials[:shop][:domain]}/product/#{row['Название товара в URL']}"]
      end
    end
  end

  task destroy: :environment do
    redirects = []
    page = 1
    loop do
      response = api_get_redirects(page)
      body = JSON.parse(response.body)
      p body.size
      break if body.size == 0
      redirects += body
      page += 1
    end
    sleep 60
    p redirects.count

    redirects.each do |redirect|
      if redirect["new_url"].match(/\/product\//)
        api_destroy_redirect(redirect["id"])
        # p redirect
        # break
      end
    end
  end

  def api_get_redirects(page)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/redirects.json?per_page=250&page=#{page}"

    RestClient.get(url_api_category)
  end

  def api_destroy_redirect(id)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/redirects/#{id}.json"

    RestClient.delete( url_api_category, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      sleep 1
      case response.code
      when 200
        p 'code 200 - sleep 0.6'
        sleep 0.6
      when 422
        p 'code 422'
      else
        response.return!(&block)
      end
    end
  end
end
