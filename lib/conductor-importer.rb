require "conductor-importer/version"
require 'json'
require 'rest_client'
require 'hpricot'

module Conductor
  module Importer
    # Your code goes here...
    def self.import(filename)
      json_object = JSON.parse(File.read(filename))
      json_object.each do |entry|
        process(entry)
      end
    end

    def self.process(entry)
      attributes = {}
      source_images = Set.new
      source_links = Set.new

      response = RestClient.get(entry['source_url'], :accept => :html)

      doc = Hpricot(response.body)

      # Collect the parts
      entry['content_map'].each do |options|
        source_content = options['selector_method_chain'].inject(doc) { |mem, var|
          mem = mem.send(*var)
        }

        # Scan for images
        (source_content/'img').each do |img_tag|
          source_images << img_tag
        end

        # Scan for images
        (source_content/'a').each do |a_tag|
          source_links << a_tag
        end

        attributes[options['target_attribute']] = source_content.collect(&:to_s).join("\n")
      end
    end
  end
end
