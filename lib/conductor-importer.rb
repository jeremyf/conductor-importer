require 'state_machine'
require 'json'
require 'rest_client'
require 'hpricot'

require "conductor-importer/version"
require "conductor-importer/storage"
require "conductor-importer/batch"
require "conductor-importer/page"
require "conductor-importer/referenced_resource"

module Conductor
  module Importer
    # Your code goes here...
    def self.process(filename)
      json_object = JSON.parse(File.read(filename))
      Storage.init(true)
      Batch.create(:batch_key => json_object['batch_key']) do |batch|
        batch.download( json_object['entries'] )
        batch.process_images
        batch.process_links
        batch.transform_content
        batch.upload
      end
    end
  end
end
