namespace :client do
  task create: :environment do
    already_id = []
    rows = CSV.read("#{Rails.public_path}/shop.csv", headers: true)
    rows.each do |row|
      fid = row["Параметр: fid"]
      id = row["ID товара"]
      tov = Tov.find_by(fid: fid)
      unless already_id.include?(tov.id)
        tov.reviews.each {|client| api_create_client(client, id)}
        already_id << tov.id
      end
    end

  end

  def api_create_client(client, id)
    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    p data = {
      client: {
        name: client[:name],
        surname: client[:surname],
        middlename: client[:middlename],
        registered: true,
        email: client[:email],
        "password": "123456",
        "phone": "+71111111111",
        "type": "Client::Individual",
        "fields_values_attributes": [
          {
            "field_id": 183,
            "value": "text"
          }
        ]
      }
    }

    url_api_category = "http://#{api_key}:#{password}@#{domain}/admin/clients.json"

    RestClient.post( url_api_category, data.to_json, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      sleep 1
      case response.code
      when 201
        p 'code 201 - ok'
      when 422
        p 'code 422'
        pp JSON.parse(response.body)
        # File.open("#{Rails.public_path}/errors_update.txt", 'a') do |file|
        #   file.write "#{id}\n"
        # end
      else
        response.return!(&block)
      end
    end
  end
end
