namespace :csv do

  # task cat: :environment do
  #   Tov.all.each do |tov|
  #     p4 = tov.p4.gsub("NoMegre", "Admin")
  #     p4_admin = tov.p4_admin.gsub("NoMegre", "Admin")
  #     cat = tov.cat == "NoMegre" ? "Admin" : tov.cat
  #     tov.update(
  #       p4: p4,
  #       p4_admin: p4_admin,
  #       cat: cat,
  #       )
  #   end
  # end

  task create: :environment do
    @count = 0
    file_path = "#{Rails.public_path}/product_output_mc.csv"
    FileUtils.rm_rf(file_path)
    rows_shop = CSV.read("#{Rails.public_path}/shop.csv", headers: true)

    CSV.open(file_path,"a+") do |csv|
      csv << rows_shop.first.to_hash.keys
      rows_shop.each do |row_shop|
        sku = row_shop['Артикул']

        tov = Tov.find_by(title: row_shop['Название товара или услуги'])

        if tov.present?
          p '----------------------------------------'
          row_shop['Параметр: fid'] = tov.fid # для каждого варианта пишем уникальный UID
          row_shop['Параметр: Метка'] = tov.p1.split(" --- ").find {|param| param.include?("Метка")}.split(": ")[1] if tov.p1.include?("Метка")
          row_shop['Параметр: OLDLINK'] = tov.fid
          row_shop['Размещение на сайте'] = tov.p4
          row_shop['Краткое описание'] = tov.sdesc
          row_shop['Полное описание'] = tov.desc

          row_shop['Тег title'] = tov.mtitle
          row_shop['Мета-тег keywords'] = tov.mkeyw
          row_shop['Мета-тег description'] = tov.mdesc

          row_shop['Изображения'] = tov.pict
          row_shop['Ссылка на видео'] = tov.video
          
          tov.update(check: true)
          csv << row_shop
          p @count += 1

        elsif Tov.where(sku: sku).present? && sku.present?
          tovs = Tov.where(sku: sku)
          if tovs.present?
            p '++++++++++++++++++++++++++++++++++++++++'
            picts = []
            videos = []
            tovs.each do |tov|
              picts += tov.pict.split(" ") if tov.pict.present?
              videos += tov.video.split(" ") if tov.video.present?

              tov.update(check: true)
            end

            row_shop['Параметр: fid'] = tovs.first.fid # для каждого варианта пишем уникальный UID
            row_shop['Параметр: Метка'] = tovs.first.p1.split(" --- ").find {|param| param.include?("Метка")}.split(": ")[1] if tovs.first.p1.include?("Метка")
            row_shop['Параметр: OLDLINK'] = tovs.first.fid
            row_shop['Размещение на сайте'] = tovs.first.p4
            row_shop['Краткое описание'] = tovs.first.sdesc
            row_shop['Полное описание'] = tovs.first.desc

            row_shop['Тег title'] = tovs.first.mtitle
            row_shop['Мета-тег keywords'] = tovs.first.mkeyw
            row_shop['Мета-тег description'] = tovs.first.mdesc

            row_shop['Изображения'] = picts.uniq.join(" ")
            row_shop['Ссылка на видео'] = videos.uniq.join(" ")

            csv << row_shop
            p @count += 1
            else
              next
            end
          end
        end
      end
    end
end
