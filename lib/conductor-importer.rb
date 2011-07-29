require 'state_machine'
require 'json'
require 'rest_client'
require 'hpricot'
require 'open-uri'
require 'highline'
require "highline/import"


require "conductor-importer/version"
require "conductor-importer/storage"
require "conductor-importer/batch"
require "conductor-importer/page"
require "conductor-importer/referenced_resource"
require "conductor-importer/page_attribute"

module Conductor
  module Importer
    def self.net_id
      @net_id ||= ask(%(<%= color("Net ID: ", :black, :on_yellow)%>))
    end
    def self.password
      @password ||= ask(%(<%= color("Password: ", :black, :on_yellow)%>)) { |q| q.echo = "*" }
    end
    # Your code goes here...
    def self.process(filename)
      json_object = JSON.parse(File.read(filename))
      Storage.init(true)
      Batch.create(
        :batch_key => json_object['batch_key'],
        :base_source_url => json_object['base_source_url'],
        :base_target_url => json_object['base_target_url'],
        :source_is_conductor => json_object['source_is_conductor']
      ) do |batch|
        batch.download( json_object['entries'] )
        batch.process_images
        batch.process_links
        batch.transform_content
        batch.upload
      end
    end
  end
end
