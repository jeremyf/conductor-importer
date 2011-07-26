require 'state_machine'
module Conductor
  module Importer
    module BatchCommands
      def download(*args); end
      def process_images(*args); end
      def process_links(*args); end
      def transform_content(*args); end
      def upload(*args); end

    end
    class Batch < ActiveRecord::Base
      has_many :pages, :dependent => :destroy
      has_many :referenced_objects, :dependent => :destroy
      has_many :images
      has_many :links


      state_machine :state, :initial => :started do
        event :download_completed do
          transition [:started] => :download_complete
        end
        state :started do
          include BatchCommands
          def download(entries)
            entries.each do |entry|
              self.pages.build(entry).tap do |page|
                page.batch = self
                response = RestClient.get(entry['source_url'], :accept => :html)
                doc = Hpricot(response.body)

                # Collect the parts
                entry['content_map'].each do |options|
                  source_content = options['selector_method_chain'].inject(doc) { |mem, var|
                    mem = mem.send(*var)
                  }

                  # Scan for images
                  (source_content/'img').each do |img_tag|
                    page.referenced_objects << self.images.build(:batch => self, :source_url => img_tag.get_attribute('src'))
                  end

                  # Scan for images
                  (source_content/'a').each do |a_tag|
                    if a_tag.get_attribute('href') !~ /^\#/
                      page.referenced_objects << self.links.build(:batch => self, :source_url => a_tag.get_attribute('href'))
                    end
                  end

                  page.page_attributes.build(:key => options['target_attribute'], :value => source_content.collect(&:to_s).join("\n"))
                end
                page.save!
              end
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
      end
    end


    class Page < ActiveRecord::Base
      belongs_to :batch
      has_many :page_attributes, :dependent => :destroy
      serialize :content_map
      has_and_belongs_to_many :referenced_objects

      state_machine :state, :initial => :downloaded
    end
    class PageAttribute < ActiveRecord::Base
      belongs_to :page
    end
    class ReferencedObject < ActiveRecord::Base
      belongs_to :batch
      has_and_belongs_to_many :pages
    end
    class Image < ReferencedObject
    end
    class Link < ReferencedObject
    end
  end
end
