namespace :errors do
  task csv: :environment do
    rows = CSV.read("#{Rails.public_path}/product_output.csv", headers: true)
    rows_log = File.readlines("#{Rails.public_path}/log.txt")

    CSV.open("#{Rails.public_path}/product_output_errors.csv", "a+") do |csv|
      csv << rows.first.to_hash.keys
      rows_log.each do |row_log|
        row_num = row_log.match(/^\d+/)[0]
        new_row = rows[row_num.to_i - 2]
        error_url = row_log.match(/"(.+)"/).captures[0]
        right_url = get_url(error_url)
        new_row["Изображения"] = right_url
        csv << new_row
      end
    end
  end

  def get_url(url)
    url = if url.match(/\.jpeg\.jpg$/)
            url.gsub(/\.jpeg\.jpg$/, ".jpeg")
          elsif url.match(/\.jpg$/)
            url.gsub(/\.jpg$/, ".jpeg")
          else
            url
          end
    url
  end
end
