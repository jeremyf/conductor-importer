module Conductor
  module Importer
    # Each of the states has these methods; However when the batch is in the
    # given state, the method is overridden.
    module PageCommands
      def download!(*args); end
      def transform_content(*args); end
    end


    class Page < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_many :page_attributes, :dependent => :destroy, :class_name => '::Conductor::Importer::PageAttribute'
      serialize :content_map
      has_and_belongs_to_many :referenced_resources

      def self.create_from!(batch, entry)
        batch.pages.find_or_initialize_by_batch_id_and_source_url(batch[:id], entry['source_url']).download!(batch,entry)
      end

      state_machine :state, :initial => :preprocess do
        event :download_complete do
          transition :preprocess => :downloaded
        end

        state :preprocess do
          include PageCommands
          def download!(batch,entry)

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
                self.referenced_resources << batch.images.build(:batch => self.batch, :source_url => img_tag.get_attribute('src'))
              end


              # Scan for images
              (source_content/'a').each do |a_tag|
                if a_tag.get_attribute('href') !~ /^\#/
                  self.referenced_resources << batch.links.build(:batch => self.batch, :source_url => a_tag.get_attribute('href'))
                end
              end

              self.page_attributes.build(:key => options['target_attribute'], :value => source_content.collect(&:to_s).join("\n"))
            end
            # self.save!
            self.download_complete!
          end
        end
        state :downloaded do
          include PageCommands
          def transform_content
          end
        end
        state :content_transformed do
          include PageCommands
        end
        state :uploaded do
          include PageCommands
        end
      end
    end
  end
end
