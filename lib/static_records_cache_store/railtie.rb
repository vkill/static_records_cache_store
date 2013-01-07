require "static_records_cache_store/active_record_extension"
require "static_records_cache_store/rails_extensions/active_record/associations/builder/belongs_to"
require "static_records_cache_store/rails_extensions/active_record/associations/belongs_to_association"

module StaticRecordsCacheStore
  class Railtie < ::Rails::Railtie

    initializer 'static_records_cache_store' do |app|
      ActiveSupport.on_load :active_record do
        include ::StaticRecordsCacheStore::ActiveRecordExtension
      end

      ::ActiveRecord::Associations::BelongsToAssociation.send :include,
          ::StaticRecordsCacheStore::RailsExtensions::ActiveRecord::Associations::BelongsToAssociation

      ::ActiveRecord::Associations::Builder::BelongsTo.send :extend,
          ::StaticRecordsCacheStore::RailsExtensions::ActiveRecord::Associations::Builder::BelongsTo
    end

    rake_tasks do
      load File.expand_path("../../tasks/railtie.rake", __FILE__)
    end

  end
end
