namespace :parsing do
  task create_categories: :environment do
    file = "#{Rails.root}/public/create_category.txt"
    if File.exist?(file)
      File.delete(file)
    end

    parent_id = '18471481'

    create_category(Category.first, parent_id)
  end

  def create_category(parent_category, parent_id)

    if parent_category.name != "Каталог"
      p data = {
        "title": parent_category.name,
        "parent_id": parent_id,
        "html_title": parent_category.mtitle,
        "meta_description": parent_category.mdesc,
        "meta_keywords": parent_category.mkeywords,
        "description": parent_category.description,
        "seo_description": parent_category.sdesc,
        "image_attributes": {
          "src": parent_category.image_from_up,
        }
      }

      response = api_create_category(data)
      parent_id = response['id']
      api_create_redirect(parent_category.link, response['url'])
    else
      api_create_redirect(parent_category.link, "http://myshop-ble273.myinsales.ru/collection/all")
    end

    parent_category.subordinates.each do |category|
      create_category(category, parent_id)
    end
  end

  # TODO Передавать SEO: title, description
  def api_create_category(data)

    add_data = {
      "collection": data
    }

    result_body = {}

    url_api_category = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/collections.json"

    RestClient.post( url_api_category, add_data.to_json, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 201
        puts 'sleep 0.3 категорию добавили'
        sleep 0.3
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
    p 'ответ создания категории END --------------------------------'
    result_body
  end

  def api_create_redirect(old_url, new_url)
    p data = {
      "redirect": {
        "old_url": old_url,
        "new_url": new_url
      }
    }
    url_api_redirect = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/redirects.json"

    RestClient.post( url_api_redirect, data.to_json, :accept => :json, :content_type => "application/json") { |response, request, result, &block|

      case response.code
      when 201
        puts 'sleep 0.3 редирект добавили'
        sleep 0.3
      when 422
        puts "error 422 - не добавили редирект"
        puts response
        break
      when 404
        puts 'error 404'
        break
      when 503
        sleep 1
        puts 'sleep 1 error 503'
      else
        response.return!(&block)
      end
    }
  end
end
