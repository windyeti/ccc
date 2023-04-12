namespace :p do

  # require 'capybara/dsl'
  # include Capybara::DSL

  task t: :environment do
    link = "https://mpolis-pro.ru/catalog/trotuarnaya-plitka/vibropressovannaya-trotuarnaya-plitka/trotuarnaya-plitka-braer-domino-60-mm-color-mix-plato/"
    doc = get_doc(link)
    selector_other_level = '.detail_slider__item a'
    # selector_other_level = '.slick-track .detail_slider__item a'
    p doc.css(selector_other_level).map {|a| a['href']}
  end

  task ttt: :environment do
    link = "https://define.moscow/tproduct/359818527-623262259851-komplekt-new-day-black-legginsi-c-topom"
    # link = "https://define.moscow/weekoffer/tproduct/392303695-225510471241-legginsi-new-way-bordo"
    # doc = get_doc(link)
    visit link
    sleep 3
    p mtitle = doc.at('title').text.strip rescue nil
    p mdesc = doc.at('meta[name="description"]')['content'] rescue nil
    p mkeyw = doc.at('meta[name="keywords"]')['content'] rescue nil
    p video = all(".t-slds__videowrapper .t-slds__play_icon").map {|div| "https://www.youtube.com/watch?v=" + div['data-slider-video-url']}
  end

  task t4: :environment do
    result = []
    @rows_tilda = CSV.read("#{Rails.public_path}/tilda.csv", headers: true)
    @rows_tilda.each do |row|
      next if row['Editions'].nil?
      result += row['Editions'].split(";").map {|prop| prop.split(":").first}
      result = result.uniq
    end
    p result
  end

  task uniq: :environment do
    a = Tov.all.map(&:title)
    p a.uniq.
      map { | e | [a.count(e), e] }.
      select { | c, _ | c > 1 }.
      sort.reverse.
      map { | c, e | "#{e}:#{c}" }
  end

  task w: :environment do
    @agent = Mechanize.new
    link = "https://onlytrees.wixsite.com/website-3/product-page/%D0%BF%D1%80%D0%BE%D0%B4%D0%B0%D0%B6%D0%B0-%D0%B4%D0%B5%D1%80%D0%B5%D0%B2%D0%B0-%D0%B3%D0%BB%D0%B8%D1%86%D0%B8%D0%BD%D0%B8%D1%8F-%D1%84%D0%B8%D0%BE%D0%BB%D0%B5%D1%82%D0%BE%D0%B2%D0%B0%D1%8F-classic-%D0%B1%D0%B5%D0%BB%D1%8B%D0%B9-%D1%81%D1%82%D0%B2%D0%BE%D0%BB-2-8-%D0%BC"
    page = @agent.get link
    p mtitle = page.at('title').text
    p mdesc = page.at('meta[name="description"]')['content'] rescue nil
  end
end
