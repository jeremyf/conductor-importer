require 'state_machine'
module Conductor
  module Importer
    # Each of the states has these methods; However when the batch is in the
    # given state, the method is overridden.
    module BatchCommands

      def download(*args); end
      def process_images(*args); end
      def process_links(*args); end
      def transform_content(*args); end
      def upload(*args); end

    end
    class Batch < ActiveRecord::Base
      has_many :pages, :dependent => :destroy, :class_name => '::Conductor::Importer::Page'
      has_many :referenced_objects, :dependent => :destroy, :class_name => '::Conductor::Importer::ReferencedObject'
      has_many :images, :class_name => '::Conductor::Importer::Image'
      has_many :links, :class_name => '::Conductor::Importer::Link'


      state_machine :state, :initial => :started do
        event :download_completed do
          transition [:started] => :download_complete
        end
        state :started do
          include BatchCommands
          def download(entries)
            entries.each do |entry|
              Page.create_from!(self, entry)
            end
            self.download_completed!
          end
        end
        state :download_complete do
          include BatchCommands

          def process_images
          end
        end
        state :images_processed do
          include BatchCommands

          def process_links
          end
        end

        state :links_processed do
          include BatchCommands

          def transform_content
          end
        end

        state :content_transformed do
          include BatchCommands

          def upload
          end
        end

        state :uploaded do
          include BatchCommands
        end
      end
    end


    class Page < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_many :page_attributes, :dependent => :destroy, :class_name => '::Conductor::Importer::PageAttribute'
      serialize :content_map
      has_and_belongs_to_many :referenced_objects

      def self.create_from!(batch, entry)
        batch.pages.find_or_initialize_by_batch_id_and_source_url(batch[:id], entry['source_url']).process!(batch,entry)
      end

      def process!(batch,entry)
        self.batch = batch
        self.content_map = entry['content_map']
        self.target_url = entry['target_url']
        self.name = entry['name']

        response = RestClient.get(entry['source_url'], :accept => :html)
        doc = Hpricot(response.body)

        # Collect the parts
        content_map.each do |options|
          source_content = options['selector_method_chain'].inject(doc) { |mem, var|
            mem = mem.send(*var)
          }

          # Scan for images
          (source_content/'img').each do |img_tag|
            self.referenced_objects << batch.images.build(:batch => self.batch, :source_url => img_tag.get_attribute('src'))
          end


          # Scan for images
          (source_content/'a').each do |a_tag|
            if a_tag.get_attribute('href') !~ /^\#/
              self.referenced_objects << batch.links.build(:batch => self.batch, :source_url => a_tag.get_attribute('href'))
            end
          end

          self.page_attributes.build(:key => options['target_attribute'], :value => source_content.collect(&:to_s).join("\n"))
        end
        # self.save!
        self.download_complete!
      end

      state_machine :state, :initial => :preprocess do
        event :download_complete do
          transition :preprocess => :downloaded
        end

        state :preprocess
        state :downloaded
        state :content_transformed
        state :uploaded
      end

    end
    class PageAttribute < ActiveRecord::Base
      belongs_to :page, :class_name => '::Conductor::Importer::Page'
    end
    class ReferencedObject < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_and_belongs_to_many :pages, :class_name => '::Conductor::Importer::Page'
    end
    class Image < ReferencedObject
    end
    class Link < ReferencedObject
    end
  end
end
