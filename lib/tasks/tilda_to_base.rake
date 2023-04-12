namespace :tilda_to_base do
  task create: :environment do
    @rows_tilda = CSV.read("#{Rails.public_path}/tilda.csv", headers: true)
    @rows_tilda.each do |row|
      # берем только главные, а не варианты
      next if row['Parent UID'].present?
      p '----------------------------------------'

      tilda_uid = row['Tilda UID'] # для каждого варианта пишем уникальный UID
      row_vars = @rows_tilda.select {|row| row['Parent UID'] == tilda_uid}

      sku = row['SKU']
      fid = row['Url'].remove(/\?.+$/)

      p1 = []
      p1 << "Бренд: #{row['Brand']}" if row['Brand'].present?
      p1 << "Метка: #{row['Mark']}" if row['Mark'].present?
      row.each do |key,value|
        if key.match(/^Characteristics:/)
          name = key.split(":")[0]
          p1 << "#{name}: #{value}"
        end
      end

      link = row['Url']
      p4_admin = row['Category'].nil? ? "Каталог/Admin/NoCategory" : row['Category'].split(";").map {|cat| "Каталог/Admin/#{cat}"}.join(" ## ")
      title = get_title(row['Title'])
      sdesc = row['Description']
      desc = row['Text']
      pict = row['Photo']
      price = row['Price'] ? row['Price'] : "0"
      oldprice = row['Price Old']
      quantity = row['Quantity']

      data = {
        fid: fid,
        sku: sku,
        title: title,
        price: price,
        oldprice: oldprice,
        sdesc: sdesc,
        desc: desc,
        pict: pict,
        quantity: quantity,
        p1: p1.join(" --- "),
        link: link,

        uid: tilda_uid,
        p4_admin: p4_admin,
      }

      if row_vars.present?
        row_vars.each do |row_var|
          row_var['Editions'].split(";").each do |prop|
            arr = prop.split(":")
            data[:option1] = arr[1] if arr[0] == "Размер кроп-топа"
            data[:option2] = arr[1] if arr[0] == "Размер леггинсов"
            data[:option3] = arr[1] if arr[0] == "Размер топа"
            data[:option4] = arr[1] if arr[0] == "Размер велосипедок"
            data[:option5] = arr[1] if arr[0] == "Цвет"
            data[:option6] = arr[1] if arr[0] == "Размер"
            data[:option7] = arr[1] if arr[0] == "Номинал сертификата"
            data[:option8] = arr[1] if arr[0] == "Размер низа"
            data[:option9] = arr[1] if arr[0] == "Размер верха"
            data[:option10] = arr[1] if arr[0] == "Цвет лонгслива"
            data[:option11] = arr[1] if arr[0] == "Сопротивление фитнес резинки"
            data[:option12] = arr[1] if arr[0] == "Цвет футболки"
            data[:option13] = arr[1] if arr[0] == "Цвет комплекта"
            data[:option14] = arr[1] if arr[0] == "Цвет топа"
          end

          data[:sku] = row_var['SKU']
          data[:photo_var] = row_var['Photo'] # Изображения варанта
          data[:uid] = row_var['Tilda UID'] # для каждого варианта пишем уникальный UID
          data[:price] = row_var['Price'] ? row_var['Price'] : "0"
          data[:oldprice] = row_var['Price Old']
          data[:quantity] = row_var['Quantity']
          data[:link] = row_var['Url']

          p '++++++++++'
          # pp data
          Tov.create!(data)
        end
      else
        # pp data
        Tov.create!(data)
      end
    end
  end

  task p4_empty: :environment do
    Tov.all.each do |tov|
      if tov.p4.nil?
        categories = tov.p4_admin.split(" ## ").first.split('/')
        tov.update(
          p4: tov.p4_admin,
          cat: categories[1],
          cat1: categories[2],
          cat2: categories[3],
          cat3: categories[4],
          cat4: categories[5],
          )
      end
    end
  end

  task option_uniq: :environment do
    @rows_tilda = CSV.read("#{Rails.public_path}/tilda.csv", headers: true)
    result = []
    @rows_tilda.each do |row|
      next if row['Editions'].nil?
      row['Editions'].split(";").each do |param|
        result << param.split(":")[0]
      end
    end
    p result.uniq
  end

  def get_vars(row_main)
    @rows_tilda.select {|row| row['Parent UID'] == row_main['Tilda UID']}
  end
end
