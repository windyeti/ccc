namespace :parsing do
  task create_categories: :environment do
    file = "#{Rails.root}/public/create_category.txt"
    if File.exist?(file)
      File.delete(file)
    end

    parent_id = '16356602'
    url_source = Rails.application.credentials[:shop][:old_domain]
    selector_top_level = '.main-catalog .item'
    selector_other_level = '.catalog-category-grid a'

    pp structure = category_structure(
                                      url_source,
                                      {name: 'Luxury baby', category_path: 'Каталог/Luxury baby'},
                                      selector_top_level,
                                      selector_other_level,
                                      true
                                      )
    # File.write("#{Rails.root}/public/my_structure.txt", structure)
    #
    # create_category(structure, parent_id, "Каталог")
  end

  def create_category(parent_category, parent_id, parent_category_path)

    if parent_category_path != "Каталог"
      name = parent_category[:name]
      link = parent_category[:link]
      image = parent_category[:image_from_up]
      # description = parent_category[:description]

      doc_category = get_doc(link)
      p data = {
        "title": name,
        "parent_id": parent_id,
        "html_title": doc_category.at_css('title').text.strip,
        "meta_description": doc_category.at_css('meta[name="description"]') ? doc_category.at_css('meta[name="description"]')['content'] : nil,
        "meta_keywords": doc_category.at_css('meta[name="keywords"]') ? doc_category.at_css('meta[name="keywords"]')['content'] : nil,
        "description": doc_category.at('.text-description') ? doc_category.at('.text-description').inner_html : nil,
        "seo_description": nil,
        "image_attributes": {
          "src": image,
        }
      }

      response = api_create_category(data)
      parent_id = response['id']
      api_create_redirect(link, response['url'])
    end

    parent_category[:children].each do |category|
      path_current_category = "#{parent_category_path}/#{category[:name]}"

      create_category(category, parent_id, path_current_category)
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
