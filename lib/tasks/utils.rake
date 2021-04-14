require 'csv'

namespace :parsing do

  # require 'capybara/dsl'
  # include Capybara::DSL

  def already_done?(name)
    Category.all.each do |category|
      return true if category.name == name
    end
    return false
  end

  def get_doc(url)
    category_url = URI.escape(url)
    Nokogiri::HTML(RestClient::Request.execute(:url => category_url, :timeout => 100, :method => :get, :verify_ssl => false))
  end

  # В Стартовой точке data_category_from_up = {name: 'Luxury baby', category_path: 'Каталог/Luxury baby'}
  def create_structure(data_category_from_up, selector_top_level, selector_other_level, current_top_level = false)
    url = data_category_from_up[:link]
    url = "#{Rails.application.credentials[:shop][:old_domain]}#{url}" unless url[/http|https/]
    p url = URI.encode(url)

    doc = get_doc url

    selector = current_top_level ? selector_top_level : selector_other_level

    p category = Category.create!(
      name: data_category_from_up[:name].nil? ? "Каталог" : data_category_from_up[:name],
      link: url,
      image_from_up: data_category_from_up[:image].nil? ? nil : data_category_from_up[:image],
      image: nil,
      description_from_up: data_category_from_up[:description].nil? ? nil : data_category_from_up[:description],
      description: doc.at('.ty-mainbox-body .ty-wysiwyg-content') ? doc.at('.ty-mainbox-body .ty-wysiwyg-content').inner_html : nil,
      sdesc: nil,
      mtitle: doc.at('title').text.strip,
      mdesc:  doc.at('meta[name="description"]') ? doc.at('meta[name="description"]')['content'] : nil,
      mkeywords: doc.at('meta[name="keywords"]') ? doc.at('meta[name="keywords"]')['content'] : nil,
      category_path: data_category_from_up[:category_path]
    )

    doc_subcategories = doc.css(selector)

    p subcategories = create_layer_sub(doc_subcategories, current_top_level, data_category_from_up[:category_path]) if doc_subcategories.present?

    if subcategories.present?
      subcategories.each do |subcategory_data|
        category.subordinates << create_structure(subcategory_data, selector_top_level, selector_other_level)
      end
    end
    category
  end

  def create_layer_sub(doc_subcategories, current_top_level, category_path)
    result = []
    doc_subcategories.each do |doc_subcategory|

      if current_top_level
        link = doc_subcategory['href']
        image = nil
        name = doc_subcategory.text.strip
      else
        link = doc_subcategory['href']
        image = doc_subcategory.at('img') ? doc_subcategory.at('img')['src'] : nil
        name = doc_subcategory.text.strip
      end

      result << {
        link: link,
        description: nil,
        image: image,
        name: name,
        category_path: "#{category_path}/#{name}"
      }
    end
    result
  end

  def login
    visit Rails.application.credentials[:shop][:old_domain]
    click_on 'Личный кабинет'
    fill_in 'name', with: 'ovcharochka1987'
    fill_in 'pass', with: 'Newlife2020'
    click_on 'Войти'
    sleep 1
  end

  def scroll_to(element)
    script = <<-JS
      arguments[0].scrollIntoView(true);
    JS

    Capybara.current_session.driver.browser.execute_script(script, element.native)
  end


  def get_name_skus(link)
    visit link
    # login

    list_options_name = []
    page.all('.product-detail-options').each do |detail_option|
      list_options_name << detail_option.first('input', visible: false)['name']
    end
    list_options_name
  end

  def get_skus(link)
    skus = []
    doc = get_doc(link)
    price = doc.at('.price h2').text.strip.gsub(' ', '').gsub('р.', '').to_i
    old_price = doc.at('.price > span').text.strip.gsub(' ', '').gsub('р.', '').to_i

    script = doc.css('script').find do |script|
      script.text.include?('var poip_images = ')
    end
    json = script.text.gsub(":null", ': " "').split('poip_images = ')[1].split("var poip_product_option_ids")[0].strip.split('var poip_images_by_options = ')
    options_color_one = eval(json[1])
    options_color_zero = eval(json[0])
    File.write("#{Rails.public_path}/json_0.txt", options_color_zero)
    File.write("#{Rails.public_path}/json_1.txt", options_color_one)

    doc_options_container = doc.css('#product .options .form-group')

    doc_options_container.each do |doc_option_container|
      name_option = doc_option_container.at('label').text.strip
      options = doc_option_container.css('option').reject do |option|
        option['value'].blank?
      end

      array_option = []

      if options.size == 1 && options.first.text.match(/\(\+\d*р\.\)/)
        array_option << {
          name: name_option,
          value: 'Стандартный',
          data_price: 0,
          price: price,
          old_price: old_price
        }
      end

      if name_option == 'Цвет' || name_option == 'Выберите цвет'
        options.each do |option|
          url_image = ''
          all_url_image = []
            options_color_zero.each do |option_color_zero|
              all_url_image << URI.encode(option_color_zero[:popup])

              if option_color_zero[:product_option_value_id]&.include?(option['value'])
                url_image = URI.encode(option_color_zero[:popup])
              end
            end

          array_option << {
            name: name_option,
            value: option.text.strip,
            data_price: option['data-price'].to_i,
            image: all_url_image.unshift(url_image).uniq.join(' '),
            price: price,
            old_price: old_price
          }
        end
      else
        options.each do |option|
          array_option << {
            name: name_option,
            value: option.text.strip,
            data_price: option['data-price'].to_i,
            price: price,
            old_price: old_price
          }
        end
      end
      skus << array_option
    end
    OBender.new(*skus).vasyuki
  end

  def get_code
    code = nil
    first_div = page.first('.product-desc__value').text rescue nil
    if first_div.present? && first_div.include?('Артикул:')
      code = page.first('.product-desc__value').text.gsub('Артикул:','').strip rescue nil
    end
    code
  end

  def get_price_from_file(code)
    price = nil
    rows = CSV.read("#{Rails.public_path}/price.csv", headers: true).map do |row|
      row.to_hash
    end
    rows.each do |row|
      price = row[:price] if row[:sku] == code
    end
    price
  end

  def get_props(doc)
    result = []
    props = doc.css('#content_features .ty-product-feature')
    props.each do |prop|
      name = prop.at('.ty-product-feature__label').text.gsub(/:$/,'')
      value = prop.at('.ty-product-feature__value')
                .text
                .split(',')
                .map { |v| v.strip }
                .join(' ## ')
      result << "#{name}: #{value}"
    end
    result.join(' --- ')
  end

  def get_desc(doc, fid, product_link)
    doc_desc = doc.at('#content_description')
    doc_desc.css("img").each do |img|
      link = img['src'].split('?').first
      img.attributes["src"].value = create_and_get_url_file(link, fid, product_link)
    end
    doc_desc.to_html
  end

  def get_images(doc)
    if doc.css('.ty-product-block__img-wrapper .ty-product-thumbnails img').size > 0
      doc.css('.ty-product-block__img-wrapper .ty-product-thumbnails img').map do |image|
        image['src'].gsub('/thumbnails/35/35','')
      end.join(' ')
    elsif doc.at('.ty-product-img .ty-pict')
      doc.at('.ty-product-img .ty-pict')['src']
    else
      nil
    end
  end

  def get_quantity(doc)
    block = doc.at('.ty-control-group.product-list-field .ty-qty-out-of-stock.ty-control-group__item')
    '0' if block.present? && block.text == 'Предзаказ'
  end

  def create_and_get_url_file(link, fid, product_link)

    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    name = link.split('/').last
    short_name = link.split('/').last.split('.').first
    ext_name = link.split('/').last.split('.').last
    p link_name = {
      name: name,
      short_name: short_name,
      ext_name: ext_name,
      link: link
    }
    new_src = ''
    data = 	{
              "file": {
                "src": link_name[:link],
                "filename": "#{link_name[:short_name]}__#{Time.now.to_i}.#{link_name[:ext_name]}"
              }
            }
    uri = "http://"+api_key+":"+password+"@"+domain+"/admin/files.json"

    RestClient.post( uri, data.to_json, {:content_type => 'application/json', accept: :json}) { |response, request, result, &block|
      sleep 0.5
      case response.code
      when 201
        puts 'code 201 - ok'
        resp_data = JSON.parse(response)
        new_src = resp_data['absolute_url']
        new_src
      when 422
        p 'code 422 - уже существует'
        begin
         get_doc(link_name[:link])

         File.open("#{Rails.public_path}/___error_image___.html", 'w') do |f|
           f.write "#{link_name[:link]} --- #{product_link}"
         end
        rescue
          p "Нет такой страницы или изображения #{link_name[:link]}"
          return nil
        end

        # number_in_request = 250
        # page = 1
        # loop do
        #   list_resp = RestClient.get "http://#{api_key}:#{password}@#{domain}/admin/files.json?page=#{page}&per_page=#{number_in_request}"
        #   sleep 0.5
        #   list_data = JSON.parse(list_resp)
        #
        #   list_data.each do |ld|
        #     p check = ld['absolute_url'].split('/').last.split('?').first.gsub(/\.$/,'')
        #     p link_name[:name].gsub(/\(|\)/, '_')
        #     new_src = ld['absolute_url'] if check == link_name[:name].gsub(/\(|\)/, '_')
        #   end
        #   break if list_data.count < number_in_request || !new_src.empty?
        #   page += 1
        # end
      else
        response.return!(&block)
      end
    }
    # raise if new_src.empty?
    p new_src
  end
end
