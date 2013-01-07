require "static_records_cache_store/version"
require "static_records_cache_store/configuration"
require "static_records_cache_store/railtie"

module StaticRecordsCacheStore

  mattr_accessor :use_model_names, :eager_loaded
  self.use_model_names = []
  self.eager_loaded = false

  class << self
    def configure
      yield Configuration
    end

    #
    # register_store :memory, ActiveSupport::Cache.lookup_store(:memory_store)
    #
    def register_store(name, store)
      # raise "store is not a 'ActiveSupport::Cache::Store'" unless store.is_a?(::ActiveSupport::Cache::Store)
      Configuration.stores[name.to_sym] = store
    end

    def disable!
      Configuration.enable = false
    end

    def enable!
      Configuration.enable = true
    end

    def reset!(model_name, action = :rewrite)
      rails_eager_load!

      model_name = model_name.name if !model_name.is_a?(String) and model_name.respond_to?(:name)

      model = 
        begin
          model_name.singularize.camelize.constantize
        rescue ::NameError
          model_name.camelize.constantize
        end

      raise("unknow model_name: %s" % model_name) unless self.use_model_names.include?(model.name)
      store = model.store_with_cache_store

      case action.to_sym
      when :write, :rewrite, :create, :update
        model.unscoped.find_each {|record| record.send :change_static_records_cache_store, :update, model.name}
      when :destroy, :delete, :clear
        if store_can_delete_matched?(store)
          store.delete_matched(/#{model.name}\//)
        else
          model.unscoped.find_each {|record| record.send :change_static_records_cache_store, :destroy, model.name}
        end
      else
        raise "unknow action: %s" % action
      end
    end

    def reset_all!(action = :rewrite)
      rails_eager_load!
      self.use_model_names.each do |model_name|
        reset!(model_name, action)
      end
    end

    private

    def rails_eager_load!(force = false)
      if self.eager_loaded.blank? or force == true
        ::Rails.application.eager_load!
        self.eager_loaded = true
      end
    end

    def store_can_delete_matched?(store)
      return false unless store.respond_to?(:delete_matched)
      
      case store
      when ::ActiveSupport::Cache::FileStore
        true
      when ActiveSupport::Cache::MemoryStore
        true
      else
        false
      end
    end

  end
end
