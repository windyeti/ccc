namespace :product do
  task delete: :environment do
    get_products
  end

  def get_products
    page = 1

    loop do
      list_resp = RestClient.get "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/products.json?page=#{page}&per_page=250}"
      sleep 0.5
      list_data = JSON.parse(list_resp.body)
      p list_data.count

      list_data.each do |product|
        delete_product(product["id"])
      end

      break if list_data.count == 0
      page += 1
    end
  end

  def delete_product(id)
    result_body = {}

    id_product = id

    url_api_category = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/products/#{id_product}.json"

    RestClient.delete( url_api_category, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 200
        puts "sleep 0.5 #{id_product} товар удалили"
        sleep 0.5
        result_body = JSON.parse(response.body)
      when 422
        puts "error 422 - не добавили категорию"
        puts response
      when 404
        puts 'error 404'
        puts response
      when 503
        sleep 1
        puts 'sleep 1 error 503'
      else
        puts 'UNKNOWN ERROR'
      end
    end
    p 'ответ на удаление END --------------------------------'
    p result_body
  end
end
