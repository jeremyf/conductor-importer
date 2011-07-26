require 'state_machine'
module Conductor
  module Importer
    class Batch < ActiveRecord::Base
      has_many :pages, :dependent => :destroy
      has_many :referenced_objects, :dependent => :destroy
      has_many :images
      has_many :links

      state_machine :state, :initial => :started do
        event :download_completed do
          transition [:started] => :download_complete
        end
      end

      def self.download(object)
        batch = Batch.create(:key => object['batch_number'] || Time.now.to_s)

        object['entries'].each do |entry|
          batch.pages.build(entry).tap do |page|
            response = RestClient.get(entry['source_url'], :accept => :html)
            doc = Hpricot(response.body)

            # Collect the parts
            entry['content_map'].each do |options|
              source_content = options['selector_method_chain'].inject(doc) { |mem, var|
                mem = mem.send(*var)
              }

              # Scan for images
              (source_content/'img').each do |img_tag|
                page.referenced_objects << batch.images.create(:source_url => img_tag.get_attribute('src'))
              end

              # Scan for images
              (source_content/'a').each do |a_tag|
                if a_tag.get_attribute('href') !~ /^\#/
                  page.referenced_objects << batch.links.create(:source_url => a_tag.get_attribute('href'))
                end
              end

              page.page_attributes.build(:key => options['target_attribute'], :value => source_content.collect(&:to_s).join("\n"))
            end
            page.save!
          end
        end
        batch.download_completed!
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
