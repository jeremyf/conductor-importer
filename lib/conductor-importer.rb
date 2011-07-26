require "conductor-importer/version"
require "conductor-importer/storage"
require 'json'
require 'rest_client'
require 'hpricot'

module Conductor
  module Importer
    # Your code goes here...
    def self.import(filename)
      json_object = JSON.parse(File.read(filename))
      Storage.init(true)
      json_object.each do |entry|
        process(entry)
      end
    end

    def self.process(entry)
      Page.new(entry).tap do |page|
        response = RestClient.get(entry['source_url'], :accept => :html)
        doc = Hpricot(response.body)

        # Collect the parts
        entry['content_map'].each do |options|
          source_content = options['selector_method_chain'].inject(doc) { |mem, var|
            mem = mem.send(*var)
          }

          # Scan for images
          (source_content/'img').each do |img_tag|
            require 'ruby-debug'; debugger; true;
            page.referenced_objects << Image.create(:source_url => img_tag.get_attribute('src'))
          end

          # Scan for images
          (source_content/'a').each do |a_tag|
            if a_tag.get_attribute('href') !~ /^\#/
              page.referenced_objects << Image.create(:source_url => a_tag.get_attribute('href'))
            end
          end

          page.page_attributes.build(:key => options['target_attribute'], :value => source_content.collect(&:to_s).join("\n"))
        end
        page.save!
      end
    end
  end
end
