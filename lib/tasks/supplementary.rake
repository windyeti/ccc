namespace :supplementary do
  task start: :environment do
    rows = CSV.read("#{Rails.public_path}/shop.csv", headers: true)
    rows.each do |row|
      id = row["ID товара"]
      tov = Tov.find_by(fid: row["Параметр: fid"])
      links = tov.option3.split(" ")
      ids = rows.select { |row| links.include?(row["Параметр: fid"]) }
              .map {|row| row["ID товара"].to_i}.uniq
      api_supplementary(id, ids) if ids.present?
    end
  end

  def api_supplementary(id, ids)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/products/#{id}/supplementaries.json"

    p data = {
      "supplementary_ids": ids
    }

    RestClient.post( url_api_category, data.to_json, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      case response.code
      when 200
        p 'code 200 - ok'
        sleep 1
      when 422
        p 'code 422'
        File.open("#{Rails.public_path}/errors_update_similars.txt", 'a') do |file|
          file.write "#{id}\n"
        end
      else
        response.return!(&block)
      end
    end
  end
end
