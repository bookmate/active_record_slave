appraise 'rails_4.2' do
  gem 'activerecord', '~> 4.2.0'
end

appraise 'rails_5.0' do
  gem 'activerecord', '~> 5.0'
end

appraise 'rails_5.1' do
  gem 'activerecord', '~> 5.1.0'
end

appraise 'rails_5.2' do
  # Изменил весию потому что в 5.2.0.rc2 стояло ограничение на версию mysql2 (~> 0.4.4)
  # https://github.com/rails/rails/blob/db7edd81062648281d1e50c8ff9ebfafac5a9c3d/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L6
  # А текущая 0.5.2.
  gem 'activerecord', '~> 5.2.0'
end
