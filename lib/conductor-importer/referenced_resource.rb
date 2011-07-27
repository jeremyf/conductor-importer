module Conductor
  module Importer
    class ReferencedResource < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_and_belongs_to_many :pages, :class_name => '::Conductor::Importer::Page'
    end
    class Image < ReferencedResource
    end
    class Link < ReferencedResource
    end
  end
end
