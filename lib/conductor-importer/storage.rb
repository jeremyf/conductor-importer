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
            table.column :base_source_url, :string, :null => false
            table.column :base_target_url, :string, :null => false
            table.column :source_is_conductor, :boolean
            table.column :state, :string
          end

          add_index :batches, :batch_key, :unique => true

          create_table :pages, :force => force do |table|
            table.column :batch_id, :integer, :null => false
            table.column :source_url, :string, :null => false
            table.column :target_url, :string, :null => false
            table.column :name, :string, :null => false
            table.column :template, :string, :null => false
            table.column :state, :string
            table.column :content_map, :text
          end

          add_index :pages, :batch_id
          add_index :pages, [:batch_id, :source_url], :unique => true
          add_index :pages, :target_url

          create_table :page_attributes, :force => force do |table|
            table.column :page_id, :integer, :null => false
            table.column :key, :string, :null => false
            table.column :state, :string
            table.column :value, :text, :null => false
          end

          add_index :page_attributes, :page_id
          add_index :page_attributes, :key
          add_index :page_attributes, [:page_id, :key], :unique => true

          create_table :referenced_resources, :force => force do |table|
            table.column :batch_id, :integer, :null => false
            table.column :source_url, :string, :null => false
            table.column :target_url, :string
            table.column :state, :string
            table.column :type, :string
          end

          add_index :referenced_resources, :batch_id

          create_table :pages_referenced_resources, :force => force, :id => false do |table|
            table.column :page_id, :integer, :null => false
            table.column :referenced_resource_id, :integer, :null => false
          end
          add_index :pages_referenced_resources, [:page_id, :referenced_resource_id], :name => :pages_referenced_resources_index

        end
      end
    end
  end
end
