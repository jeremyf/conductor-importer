require 'main'
require File.join(File.dirname(__FILE__), '../lib/conductor-importer')

Main {
  argument('filename') {
    description 'the name of the map file; JSON format'
  }
  option('database') {
    description 'the name of the database that we will be creating; SQLite'
  }

  def run
    Conductor::Importer.process(params['filename'].value)
    exit_success!
  rescue RuntimeError => e
    exit_failure!
  end
}
