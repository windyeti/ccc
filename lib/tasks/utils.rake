require 'csv'

namespace :parsing do

  require 'capybara/dsl'
  include Capybara::DSL

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

    visit url
    sleep 3

    selector = current_top_level ? selector_top_level : selector_other_level

    p category = Category.create!(
      name: data_category_from_up[:name].nil? ? "Каталог" : data_category_from_up[:name],
      link: url,
      image_from_up: data_category_from_up[:image].nil? ? nil : data_category_from_up[:image],
      image: nil,
      description_from_up: data_category_from_up[:description].nil? ? nil : data_category_from_up[:description],
      description: nil,
      sdesc: nil,
      mtitle: nil,
      mdesc:  nil,
      mkeywords: nil,
      category_path: data_category_from_up[:category_path]
    )

    doc_subcategories = page.all(selector, visible: false).uniq

    subcategories = create_layer_sub(doc_subcategories, current_top_level, data_category_from_up[:category_path]) if doc_subcategories.present?
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
        image = nil
        name = Nokogiri::HTML(doc_subcategory['innerHTML']).at('span').text.strip
      end

      result << {
        link: link,
        description: nil,
        image: nil,
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

  def get_images(doc)
    result = doc.css('.slider-product .slides a').map { |capydoc_image| capydoc_image['href'] }
    result.join(' ')
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
    visit link
    # login

    list_options_name = []
    page.all('.product-detail-options').each do |detail_option|
      list_options_name << detail_option.first('input', visible: false)['name']
    end

    options_value = {}
    page.all('.product-detail-options').each do |detail_option|
      name = detail_option.first('input', visible: false)['name']
      options_value[name.to_sym] = {}
      detail_option.all('.product-detail-radio', visible: false).each do |option|
        key = option.first('input', visible: false)['value']
        value = option.first('label', visible: false).text.strip
        options_value[name.to_sym][key.to_sym] = value
      end
    end
    pp options_value

    skus = []
    skus_in_div = page.all('.product-price.js_shop_param_price.shop_param_price.shop-item-price', visible: false)
    if skus_in_div.present?
      skus_in_div.each do |sku_div|
        sku = {
          param2: nil,
          param3: nil,
          param4: nil,
          param6: nil
        }
        sku[:code] = get_code
        sku[:opt_price] = sku_div.first('span', visible: false)['summ']
        sku[:price] = page.first('.text-marked .site_dynamic').text
                        .gsub(/(Рекомендованная розничная цена )|(. Не поставляется в интернет-магазины.)/,'').strip rescue nil
        list_options_name.each do |option_name|
          key = sku_div[option_name]
          sku[option_name.to_sym] = options_value[option_name.to_sym][key.to_sym] rescue nil
        end
        skus << sku
      end
    else
      skus << {
        param2: nil,
        param3: nil,
        param4: nil,
        param6: nil
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
    tabs = doc.css('.tabs_section.type_more .row.char_inner_wrapper .col-md-12')
    tabs.each do |tab|
      if tab.at('h4').text == 'Характеристики'
        trs = tab.css('.char_block tr')
        trs.each do |tr|
          tds = tr.css('td')
          result << "#{tds[0].text.strip}: #{tds[1].text.strip}"
        end
      end
    end
    result.join(' --- ')
  end

  def get_desc(doc)
    result = []
    doc.css('.product-desc').each do |desc|
      result << desc.inner_html
    end
    result.join(' ')
  end

  def create_and_get_url_file(link)

    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    link_name = {
      name: link.split('/').last,
      link: link
    }
    new_src = ''
    data = 	{"file": {"src": link_name[:link]}}
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

        page = 1
        loop do
          list_resp = RestClient.get "http://"+api_key+":"+password+"@"+domain+"/admin/files.json?page=#{page}&per_page=250}"
          sleep 0.5
          list_data = JSON.parse(list_resp)

          list_data.each do |ld|
            check = ld['absolute_url'].split('/').last.to_s
            new_src = ld['absolute_url'] if check == link_name[:name]
          end
          break if list_data.count < 250 || !new_src.empty?
          page += 1
        end
      else
        response.return!(&block)
      end
    }
    new_src
  end
end
