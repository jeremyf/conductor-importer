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


      def target_host_uri
        @target_host_uri ||= URI.parse(base_target_url)
      end

      def source_host_uri
        @source_host_uri ||= URI.parse(base_source_url)
      end

      state_machine :state, :initial => :started do
        event :download_completed do
          transition [:started] => :download_complete
        end
        event :images_processed do
          transition [:download_complete] => :images_processed
        end
        event :links_processed do
          transition [:images_processed] => :links_processed
        end
        event :content_transformed do
          transition [:links_processed] => :content_transformed
        end
        event :upload_completed do
          transition [:content_transformed] => :uploaded
        end

        state :started do
          include BatchCommands
          def download(entries)
            entries.each do |entry|
              Page.create_from!(self, entry)
            end
            self.download_completed!
            self.reload
          end
        end
        state :download_complete do
          include BatchCommands

          def process_images
            images.each {|image| image.process! }
            images_processed!
            self.reload
          end
        end
        state :images_processed do
          include BatchCommands

          def process_links
            links.each {|link| link.process! }
            links_processed!
            self.reload
          end
        end

        state :links_processed do
          include BatchCommands

          def transform_content
            pages.each { |page| page.transform_content! }
            content_transformed!
            self.reload
          end
        end

        state :content_transformed do
          include BatchCommands
          def upload
            pages.upload_order.each {|page| page.upload! }
            upload_completed!
            self.reload
          end
        end

        state :uploaded do
          include BatchCommands
        end
      end
    end
  end
end
