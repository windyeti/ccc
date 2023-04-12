# require 'capybara/dsl'
# include Capybara::DSL

namespace :product do

  task start: :environment do
    @agent = Mechanize.new
    get_category(Category.first)
  end

  def get_category(category)
    p "GUARD --> #{category.parsing}"
    p category.name
    return if category.parsing

    category.subordinates.order(:id).each do |subordinate|
      get_category(subordinate)
    end

    Rake::Task['product:get_product_links'].invoke(category.link, category.category_path)
    Rake::Task['product:get_product_links'].reenable
    # category.update(parsing: true)
  end

  task :get_product_links, [:category_url, :category_path_name] => :environment do |_t, args|
    p category_url = /\/$/.match(args[:category_url]) ? args[:category_url] : "#{args[:category_url]}/"
    category_path_name = args[:category_path_name]

    selector = ".t-store__grid-cont .t-store__card > a"
    visit category_url
    sleep 2

    button = find(".t-store__load-more-btn") rescue nil

    if button.present?
      loop do
        button.click
        sleep 1
        button = find(".t-store__load-more-btn") rescue nil
        break if button.nil?
        p button.text
      end
    end
    product_urls = all(selector).map {|a| a['href']}

# p product_urls
# p product_urls.count
# p Category.find_by(category_path: category_path_name).update(amount: product_urls.count)
    Rake::Task['product:get_product'].invoke(product_urls, category_path_name)
    Rake::Task['product:get_product'].reenable
  end

  task :get_product, [:products_urls_in_category, :category_path_name] => :environment do |_t, args|
    category_path_name = args[:category_path_name]
    args[:products_urls_in_category].each do |product_link|

      p "START <<<< начали собирать данные по продукту #{product_link}"
      fid = product_link
      tovs = Tov.where(fid: fid)

      if tovs.present?
        choose_type_update(tovs, product_link, category_path_name)
      else
        File.open("#{Rails.public_path}/not_tov.txt","a+") {|f| f.write("#{product_link} ---- ")}
      end
      p "FINISH <<<< начали собирать данные по продукту #{product_link}"
      next

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
    tov = Tov.new(data)
    if tov.save
    else
      p "!!!!ОШИБКА!!!!! товара #{tov.fid}"
    end
  end

  def choose_type_update(tovs, product_link, category_path_name)
    if tovs.first.cat.present?
      update_only_p4(tovs, category_path_name)
    else
      update_first_time(tovs, product_link, category_path_name)
    end
  end

  def update_only_p4(tovs, category_path_name)
    tovs.each do |tov|
      p '==== UPDATE ===='
      next if tov.p4.split(' ## ').include?(category_path_name)
      update_product(tov, category_path_name)
    end
  end

  def update_first_time(tovs, product_link, category_path_name)
    begin
      page = @agent.get(product_link)
    rescue
      retry
    end
    mtitle = page.at('title').text
    mdesc = page.at('meta[name="description"]')['content'] rescue nil

    tovs.each do |tov|
      p '++++++ UPDATE ++++++'
      categories = category_path_name.split('/')
      p data = {
        p4: category_path_name,
        cat: categories[1],
        cat1: categories[2],
        cat2: categories[3],
        cat3: categories[4],
        cat4: categories[5],
        mtitle: mtitle,
        mdesc: mdesc,
        check: true
      }
      tov.update(data)
    end
  end

end
