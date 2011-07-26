require "conductor-importer/version"
require "conductor-importer/storage"
require "conductor-importer/batch"
require 'json'
require 'rest_client'
require 'hpricot'

module Conductor
  module Importer
    # Your code goes here...
    def self.process(filename)
      json_object = JSON.parse(File.read(filename))
      Storage.init(true)
      Batch.download(json_object)
    end
  end
end
