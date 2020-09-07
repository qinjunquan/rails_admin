class FakeModel < ActiveRecord::Base
  self.table_name = "schema_migrations"
  def method_missing(name, *args, &block)
    ""
  end
end
