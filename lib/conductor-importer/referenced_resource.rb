module Conductor
  module Importer
    module ReferencedResourceCommands
      def process!(*args); end
      def replace_content(*args); end
    end
    class ReferencedResource < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_and_belongs_to_many :pages, :class_name => '::Conductor::Importer::Page'


      state_machine :state, :initial => :preprocess do
        event :process_source do
          transition :preprocess => :source_processed
        end
        state :preprocess do
          include ReferencedResourceCommands
          def process!
          end
        end
        state :source_processed do
          include ReferencedResourceCommands
          def replace_content(value)
            if source_url.to_s != target_url.to_s
              yield(value.gsub(source_url.to_s, target_url.to_s))
            end
          end
        end
      end
    end
    class Image < ReferencedResource
    end
    class Link < ReferencedResource
    end
  end
end
