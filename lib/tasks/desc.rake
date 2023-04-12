namespace :desc do

  task create: :environment do
    doc = File.open("#{Rails.public_path}/desc.txt") { |f| Nokogiri::HTML(f, nil, 'utf-8') }
    new_desc = get_desc(doc)
    File.open("#{Rails.public_path}/new_desc.txt", "a+") { |f| f.write new_desc }
  end
end
