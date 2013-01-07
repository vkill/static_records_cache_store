namespace :static_records_cache_store do
  task :reset_all, [:action] => :environment do |t, args|
    action = args[:action] || :write
    p "> %s all models..." % [action]
    ::StaticRecordsCacheStore.reset_all! action
  end

  desc "write_all static_records_cache_store"
  task :write_all => :environment do
    Rake::Task['static_records_cache_store:reset_all'].invoke :write
  end

  desc "rewrite_all static_records_cache_store"
  task :rewrite_all => :environment do
    Rake::Task['static_records_cache_store:reset_all'].invoke :rewrite
  end

  desc "delete_all static_records_cache_store"
  task :delete_all => :environment do
    Rake::Task['static_records_cache_store:reset_all'].invoke :delete
  end

  task :reset, [:models, :action] => :environment do |t, args|
    models = args[:models] || ''
    action = args[:action] || :write
    models = models.split(/(%|@)/).delete_if{|x| ['%', '@'].include?(x)}
    models.each do |model|
      p "> %s %s..." % [action, model]
      ::StaticRecordsCacheStore.reset! model, action
    end
  end

  desc "write models static_records_cache_store, example: 'rake static_records_cache_store:write[group@skill]'"
  task :write, [:models] => :environment do |t, args|
    Rake::Task['static_records_cache_store:reset'].invoke args[:models], :write
  end

  desc "rewrite models static_records_cache_store, example: 'rake static_records_cache_store:rewrite[group@skill]'"
  task :rewrite, [:models] => :environment do |t, args|
    Rake::Task['static_records_cache_store:reset'].invoke args[:models], :rewrite
  end

  desc "delete models static_records_cache_store, example: 'rake static_records_cache_store:delete[group@skill]'"
  task :delete, [:models] => :environment do |t, args|
    Rake::Task['static_records_cache_store:reset'].invoke args[:models], :delete
  end

end