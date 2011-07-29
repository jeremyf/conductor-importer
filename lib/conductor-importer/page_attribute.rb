module Conductor
  module Importer
    class PageAttribute < ActiveRecord::Base
      belongs_to :page, :class_name => '::Conductor::Importer::Page'

      def construct_attribute_hash_for(hash)
        if key =~ /^([^\[]*)\[([^\]]*)\]$/
          hash[$1] = {}
          hash[$1][$2] = value
        elsif key =~ /[^\[]/
          hash[key] = value
        end
        hash
      end
    end
  end
end
