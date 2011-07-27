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
      has_many :referenced_resources, :dependent => :destroy, :class_name => '::Conductor::Importer::ReferencedResource'
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

    class PageAttribute < ActiveRecord::Base
      belongs_to :page, :class_name => '::Conductor::Importer::Page'
    end
  end
end
