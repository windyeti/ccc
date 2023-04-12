namespace :parsing do
  task update_product: :environment do
    products = []
    page = 1
    loop do
      response = api_get_products(page)
      body = JSON.parse(response.body)
      p body.size
      break if body.size == 0
      products += body
      page += 1
    end

    products.each do |product|
      if product["title"].match(/__\d+$/)
        api_update_product(
          id: product["id"],
          title: product["title"].gsub(/__\d+$/,"")
        )
      end
    end
  end

  task redirect: :environment do
    products = []
    page = 1
    page_for_find_OLDLINK = 1
    id_prop_OLDLINK = nil
    loop do
      response = api_get_products(page_for_find_OLDLINK)
      body = JSON.parse(response.body)
      break if body.size == 0
      body.each do |product|
        pp product['properties']
        prop = product['properties'].find {|prop| prop["title"] == "fid"}
        id_prop_OLDLINK = prop["id"] if prop.present?
        break
      end
      break if id_prop_OLDLINK.present?
      page_for_find_OLDLINK += 1
    end

    if id_prop_OLDLINK.nil?
      p "НЕТ Параметра OLDLINK"
      next
    else
      p "Параметр OLDLINK #{id_prop_OLDLINK}"
    end

    CSV.open("#{Rails.public_path}/short_redir.csv", "a+") do |csv|
      loop do
        response = api_get_products(page)
        body = JSON.parse(response.body)
        p body.size
        body.each do |product|
          newlink = "https://#{Rails.application.credentials[:shop][:domain]}/product/" + product["permalink"]
          oldlink = product["characteristics"].find {|char| char["property_id"] == id_prop_OLDLINK}
          oldlink = oldlink.nil? ? nil : oldlink["title"]
          csv << [oldlink, newlink] if oldlink.present?
        end
        break if body.size == 0
        products += body
        page += 1
      end
    end
  end

  def api_get_products(page)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/products.json?per_page=100&page=#{page}"

    RestClient.get( url_api_category )
  end

  def api_update_product(data)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    id = data[:id]

    p data = {
      "product": {
        "title": data[:title]
      }
    }

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/products/#{id}.json"

    RestClient.put( url_api_category, data.to_json, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      sleep 0.5
      case response.code
      when 200
        p 'code 200 - ok'
      when 422
        p 'code 422'
        File.open("#{Rails.public_path}/errors_update.txt", 'a') do |file|
          file.write "#{id}\n"
        end
      else
        response.return!(&block)
      end
    end
  end

  # def find_for_update(insales, my)
  #   no_for_compare = ["Кошелек Horsefeathers TERRY WALLET camo", "Ремень Horsefeathers ARLEN BELT (brushed brown)", "Кошелек Horsefeathers COURTNEY WALLET (ruby)", "Ремень Horsefeathers DUKE BELT (black)", "Ремень Horsefeathers DUKE BELT (brown)", "Ремень Horsefeathers CHAD BELT (port)", "Ремень Horsefeathers DUKE BELT (brown)", "Ремень Horsefeathers DUKE BELT (black)", "Ремень Horsefeathers ARLEN BELT (brushed brown)", "Кошелек Horsefeathers KYLER WALLET (olive)", "Шлем Giro BEVEL Matte Black", "Гайка для кингпина Independent Kingpin Nuts", "Кошелек Horsefeathers KYLER WALLET (olive)", "Гайка для кингпина Independent Kingpin Nuts", "Кеды DC TONIK M SHOE BB2 BLACK/BLACK"]
  #   insales.each do |item_insales|
  #     my.each do |item_my|
  #       correct = false
  #       if item_insales['title'] == item_my.title && !no_for_compare.include?(item_insales)
  #         if item_insales['description'].nil? && item_my.desc.present?
  #           item_insales['description'] = item_my.desc
  #           correct = true
  #         end
  #         if item_insales['images'].empty? && item_my.pict.present?
  #           item_insales['images'] = item_my.pict
  #           correct = true
  #         end
  #
  #         api_update_product(item_insales) if correct
  #         tov = Tov.find(item_my.id)
  #         tov.update(sync: true, keyones: item_insales['product_field_values'][0]['value'])
  #       end
  #     end
  #   end
  # end

  # def compare_arrays(insales, my)
  #   not_compare_count = 0
  #   more_compare = 0
  #   File.open("#{Rails.public_path}/no_compare.txt", "w") do |file|
  #     insales.each do |item_insales|
  #       count_compare = 0
  #       my.each do |item_my|
  #         count_compare += 1 if item_insales[:title] == item_my[:title]
  #       end
  #       if count_compare == 0
  #         file.write "#{item_insales}\n"
  #         # p "НЕТ СОВПАДЕНИЙ (#{not_compare_count += 1}) #{item_insales}"
  #       end
  #       if count_compare > 1
  #         file.write "БОЛЬШЕ ОДНОГО (#{more_compare += 1})(#{count_compare}) #{item_insales}\n"
  #         # p "БОЛЬШЕ ОДНОГО (#{more_compare += 1})(#{count_compare}) #{item_insales}"
  #       end
  #       p ' - round -'
  #     end
  #   end
  #   p not_compare_count
  #   p more_compare
  # end
  task icanread: :environment do
    File.readlines("#{Rails.public_path}/no_image.txt").each do |line|
      hash = eval(line)
      search = hash[:title]
      visit 'http://simpleboardshop.ru'

      fill_in 'keyword', with: search
      click_on 'Поиск'

      sleep 1
      # begin
      # if page.find('h1').text.strip == search
      #   p search
      # end
      # rescue
      #   p '-----'
      # end
      begin
        if page.all('.mod_vm_universal2').size == 0
          p '-2'
        end
      rescue
        p "2222222222 -------- #{search}"
      end
    end
  end
end
