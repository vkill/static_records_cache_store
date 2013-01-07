#static_records_cache_store

static_records_cache_store is a cache ActiveModel records plugin for Rails3.

* https://github.com/vkill/static_records_cache_store

##Supported versions

* Ruby 1.9.x

* Rails 3.x


##Installation

In your app's `Gemfile`, add:

    gem "static_records_cache_store"


##Initializer

In `config/initializers/static_records_cache_store.rb`

    if defined?(::StaticRecordsCacheStore)
      
      ::StaticRecordsCacheStore.register_store :file, 
                      ActiveSupport::Cache.lookup_store(:file_store, Rails.root.join("tmp/records_cache"))

      if ::Rails.env.development? or ::Rails.env.test?
        ::StaticRecordsCacheStore.register_store :shared,
                      ActiveSupport::Cache.lookup_store(:file_store, Rails.root.join("tmp/records_cache"))
      else
        ::StaticRecordsCacheStore.register_store :shared, ::Rails.cache
      end

      ::StaticRecordsCacheStore.configure do |config|
        config.enable = true
      end
      
    end

##Usage

For example, cache Card objects:

    class Card < ActiveRecord::Base
      static_records_cache_store :keys => [:id, :code], :store => :shared
    end

    class UserCard < ActiveRecord::Base
      belongs_to :card, :read_from_cache => true
    end

Then it will fetch cached object in this situations:

    Card.find(1)
    Card.find(1, 2, 3)
    Card.find_by_id(1)
    Card.find_by_code(:code)
    user_card.card

When card create/update then write/rewrite cache.

When card destroy then delete cache.

##Copyright

Copyright (c) 2012 vkill.net .

