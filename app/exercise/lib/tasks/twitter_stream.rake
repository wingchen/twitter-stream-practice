require 'tweetstream'
require 'elasticsearch'

namespace :twitter_stream do
  desc "Consume data from twitter stream API and index them into elasticsearch"
  task consume: :environment do
    client = Elasticsearch::Client.new log: true

    TweetStream.configure do |config|
      config.consumer_key       = 'ey7yFngSDkz1pKCIQv86BoZdX'
      config.consumer_secret    = '7AHQk0IYqjXwgHaDVYzWIMKadtFaugQw5o4dhWmeyyRFrPiUIG'
      config.oauth_token        = '43825244-GqDeQXgMLTyYN5vVl2QKoFWFxop3TCT040zVFyNV0'
      config.oauth_token_secret = 'E8smcQdZ5Fimn3usiOv0XKmIXHMb5oHdKKDSeIEhxAvqY'
      config.auth_method        = :oauth
    end

    TweetStream::Client.new.sample do |status|
      # only deal with ones with geo info
      if status.coordinates?
        payload = {}
        payload[:tweet_id] = status.id
        payload[:text] = status.text
        payload[:user] = status.user.gguesa
        payload[:created_at] = status.created_at
        payload[:profile_image_url] = status.user.profile_image_url

        hashtags = status.entities.hashtags.map { |h| h.text }
        payload[:hashtags] = hashtags

        payload[:location] = status.coordinates.coordinates

        client.index  index: 'banjo', type: 'tweets', id: payload[:tweet_id], body: payload
      end
    end
  end

end
