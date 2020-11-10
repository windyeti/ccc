require 'csv'

class Services::CreateCsvWithParams
  PRODUCT_STRUCTURE = {
    fid: 'Параметр: fid',
    sku: 'Артикул',
    title: 'Название товара',
    sdesc: 'Краткое описание',
    desc: 'Полное описание',
    price: 'Цена продажи',
    oldprice: 'Старая цена',
    pict: 'Изображения',
    p4: 'Размещение на сайте',
    link: 'Параметр: OLDLINK',
    cat: 'Подкатегория 1',
    cat1: 'Подкатегория 2',
    cat2: 'Подкатегория 3',
    cat3: 'Подкатегория 4',
    mtitle: 'Тег title',
    mdesc: 'Мета-тег description',
    mkeyw: 'Мета-тег keywords',
    option1: 'Свойство: Размер',
    option2: 'Свойство: Капюшон',
    option3: 'Свойство: Возраст',
    option4: 'Свойство: Декоративные элементы'
  }.freeze

    def self.call
      @file_path_prep = "#{Rails.public_path}"+'/product_prep.csv'
      @file_name_output = "#{Rails.public_path}"+'/product_output.csv'

      @tovs = Tov.order(:id)

      check_previous_files_csv

      create_csv_prep(PRODUCT_STRUCTURE)

      additions_headers = get_additions_headers

      product_hashs = get_product_hashs

      all_column_names = add_column_names(product_hashs, additions_headers)

      csv_with_full_headers(product_hashs, all_column_names)

      create_csv_output
  end



  private

  def self.check_previous_files_csv
    check = File.file?("#{@file_path_prep}")
    if check.present?
      File.delete("#{@file_path_prep}")
    end
    check = File.file?("#{@file_path_output}")
    if check.present?
      File.delete("#{@file_path_output}")
    end
  end

  def self.create_csv_prep(product_hash_structure)
    CSV.open(@file_path_prep, 'w') do |writer|
      writer << product_hash_structure.values

      @tovs.each do |tov|
        product_properties = product_hash_structure.keys
        product_properties_amount = product_properties.map do |property|
          tov.send(property)
        end
        writer << product_properties_amount
      end
    end
  end

  def self.get_additions_headers
    result = []
    p = @tovs.select(:p1)
    p.each do |p|
      if p.p1 != nil
        p.p1.split('---').each do |pa|
          result << pa.split(':')[0].strip if pa != nil
        end
      end
    end
    result.uniq
  end

  def self.get_product_hashs
    CSV.read(@file_path_prep, headers: true).map do |product|
      product.to_hash
    end
  end

  def self.add_column_names(product_hashs, addHeaders)
    result = []
    column_names = product_hashs.first.keys
    result += column_names
    addHeaders.each do |addH|
      additional_column_names = ['Параметр: '+addH]
      result += additional_column_names
    end
    result
  end

  def self.csv_with_full_headers(product_hashs, all_column_names)
    csv_file_with_addition_headers = CSV.generate do |csv|
      csv << all_column_names
      product_hashs.each do |product_hash|
        values = product_hash.values
        csv << values
      end
    end
    File.write(@file_path_prep, csv_file_with_addition_headers)
  end

  def self.create_csv_output
    CSV.open(@file_name_output, "w") do |csv_out|
      rows = CSV.read(@file_path_prep, headers: true).collect do |row|
        row.to_hash
      end
      column_names = rows.first.keys
      csv_out << column_names
      CSV.foreach(@file_path_prep, headers: true ) do |row|
        fid = row[0]
        vel = Tov.find_by_fid(fid)
        if vel != nil
# 				puts vel.id
          if vel.p1.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
            vel.p1.split('---').each do |vp|
              key = 'Параметр: '+vp.split(':')[0].strip
              value = vp.split(':')[1].remove('.') if vp.split(':')[1] !=nil
              row[key] = value
            end
          end
        end
        csv_out << row
      end
    end
  end
end
