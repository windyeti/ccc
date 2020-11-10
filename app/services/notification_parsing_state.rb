class Services::NotificationParsingState
  def self.send_message(message = nil)
    token = '1351603479:AAH-cz1zdopKAslf8SfWxves7AEOUsNJ8VA'
    chat_id = '346972648'
    Telegram::Bot::Client.run(token) do |bot|
      bot.api.sendMessage(chat_id: chat_id, text: message.nil? ? "ЗАКОНЧИЛИ ПАРСИНГ" : "Спарсили коллекцию #{message}")
    end
  end
end
