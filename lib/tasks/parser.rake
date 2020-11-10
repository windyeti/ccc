# require 'capybara/dsl'
# include Capybara::DSL

namespace :product do


  task start: :environment do
    get_category(Category.first)
  end

  def get_category(category)
    category.subordinates.each do |subordinate|
      path_current_category = subordinate.category_path
      link = subordinate.link

      # GUARD
      p "GUARD --> #{subordinate.parsing}"
      next if subordinate.parsing

      get_category(subordinate)

      Rake::Task['product:get_product_links'].invoke(link, path_current_category)
      Rake::Task['product:get_product_links'].reenable

      # subordinate.update(parsing: true)
    end
  end

  task :get_product_links, [:category_url, :category_path_name] => :environment do |_t, args|
    category_url = args[:category_url]
    category_path_name = args[:category_path_name]
    product_urls = []

    doc = get_doc(category_url)

    product_urls += doc.css('.product-layout .product-thumb .image .imgan').map {|product| product['href']}

    if doc.css('.july-pagination .text-left .pagination').present?
      pagination_links_count = doc.css('.july-pagination .text-left .pagination li a').last['href'].split('=').last.to_i

      (2..pagination_links_count).each do |count|
        p url = "#{category_url}page#{count}/"
        doc = get_doc(url)
        product_urls += doc.css('.product-layout .product-thumb .image .imgan').map {|product| product['href']}
      end
    end
    Rake::Task['product:get_product'].invoke(product_urls, category_path_name)
    Rake::Task['product:get_product'].reenable
  end

  task :get_product, [:products_urls_in_category, :category_path_name] => :environment do |_t, args|
    p '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
    p category_path_name = args[:category_path_name]
    p args[:products_urls_in_category].size
    p '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
    # args[:products_urls_in_category].each do |product_link|
    #   p "START <<<< начали собирать данные по продукту #{product_link}"
    #
    #   @tovs = tovs_with_link(product_link)
    #
    #     if @tovs.present?
    #       p '==== UPDATE ===='
    #       next if @tovs.first.p4.split(' ## ').include?(category_path_name)
    #       update_product(@tovs, category_path_name)
    #     else
    #       data = {
    #         product_link: product_link,
    #         category_path_name: category_path_name
    #       }
    #       create_product(data)
    #     end
    # p "END <<<< закончили собирать данные на продукт:: #{product_link}"
    # end
    # p "Total: #{Tov.count}"
  end

  def tovs_with_link(product_link)
    Tov.where(link: product_link)
  end

  def update_product(tovs, category_path_name)
    tovs.each do |tov|
      if tov.update(p4: "#{tov.p4} ## #{category_path_name}")
        p "---- update товара #{tov.fid} -- p4: #{tov.p4} -- всего: #{Tov.count}}"
      else
        p "!!!!ОШИБКА UPDATE!!!!! товара #{tov.fid} -- TIME: #{Time.now}"
      end
    end
  end

  def create_product(data)
    doc = get_doc data[:product_link]

    title = doc.at('h1').text.strip rescue nil
    desc = get_desc(doc)
    sdesc = nil
    categories = data[:category_path_name].split('/')
    # mtitle = doc.at('title').text.strip rescue nil
    # mdesc = doc.at('meta[name="description"]')['content'] rescue nil
    # mkeyw = doc.at('meta[name="keywords"]')['content'] rescue nil

    skus = get_skus(data[:product_link])
    skus.each do |sku|

      option1 = sku[:param2]
      option2 = sku[:param3]
      option3 = sku[:param4]
      option4 = sku[:param6]

      codes = sku[:code].gsub(' ', '').gsub('/', ',').gsub(';', ',').split(',') rescue [nil]

      codes.each do |code|
        price = get_price_from_file(code)
        sku[:price] = price if price.present?

        unless CheckNumber.is_number? sku[:price]
          sku[:price] = 0
        end

        if codes.size > 1
          title_code = "#{title}__#{code}"
        else
          title_code = title
        end

        @tov = Tov.new(
          {
            fid: "#{data[:product_link]}__#{sku[:param2]}__#{sku[:param3]}__#{sku[:param4]}__#{sku[:param5]}__#{code}",
            sku: code,
            title: title_code,
            sdesc: sdesc,
            desc: desc,
            price: sku[:price],
            oldprice: sku[:opt_price],
            pict: get_images(doc),
            p4: data[:category_path_name],
            link: data[:product_link],
            cat: categories[1],
            cat1: categories[2],
            cat2: categories[3],
            cat3: categories[4],
            mtitle: nil,
            mdesc: nil,
            mkeyw: nil,
            option1: option1,
            option2: option2,
            option3: option3,
            option4: option4
          }
        )
        if @tov.save
          p "+++++ создан товар #{@tov.sku} -- всего: #{Tov.count}"
        else
          p "!!!!ОШИБКА!!!!! товара #{@tov.sku}"
        end
        @tov = nil
      end
    end
  end
end
