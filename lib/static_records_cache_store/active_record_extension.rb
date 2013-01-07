module StaticRecordsCacheStore
  module ActiveRecordExtension

    extend ActiveSupport::Concern

    included do
      class_attribute :store_with_cache_store, :store_with_cache_store_keys

      extend ClassMethods

    end

    module ClassMethods

      def static_records_cache_store(*options)
        @options = options.extract_options!

        store_key = @options.delete(:store) || @options.delete(:store_key) || default_store_key_with_cache_store
        self.store_with_cache_store = ::StaticRecordsCacheStore::Configuration.stores[store_key] || raise("%s not found" % store_key)

        keys = Array(@options.delete(:keys))
        raise(::ArgumentError, 'must define one key') if keys.blank?

        keys = keys.map{|x| Array(x)}
        self.store_with_cache_store_keys = keys
        
        ::StaticRecordsCacheStore.use_model_names << self.name
        
        return if ::StaticRecordsCacheStore::Configuration.enable.blank?

        finder_method_postfix = ::StaticRecordsCacheStore::Configuration.finder_method_postfix || raise("finder_method_postfix miss")

        # cache find method
        if static_records_cache_store_cache_find?
          define_singleton_method(:find) do |*args|
            return super *args if ::StaticRecordsCacheStore::Configuration.enable.blank?

            options = args.extract_options!
            if options.present?
              super *args
            else
              case args.first
              when :first, :last, :all
                super *args
              else
                ids = args.flatten.compact.uniq
                case ids.size
                when 0
                  super *args
                when 1
                  id = ids.first
                  id = id.to_i if id.is_a?(String) and id =~ /^\d/
                  self.store_with_cache_store.fetch([self.name, id]) {super id}
                else
                  ids.map do |id|
                    id = id.to_i if id.is_a?(String) and id =~ /^\d/
                    self.store_with_cache_store.fetch([self.name, id]) {super id}
                  end
                end
              end            
            end
          end
          
        end

        # cache find_by_x method
        finder_by_key_method_proc = ::StaticRecordsCacheStore::Configuration.finder_by_key_method_proc
        self.store_with_cache_store_keys.each do |key|
          finder_by_key_method = finder_by_key_method_proc.call(key)
          define_singleton_method(finder_by_key_method) do |*args|
            return super *args if ::StaticRecordsCacheStore::Configuration.enable.blank?

            args_dup = args.dup
            options = args.extract_options!
            if options.present?
              super *args_dup
            else
              args = args.first(Array(key).size)
              if static_records_cache_store_key_is_id?(key)
                args.map!{|arg| (arg.is_a?(String) and arg =~ /^\d/) ? arg.to_i : arg}
              end
              
              cache_key = static_records_cache_store_key_is_id?(key) ? [self.name, args] : [self.name, key, args]
              self.store_with_cache_store.fetch(cache_key) do
                super *args
              end
            end
          end

          define_singleton_method("%s_%s" % [finder_by_key_method, finder_method_postfix]) do |*args|
            finder_by_key_method(*args)
          end
        end



        #
        define_method(:change_static_records_cache_store) do |action, model_name=nil|
          method =
            case action.to_sym
            when :create, :update
              :write
            when :destroy
              :delete
            else
              raise "unknow action: %s" % action
            end

          model_name ||= self.class.name

          # delete/write cache find method
          cache_key = [model_name, self.send(:id)]
          if method == :delete
            self.class.store_with_cache_store.send(method, cache_key)
          else
            self.class.store_with_cache_store.send(method, cache_key, self)
          end

          # delete/write cache find_by_x method
          self.class.store_with_cache_store_keys.each do |key|
            args = Array(key).map{|x| self.send(x)}
            cache_key = self.class.send(:static_records_cache_store_key_is_id?, key) ? [model_name, args] : [model_name, key, args]
            if method == :delete
              self.class.store_with_cache_store.send(method, cache_key)
            else
              self.class.store_with_cache_store.send(method, cache_key, self)
            end
          end
        end

        self.class_eval do
          after_create(){ change_static_records_cache_store(:create) }
          after_update(:if => -> {changed?}){ change_static_records_cache_store(:update) }
          after_destroy(){ change_static_records_cache_store(:destroy) }
        end

      end

      private

      def default_store_key_with_cache_store
        ::StaticRecordsCacheStore::Configuration.default_store.to_sym
      end

      def alias_method_chain_with_method(target, feature)
        "%s_with_%s" % [target, feature]
      end

      def alias_method_chain_without_method(target, feature)
        "%s_without_%s" % [target, feature]
      end

      def static_records_cache_store_cache_find?
        keys = self.store_with_cache_store_keys
        keys.include?([:id]) or keys.include?(['id'])
      end

      def static_records_cache_store_key_is_id?(key)
        key = Array(key)
        key == [:id] or key == ['id']
      end

    end

  end
end