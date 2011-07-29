module Conductor
  module Importer
    module ReferencedResourceCommands
      def process!(*args); end
      def replace_content(*args); end
    end
    class ReferencedResource < ActiveRecord::Base
      belongs_to :batch, :class_name => '::Conductor::Importer::Batch'
      has_and_belongs_to_many :pages, :class_name => '::Conductor::Importer::Page'
      delegate :target_host_uri,
      :source_host_uri,
      :base_target_url,
      :base_source_url,
      :source_is_conductor?,
      :pages,
      :to => :batch

      def absolute_source_url
        @absolute_source_url ||= URI.parse(source_url =~ /^\// ? File.join(base_source_url, source_url) : source_url)
      end

      def include_in_import?
        return true if source_url.to_s.strip =~ /^(#{source_host_uri.scheme.sub(/s?$/, 's?')}:\/\/#{source_host_uri.host})?\//
        false
      end
      protected :include_in_import?

      state_machine :state, :initial => :preprocess do
        event :process_complete do
          transition :preprocess => :source_processed
        end
        event :skip do
          transition :preprocess => :skipped
        end
        state :skipped do
          include ReferencedResourceCommands
        end
        state :preprocess do
          include ReferencedResourceCommands
          def process!
            skip! and return true
            if include_in_import?
              __process!
              process_complete!
            else
              skip!
            end
          end
        end
        state :source_processed do
          include ReferencedResourceCommands
          # It is likely that this will need to be adjusted.
          # Namely what happens if replace_content is called before
          # the source_processed
          def replace_content(value)
            return false if target_url.nil?
            return false if include_in_import?
            if source_url.to_s != target_url.to_s
              yield(value.gsub(source_url.to_s, target_url.to_s))
            end
          end
        end
      end
    end
    class Image < ReferencedResource
      def absolute_source_url_for_download
        @absolute_source_url_for_download ||=
        if source_is_conductor?
          slugs = absolute_source_url.path.sub(/^\//,'').split("/")
          if slugs.length == 3
            slugs = [slugs[0], slugs[1], 'original', slugs[2]]
          elsif slugs[2] != 'original'
            slugs[2] = 'original'
          end
          URI.parse(File.join(base_source_url,slugs.join('/')))
        else
          absolute_source_url
        end
      end


      protected
      def temp_filename
        dirname = File.join(File.dirname(__FILE__), "../../tmp/images/#{self[:id]}/")
        FileUtils.mkdir_p(dirname)
        File.join(dirname, "#{File.basename(absolute_source_url_for_download.to_s)}")
      end
      def __process!
        download!
        upload!
      end
      def upload!
        protocol = 'https'
        host = base_target_url.sub(/^https?\:\/\//,'')
        protocol = 'http'
        begin
          RestClient.post("#{protocol}://#{::Conductor::Importer.net_id}:#{::Conductor::Importer.password}@#{File.join(host, "/admin/assets")}",
            {"asset" => { "file" => File.new(temp_filename), 'tag' => 'imported' }}
            )
        rescue RestClient::Found => e
          uri = URI.parse(e.response.headers[:location])
          asset_id = uri.path.sub(/^\/admin\/assets\/(\d+)(\/.*)?/, '\1')
          slugs = absolute_source_url.path.sub(/^\//,'').split("/")
          if source_is_conductor? && slugs[0] == 'assets'
            slugs[1] = asset_id
            self.target_url = File.join('/', slugs.join('/'))
          else
            self.target_url = File.join('/assets', asset_id, 'original', File.basename(absolute_source_url.to_s))
          end
          save!
        end
      end
      def download!
        response = RestClient.get(absolute_source_url_for_download.to_s)
        File.open(temp_filename, 'w+') do |file|
          file.puts response.body
        end
      end
    end
    class Link < ReferencedResource
      protected
      # We need only links to pages that we are migrating
      # or links to any images that we have touched; Note
      # this could include images that are not at the exact same
      # url as the img tag would indicate (i.e. /assets/45/original/hello.jpg)
      def include_in_import?
        # if link is to downloaded page
        return true if pages.find_by_absolute_url(absolute_source_url)
      end
      def __process!
        if page = pages.find_by_absolute_url(absolute_source_url)
          path, hash = source_url.split("#")
          if hash
            self.target_url = "#{page.target_uri.path}##{hash}"
          else
            self.target_url = page.target_uri.path
          end
        elsif source_url =~ /\/assets\/\d+/ && source_is_conductor?
          # We need to download these things, but for now I don't know the
          # full use case.
        end
        save!
      end
    end
  end
end
