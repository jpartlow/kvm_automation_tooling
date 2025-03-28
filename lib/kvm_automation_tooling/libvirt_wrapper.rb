require 'nokogiri'
require 'libvirt'

module KvmAutomationTooling
  # Library for interacting with libvirt through the ruby-libvert gem.
  module LibvirtWrapper

    # Default path for the libvirt default storage pool.
    DEFAULT_POOL_PATH = "/var/lib/libvirt/images"

    def self.connection
      @connection ||= new_connection
    end

    def self.new_connection
      Libvirt::open("qemu:///system")
    end

    def self.close
      @connection.close
      @connection = nil
    end

    # Wrapper around the libvirt gem to provide a more user-friendly
    # interface.
    class Client
      attr_reader :lv

      def initialize(connection)
        @lv = connection
      end

      # https://gitlab.com/libvirt/libvirt-ruby/-/blob/master/examples/upload_volume.rb
      def upload_volume(volume_name, file_path:, capacity: 3)
        # get a reference to the default storage pool
        pool = lv.lookup_storage_pool_by_name("default")
        # create the new volume in the storage pool
        volume = pool.create_volume_xml(<<~EOF)
          <volume>
            <name>#{volume_name}</name>
            <allocation unit="b">#{File.size(file_path)}</allocation>
            <capacity unit="G">#{capacity}</capacity>
          </volume>
        EOF
        # open up the original file
        image_file = File.open(file_path, "rb")
        # create a new stream to upload the data
        stream = lv.stream
        # start the upload, using the stream created above
        volume.upload(stream, 0, image_file.size)
        error = nil
        begin
          # send all of the data over the stream.  For each invocation of
          # the block, ruby-libvirt yields a tuple containing the opaque
          # data passed into sendall (here, nil), and the maximum number
          # of bytes that it is willing to accept right now.  The block
          # should return a tuple, where the first argument returns the
          # number of bytes actually filled in (up to a maximum of 'n',
          # and with 0 meaning EOF), and the second argument being the
          # string containing the data to send.
          stream.sendall do |_opaque, n|
            begin
              r = image_file.read(n)
              r ? [0, r] : [0, ""]
            rescue Exception => e
              error = e
              [-1, ""]
            end
          end

          raise error if error

          return true
        ensure
          # once all of the data has been read by the block above, finish
          # *must* be called to ensure that all of it gets uploaded
          error.nil? ? stream.finish : stream.abort
        end
      end

      def volume_exist?(volume_name)
        pool = lv.lookup_storage_pool_by_name("default")
        pool.list_volumes.include?(volume_name)
      end

      # Define and create a persistent directory storage pool.
      #
      # @param pool_name [String] The name of the pool to create.
      # @param pool_path [String] The absolute path to the directory
      #   backing the storage pool.
      # @param mode [Integer] The permissions mode for the pool
      #   directory.
      # @param uid [Integer] The owner uid of the pool directory.
      # @param gid [Integer] The group id of the pool directory.
      def create_pool(pool_name, pool_path, mode: nil, uid: nil, gid: nil)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.pool(type: "dir") {
            xml.name pool_name
            xml.target {
              xml.path pool_path
              if mode || uid || gid
                xml.permissions {
                  xml.mode mode if mode
                  xml.owner uid if uid
                  xml.group gid if gid
                }
              end
            }
          }
        end

        pool = lv.define_storage_pool_xml(builder.doc.child.to_xml)
        pool.build
        pool.create
        pool.autostart = true
      end

      def pool_exist?(pool_name)
        lv.list_storage_pools.include?(pool_name)
      end

      def close
        lv.close
      end
    end

    # Entry point for the libvirt wrapper, yields a Client instance with a
    # libvirt connection to the passed block.
    def with_libvirt(&block)
      if @libvirt
        yield(@libvirt)
      else
        @libvirt = Client.new(LibvirtWrapper.connection)
        begin
          yield(@libvirt)
        ensure
          @libvirt = nil
          LibvirtWrapper.close
        end
      end
    end
  end
end
