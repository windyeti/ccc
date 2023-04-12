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

    if data_category_from_up[:doc_sub].present?
      doc = data_category_from_up[:doc_sub]
    else
      doc = get_doc url
    end

    doc_cat = get_doc url
    desc = get_desc(doc_cat.at(".XYZ"))
    sdesc = get_desc(doc_cat.at(".XYZ"))

    selector = current_top_level ? selector_top_level : selector_other_level

    p category = Category.create!(
      name: data_category_from_up[:name].nil? ? "Каталог" : data_category_from_up[:name],
      link: url,
      image_from_up: data_category_from_up[:image].nil? ? nil : data_category_from_up[:image],
      image: nil,
      description_from_up: data_category_from_up[:description].nil? ? nil : data_category_from_up[:description],
      description: desc,
      sdesc: sdesc,
      mtitle: doc_cat.at('title') ? doc_cat.at('title').text.strip : nil,
      mdesc:  doc_cat.at('meta[name="description"]') ? doc_cat.at('meta[name="description"]')['content'] : nil,
      mkeywords: doc_cat.at('meta[name="keywords"]') ? doc_cat.at('meta[name="keywords"]')['content'] : nil,
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
        name = doc_subcategory.text.strip.gsub("/","&#47;")
        doc_sub = nil
      else
        link = doc_subcategory['href']
        image = doc_subcategory.at('.catalog-section__img')['src']
        name = doc_subcategory.text.strip.gsub("/","&#47;")
        doc_sub = nil
      end

      result << {
        link: link,
        description: nil,
        image: image,
        name: name,
        category_path: "#{category_path}/#{name}",
        doc_sub: doc_sub
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

  def get_title(title)
    tov = Tov.find_by(title: title)

    if tov.present?
      count = 1
      loop do
        title = "#{title.gsub(/__\d+$/,'')}__#{count}"
        break if Tov.find_by(title: title).nil?
        count += 1
      end
    end
    title
  end

  def get_skus(doc)
    skus = doc.css('select.select.offers-select option').map do |option|
      fid = option['value']
      price = option['data-price']
      size = option.text.gsub(/\(1\s?шт\.\)/, "").split("(").last.gsub(/\(|\)/, "").strip
      {
        fid: fid,
        size: size,
        price: price,
      }
    end
    skus
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

  def get_desc(doc_desc)
    return nil if doc_desc.nil?
    doc_desc.css("img").each do |doc_img|
      doc_parent = doc_img.parent
      doc_parent_href = doc_parent['href']
      if doc_parent_href.present?
        doc_parent_href = doc_parent_href.match(/^http/).present? ? doc_parent_href : "#{Rails.application.credentials[:shop][:old_domain]}#{doc_parent_href}"
        doc_parent.attributes["href"].value = create_and_get_url_file(doc_parent_href)
      end
      link = doc_img['src'].split('?').first
      link = link.match(/^http/).present? ? link : "#{Rails.application.credentials[:shop][:old_domain]}#{link}"
      doc_img.attributes["src"].value = create_and_get_url_file(link)
    end
    doc_desc.css("iframe").each do |doc_iframe|
      src = doc_iframe.attributes["src"].value
      doc_iframe.attributes["src"].value = "https:#{src}" unless src.match(/^https:/)
    end
    doc_desc.to_html
  end

  def get_addition_field_brand(doc)
    doc_href = doc.at(".product-intro__addition .product-intro__addition-item .product-intro__addition-link")
    return nil if doc_href.nil?

    begin
      p link = doc_href['href']
      p category = Category.find_by(link: link)
      p url = category.url
      doc_href.attributes['href'].value = url
      doc_href.to_html
    rescue
      return doc_href.text.strip
    end
  end

  def get_images(doc)
    images = []
    doc_images =  doc.css('.col-sm-5 .product-photo__item')
    if doc_images.size > 0
      doc_images.map do |doc_image|
        images << doc_image['href']
      end
    end
    doc_images =  doc.css('.product-photo__thumb > a')
    if doc_images.size > 0
      doc_images.map do |doc_image|
        images << doc_image['href']
      end
    end
    images.present? ? images.compact.map(&:strip).uniq.join(' ') : nil
  end

  def get_quantity(doc)
    block = doc.at('.ty-control-group.product-list-field .ty-qty-out-of-stock.ty-control-group__item')
    '0' if block.present? && block.text == 'Предзаказ'
  end

  def create_and_get_url_file(old_url)
    new_src = ''

    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    # если уже создавался файл по такой ссылке, возвращаем новыу ссылку
    image = Image.find_by(old_url: old_url)
    if image.present?
      return image.new_url
    end

    p name = {
      full_name: old_url.split('/').last,
      short_name: old_url.split('/').last.split('.').first,
      ext_name: old_url.split('/').last.split('.').last,
    }

    # если по такой ссылке файл не создавался, то проверяем имя содаваемого файла,
    # и переименовываем в случае существования файла с таким именем
    name_image = Image.find_by(name: name[:full_name])
    if name_image.present?
      data = 	{
        "file": {
          "src": old_url,
          filename: "#{name[:short_name]}_#{Time.now.to_i}.#{name[:ext_name]}"
        }
      }
    else
      data = 	{
        "file": {
          "src": old_url
        }
      }
    end

    uri = "http://"+api_key+":"+password+"@"+domain+"/admin/files.json"

    RestClient.post( uri, data.to_json, {:content_type => 'application/json', accept: :json}) { |response, request, result, &block|
      sleep 0.5
      case response.code
      when 201
        puts 'code 201 - ok'
        resp_data = JSON.parse(response)
        new_src = resp_data['absolute_url']
      when 422
        p 'так быть не должно -------------------------- code 422 - сылка битая'
        new_src = old_url
      else
        response.return!(&block)
      end
    }
    Image.create(
           old_url: old_url,
           new_url: new_src,
           name: new_src.split("/").last.remove(/\?\d+$/)
    )
    p new_src
  end
end
