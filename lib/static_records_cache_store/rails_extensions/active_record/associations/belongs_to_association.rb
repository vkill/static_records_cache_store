module StaticRecordsCacheStore
  module RailsExtensions

    module ActiveRecord
      module Associations
        module BelongsToAssociation

          extend ActiveSupport::Concern

          included do
            alias_method_chain :find_target, :cache_store_find_target
          end

          private

          def find_target_with_cache_store_find_target
            if ::StaticRecordsCacheStore::Configuration.enable.blank?
              return find_target_without_cache_store_find_target
            end

            ### copy begin
            # copy from ActiveRecord::Associations::AssociationScope#add_constraints
            if reflection.source_macro == :belongs_to
              if reflection.options[:polymorphic]
                key = reflection.association_primary_key(klass)
              else
                key = reflection.association_primary_key
              end

              foreign_key = reflection.foreign_key
            else
              key         = reflection.foreign_key
              foreign_key = reflection.active_record_primary_key
            end
            ### copy end

            finder_method_postfix = ::StaticRecordsCacheStore::Configuration.finder_method_postfix
            finder_by_key_method_proc = ::StaticRecordsCacheStore::Configuration.finder_by_key_method_proc
            original_finder_method = finder_by_key_method_proc.call(key)
            original_finder_method_with_cache = "%s_%s" % [original_finder_method, finder_method_postfix]

            if options[::StaticRecordsCacheStore::Configuration.belongs_to_option_key.to_sym].present? and
                klass.respond_to?(original_finder_method_with_cache)

              klass.send(original_finder_method, owner.send(foreign_key))
            else
              find_target_without_cache_store_find_target
            end
          end

        end
      end
    end
    
  end
end