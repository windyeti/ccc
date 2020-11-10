namespace :p do

  # require 'capybara/dsl'
  # include Capybara::DSL

  task t: :environment do

    link = "#{Rails.application.credentials[:shop][:catalog]}"

    visit link
    page.all('#column-left .list-group .cat-active > a').each do |c|
      p c.text
    end
    # Rake::Task['product:get_product'].invoke([link], 'asdasdasd/asdasdasd')
  end

  task tt: :environment do
    w = Writer.new
    w.write
    a = Array.new
    a.to_be_writer
  end

  end
