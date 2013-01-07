require 'ostruct'

module StaticRecordsCacheStore
  Configuration = Struct.new(
    :enable,
    :stores,
    :default_store,
    :belongs_to_option_key,
    :has_one_option_key,
    :finder_method_postfix,
    :finder_by_key_method_proc,
  ).new(
    true,
    {
      :shared => ActiveSupport::Cache.lookup_store(:memory_store),
    },
    :shared,
    :read_from_cache,
    :read_from_cache,
    :cache_store,
    proc{|keys| "find_by_%s" % Array(keys).join('_and_') },
  )
end
