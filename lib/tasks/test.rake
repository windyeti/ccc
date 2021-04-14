namespace :p do

  # require 'capybara/dsl'
  # include Capybara::DSL

  task t: :environment do

    # print_category(Category.first, 0)


    #
    # p get_doc(link).at('.ty-product-block__sku').at('.ty-sku-item')['id'].split('_').last
    # p get_doc(link).at('.ty-product-block__button .ty-btn__add-to-cart')['id'].split('_').last.to_i
    # p get_images(get_doc(link))
    # doc = get_doc link
    # result = []
    # props = doc.css('#content_features .ty-product-feature')
    # props.each do |prop|
    #   name = prop.at('.ty-product-feature__label').text.gsub(/:$/,'')
    #   value = prop.at('.ty-product-feature__value')
    #             .text
    #             .split(',')
    #             .map { |v| v.strip }
    #             .join(' ## ')
    #   result << "#{name}: #{value}"
    # end
    # p result.join(' --- ')

    # link = "http://smart52.ru/telefony/realme/realme-7-8-128gb-mirror-silver-ru.html"
    # p get_doc(link).at('.ty-price-num').text.gsub(' ', '')
    # p get_doc(link).at('.ty-price-num').text.split(' ')

    #
    # doc = get_doc(link).at('#content_description')
    # doc.css("img").each do |img|
    #   link_img = img['src'].split('?').first
    #   img.attributes["src"].value = create_and_get_url_file(link_img, link)
    # end
    # File.open("#{Rails.public_path}/___image___.html", 'w') do |f|
    #   f.write doc.to_html
    # end

    #
    # # Rake::Task['product:get_product'].invoke([link], 'asdasdasd/asdasdasd')
    #
    # doc = get_doc(link)
    # selector_top_level = '.ty-mainbox-body .ty-subcategories__item a'
    # doc.css(selector_top_level).each do |a|
    #   p a['href']
    # end
    #
    # pp get_skus(link)

#     script = get_doc(link).css('script').find do |script|
#       script.text.include?('var poip_images = ')
#     end
#     pp json = script.text.split('poip_images = ')[1].split("var poip_product_option_ids")[0].strip.split('var poip_images_by_options = ')
# File.write("#{Rails.public_path}/json.txt", json)
#     pp eval(json[0])
#     pp eval(json[1])

    # pp eval(script.text.split('var poip_images = ')[1].split("var poip_product_option_ids")[0])
    # pp eval(script.text.split('var poip_images = ')[1])

    # get_doc(link).css('#content .row.grid-july .product-layout .product-thumb .image > a').each do |c|
    #   p c['href']
    # end

    # visit link
    # page.all('#content .row.grid-july .product-layout .product-thumb .image > a').each do |c|
    #   p c['href']
    # end

    link = "http://smart52.ru/aksessuary/avtomobilnye-aksessuary/videoregistratory/videoregistrator-xiaomi-70mai-dash-cam-1s-midrive-d06.html"
    doc = get_doc(link)
    p get_quantity(doc)

    link = "http://smart52.ru/aksessuary/naushniki-i-kolonki/besprovodnye-naushniki-qcy-t7-white.html"
    doc = get_doc(link)
    p get_quantity(doc)


    # p images(doc)
  end

  def get_quantity(doc)
    block = doc.at('.ty-control-group.product-list-field .ty-qty-out-of-stock.ty-control-group__item')
    '0' if block.present? && block.text == 'Предзаказ'
  end

  # def images(doc)
  #   if doc.css('.ty-product-block__img-wrapper .ty-product-thumbnails img').size > 0
  #     p '1'
  #     p doc.css('.ty-product-block__img-wrapper .ty-product-thumbnails img')
  #     doc.css('.ty-product-block__img-wrapper .ty-product-thumbnails img').map do |image|
  #       image['src'].gsub('/thumbnails/35/35','')
  #     end.join(' ')
  #   elsif doc.at('.ty-product-img').at('.ty-pict')
  #     p '2'
  #     doc.at('.ty-product-img').at('.ty-pict')['src']
  #   else
  #     p '3'
  #     nil
  #   end
  # end

  # def print_category(category, n)
  #   space = if n == 0
  #             ''
  #           elsif n == 1
  #             '  '
  #           elsif n == 2
  #             '    '
  #           elsif n == 3
  #             '      '
  #           end
  #   p "#{space}#{category.name}"
  #   m = n + 1 if category.subordinates.present?
  #   category.subordinates.each do |subordinate|
  #     print_category(subordinate, m)
  #   end
  # end

  # task tt: :environment do
  #   w = Writer.new
  #   w.write
  #   a = Array.new
  #   a.to_be_writer
  # end

  end
