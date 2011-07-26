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
          create_table :pages, :force => force do |table|
            table.column :source_url, :string, :null => false
            table.column :target_url, :string, :null => false
            table.column :name, :string, :null => false
            table.column :state, :string
            table.column :content_map, :text
            table.column :batch_number, :datetime
          end

          create_table :page_attributes, :force => force do |table|
            table.column :page_id, :integer, :null => false
            table.column :key, :string, :null => false
            table.column :state, :string
            table.column :value, :text, :null => false
          end

          create_table :referenced_objects, :force => force do |table|
            table.column :source_url, :string, :null => false
            table.column :target_url, :string
            table.column :state, :string
            table.column :batch_number, :datetime
            table.column :type, :string
          end

          create_table :pages_referenced_objects, :force => force, :id => false do |table|
            table.column :page_id, :integer, :null => false
            table.column :referenced_object_id, :integer, :null => false
          end
        end
      end
    end
    class Page < ActiveRecord::Base
      has_many :page_attributes, :dependent => :destroy
      serialize :content_map
      has_and_belongs_to_many :referenced_objects
    end
    class PageAttribute < ActiveRecord::Base
      belongs_to :page
    end
    class ReferencedObject < ActiveRecord::Base
      has_and_belongs_to_many :pages
    end
    class Image < ReferencedObject
    end
    class Link < ReferencedObject
    end
  end
end
