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
      p subordinate.name
      next if subordinate.parsing

      get_category(subordinate)

      Rake::Task['product:get_product_links'].invoke(link, path_current_category)
      Rake::Task['product:get_product_links'].reenable

      subordinate.update(parsing: true)
    end
  end

  task :get_product_links, [:category_url, :category_path_name] => :environment do |_t, args|
    category_url = /\/$/.match(args[:category_url]) ? args[:category_url] : "#{args[:category_url]}/"
    category_path_name = args[:category_path_name]

    doc = get_doc(category_url)

    pagination = doc.at('.ty-pagination')

    if pagination
      number = pagination.css('a').last['data-ca-page'].to_i
      product_urls = doc.css('.grid-list .ty-grid-list__item .product-title').map {|a| a['href']}
      (2..number).each do |page|
        p pagianation_url = "#{category_url}page-#{page}"
        doc_pagianation = get_doc(pagianation_url)
        product_urls += doc_pagianation.css('.grid-list .ty-grid-list__item .product-title').map {|a| a['href']}
      end
    else
      product_urls = doc.css('.grid-list .ty-grid-list__item .product-title').map {|a| a['href']}
    end
    Rake::Task['product:get_product'].invoke(product_urls, category_path_name)
    Rake::Task['product:get_product'].reenable
  end

  task :get_product, [:products_urls_in_category, :category_path_name] => :environment do |_t, args|
    category_path_name = args[:category_path_name]
    args[:products_urls_in_category].each do |product_link|

      p "START <<<< начали собирать данные по продукту #{product_link}"
      begin
        doc = get_doc(product_link)
      rescue
        p "Нет такой страницы #{product_link}"
        next
      end

      fid = doc.at('.ty-product-block__sku').at('.ty-sku-item')['id'].split('_').last

      tov = Tov.find_by(fid: fid)

        if tov.present?
          p '==== UPDATE ===='
          next if tov.p4.split(' ## ').include?(category_path_name)
          update_product(tov, category_path_name)
        else
          data = {
            product_link: product_link,
            category_path_name: category_path_name,
            fid: fid
          }
          create_product(data)
        end
    p "END <<<< закончили собирать данные на продукт:: #{product_link}"
    end
    p "Total: #{Tov.count}"
  end

  def update_product(tov, category_path_name)
    if tov.update(p4: "#{tov.p4} ## #{category_path_name}")
      p "---- update товара #{tov.fid} -- p4: #{tov.p4} -- всего: #{Tov.count}}"
    else
      p "!!!!ОШИБКА UPDATE!!!!! товара #{tov.fid} -- TIME: #{Time.now}"
    end
  end

  def create_product(data)
    doc = get_doc(data[:product_link])

    title = doc.at('.ty-product-block-title').text.strip
    desc = get_desc(doc, data[:fid], data[:product_link])
    price = doc.at('.ty-price-num').text.strip.gsub(' ', '')
    props = get_props(doc)
    images = get_images(doc)
    quantity = get_quantity(doc)
    categories = data[:category_path_name].split('/')
    mtitle = doc.at('title').text.strip rescue nil
    mdesc = doc.at('meta[name="description"]')['content'] rescue nil
    mkeyw = doc.at('meta[name="keywords"]')['content'] rescue nil

    tov = Tov.new(
    {
      fid: data[:fid],
      sku: nil,
      title: title,
      sdesc: nil,
      desc: desc,
      price: price,
      oldprice: nil,
      pict: images,
      quantity: quantity,
      p1: props,
      p4: data[:category_path_name],
      link: data[:product_link],
      cat: categories[1],
      cat1: categories[2],
      cat2: categories[3],
      cat3: categories[4],
      cat4: categories[5],
      mtitle: mtitle,
      mdesc: mdesc,
      mkeyw: mkeyw
      }
    )
    if tov.save
      pp tov
      p "+++++ создан товар #{tov.fid} -- всего: #{Tov.count}"
    else
      p "!!!!ОШИБКА!!!!! товара #{tov.fid}"
    end
  end
end
