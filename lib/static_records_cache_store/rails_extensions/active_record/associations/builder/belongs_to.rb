module StaticRecordsCacheStore
  module RailsExtensions

    module ActiveRecord
      module Associations
        module Builder
          module BelongsTo

            extend ActiveSupport::Concern

            def self.extended(base)
              base.valid_options += [::StaticRecordsCacheStore::Configuration.belongs_to_option_key.to_sym]
            end

          end
        end
      end
    end

  end
end