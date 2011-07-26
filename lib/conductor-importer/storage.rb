require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
:adapter => "sqlite3",
:database => 'tmp/conductor-importer.sqlite'
)

module Conductor
  module Importer
    class Storage
      def self.init(force = false)
        ActiveRecord::Schema.define do
          create_table :batches, :force => force do |table|
            table.column :batch_key, :string, :null => false
            table.column :state, :string
          end

          add_index :batches, :batch_key, :unique => true

          create_table :pages, :force => force do |table|
            table.column :batch_id, :integer, :null => false
            table.column :source_url, :string, :null => false
            table.column :target_url, :string, :null => false
            table.column :name, :string, :null => false
            table.column :state, :string
            table.column :content_map, :text
          end

          create_table :page_attributes, :force => force do |table|
            table.column :page_id, :integer, :null => false
            table.column :key, :string, :null => false
            table.column :state, :string
            table.column :value, :text, :null => false
          end

          create_table :referenced_objects, :force => force do |table|
            table.column :batch_id, :integer, :null => false
            table.column :source_url, :string, :null => false
            table.column :target_url, :string
            table.column :state, :string
            table.column :type, :string
          end

          create_table :pages_referenced_objects, :force => force, :id => false do |table|
            table.column :page_id, :integer, :null => false
            table.column :referenced_object_id, :integer, :null => false
          end
        end
      end
    end
  end
end
