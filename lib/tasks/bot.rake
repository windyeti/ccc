require 'telegram/bot'

namespace :bot do
  task start: :environment do
    Services::NotificationParsingState.send_message('YeHoHo!!!')
  end
end
