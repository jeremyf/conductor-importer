require 'main'
require File.join(File.dirname(__FILE__), '../lib/conductor-importer')

Main {
  argument('filename') {
    description 'the name of the map file; JSON format'
  }

  def run
    Conductor::Importer.import(params['filename'].value)
    exit_success!
  rescue RuntimeError => e
    exit_failure!
  end
}
