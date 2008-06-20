require 'active_resource'
module Registry
  class Extension < ActiveResource::Base
    self.site = ENV['REGISTRY_URL'] || "http://ext.radiantcms.org/"

    def install
    end

    def uninstall
    end
  end

  class Installer
    attr_accessor :url, :path
    def initialize(url='',path=Dir.tmpdir)
      self.url, self.path = url, path
    end
    
    def abstract?
      true
    end
    
    def matches?
      false
    end
    
    def copy_to_vendor_extensions
    end
  end

  class Checkout < Installer
    def install
      checkout
      copy_to_vendor_extensions
    end
  end

  class Download < Installer
    def install
      download
      unpack
      copy_to_vendor_extensions
    end
    
    def download
      require 'open-uri'
      File.open(File.join(self.path, File.basename(self.url)), 'w') {|f| f.write open(self.url).read }
    end
  end

  class Git < Checkout
    def checkout_command
      "git clone #{url}"
    end
    
    def abstract?
      false
    end
    
    def matches?
      self.url =~ /\.?git/
    end
  end

  class Subversion < Checkout
    def checkout_command
      "svn checkout #{url}"
    end
    
    def abstract?
      false
    end
    
    def matches?
      self.url !~ /\.?git/
    end
  end

  class Gem < Download
    def unpack
      
    end
    
    def abstract?
      false
    end
  end

  class Tarball < Download
    def abstract?
      false
    end
  end

  class Zip < Download
    def abstract?
      false
    end
  end
end

module Radiant
  class Extension
    module Script
      class << self
        def execute(args)
          command = args.shift
          const_get(command.camelize).new(args)
        end
      end

      module Util
        attr_accessor :extension_name, :extension

        def to_extension_name(string)
          string.to_s.underscore
        end

        def installed?
          path_match = Regexp.compile("#{extension_name}$")
          extension_paths.any? {|p| p =~ path_match }
        end

        def extension_paths
          [RAILS_ROOT, RADIANT_ROOT].uniq.map { |p| Dir["#{p}/vendor/extensions/*"] }.flatten
        end

        def load_extensions
          Registry::Extension.find(:all)
        end

        def find_extension
          self.extension = load_extensions.find{|e| e.name == self.extension_name }
        end
      end

      class Install
        include Util

        def initialize(args=[])
          raise ArgumentError, "You must specify an extension to install." if args.blank?
          self.extension_name = to_extension_name(args.shift)
          if installed?
            puts "#{extension_name} is already installed."
          else
            find_extension && extension.install
          end
        end
      end

      class Uninstall
        include Util

        def initialize(args=[])
          raise ArgumentError, "You must specify an extension to uninstall." if args.blank?
          self.extension_name = to_extension_name(args.shift)
          if installed?
            find_extension && extension.uninstall
          else
            puts "#{extension} is not installed."
          end
        end
      end
    end
  end
end
