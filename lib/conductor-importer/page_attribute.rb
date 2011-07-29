module Conductor
  module Importer
    class PageAttribute < ActiveRecord::Base
      belongs_to :page, :class_name => '::Conductor::Importer::Page'
    end
  end
end
