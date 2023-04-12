namespace :parsing do
  task create_categories: :environment do
    file = "#{Rails.root}/public/create_category.txt"
    if File.exist?(file)
      File.delete(file)
    end

    parent_id = get_id_main_collection

    create_category(Category.first, parent_id)
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    p "XXXX  НЕ СОЗДАЛОСЬ КАТЕГОРИЙ #{Category.where.not(parent_id: nil).where(url: nil).count}  XXXX"
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  end

  task create_categories_again: :environment do
    categories = Category.where.not(parent_id: nil).where(url: nil)
    categories.each do |category|
      # pp category
      create_category(category, category.parent_id)
    end
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    p "XXXX  НЕ СОЗДАЛОСЬ КАТЕГОРИЙ #{Category.where.not(parent_id: nil).where(url: nil).count}  XXXX"
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  end

  def create_category(parent_category, parent_id)

    p 'START  --------------------------------'
    src = parent_category.image_from_up.nil? ? nil : create_and_get_url_file(parent_category.image_from_up)
    if parent_category.name != "Каталог"
      p data = {
        "collection": {
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
      }
      response = api_create_category(data)
      if response["image.image"].present? || response["image.src"].present?
        data[:collection][:image_attributes] = nil
        response = api_create_category(data)
      end
      parent_category.update(url: response['url'])
      parent_id = response['id']
      api_create_redirect(parent_category.link, response['url'])
    else
      api_create_redirect(parent_category.link, "http://#{Rails.application.credentials[:shop][:domain]}/collection/all")
    end

    parent_category.subordinates.each do |category|
      category.update(parent_id: parent_id)
      create_category(category, parent_id)
    end
  end

  # TODO Передавать SEO: title, description
  def api_create_category(data)

    result_body = {}

    url_api_category = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/collections.json"

    RestClient.post( url_api_category, data.to_json, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 201
        puts 'Категория -|-'
        sleep 1
        result_body = JSON.parse(response.body)
      when 422
        sleep 1
        puts 'Категория ----'
        # puts "error 422 - не добавили категорию"
        p result_body = response
        # data[:collection][:image_attributes] = nil
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
        puts 'sleep 1 редирект добавили'
        sleep 1
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

  def get_id_main_collection
    url_api_category = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/collections.json"

    response = RestClient.get( url_api_category, :accept => :json, :content_type => "application/json")
    body = JSON.parse(response.body)
    main_collection = body.find {|collection| collection["parent_id"].nil?}
    main_collection["id"]
  end

end
