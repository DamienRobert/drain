require "uri"
require "delegate"

module URI
  # From https://github.com/packsaddle/ruby-uri-ssh_git
  module Ssh
    extend self
    # @example
    #   url = URI::Ssh.parse('git@github.com:packsaddle/ruby-uri-ssh_git.git')
    #   #=> #<URI::Ssh::Generic git@github.com:packsaddle/ruby-uri-ssh_git.git>
    #   url.scheme #=> nil
    #   url.userinfo #=> 'git'
    #   url.user #=> 'git'
    #   url.password #=> nil
    #   url.host #=> 'github.com'
    #   url.port #=> nil
    #   url.registry #=> nil
    #   url.path #=> 'packsaddle/ruby-uri-ssh_git.git'
    #   url.opaque #=> nil
    #   url.query #=> nil
    #   url.fragment #=> nil
    # @see http://docs.ruby-lang.org/en/2.2.0/URI/Generic.html
    # @param url [String] git repository url via ssh protocol
    # @return [Generic] parsed object
    protected def internal_parse(uri_string)
      host_part, path_part = uri_string&.split(':', 2)
      # There may be no user, so reverse the split to make sure host always
      # is !nil if host_part was !nil.
      host, userinfo = host_part&.split('@', 2)&.reverse
      Generic.build(userinfo: userinfo, host: host || uri_string, path: path_part)
    end

    # @param url [String] git repository-ish url
    # @return [URI::Generic] if url starts ssh
    # @return [URI::HTTPS] if url starts https
    # @return [URI::SshGit] if url is ssh+git e.g git@example.com:schacon/ticgit.git
    def parse(url, force: false)
      (ssh_git_url?(url) || force)? ::URI::Ssh.internal_parse(url) : ::URI.parse(url)
    end

    ## From: https://github.com/packsaddle/ruby-git_clone_url
    # @param url [String] git repository-ish url
    # @return [Boolean] true if url is git via ssh protocol
    def ssh_git_url?(url)
      !generic_url?(url)
    end

    # @param url [String] git repository-ish url
    # @return [Boolean] true if url is https, ssh protocol
    def generic_url?(url)
      match = %r{\A(\w*)://}.match(url)
      !match.nil?
    end

    class Generic < ::URI::Generic #URI::Ssh::Generic
      # check_host returns `false` for 'foo_bar'
      # but in ssh config this can be a valid host
      def check_host(_v)
        return true
      end
      # @example
      #   URI::Ssh::Generic.build(
      #     userinfo: 'git',
      #     host: 'github.com',
      #     path: 'packsaddle/ruby-uri-ssh_git.git'
      #   ).to_ssh
      #   #=> 'git@github.com:packsaddle/ruby-uri-ssh_git.git'
      #
      # @return [String] git repository url via ssh protocol
      def to_ssh(show_path: true)
        str = ''
        str << "#{user}@" if user && !user.empty?
        str << "#{host}"
        str << ":#{path}" if path and show_path
        str
      end
    end
  end
end

module DR
  module URI
    module MailToHelper
       # TODO: wrap to= to add user= and host=
    end

    module URIHelpers
      def to_h
        h = { uri: uri }
        components = uri.component
        components += %i[user password] if components.include?(:userinfo)
        components.each do |m|
          v = uri.public_send(m)
          v && h[m] = v
        end
        h
      end

      def to_json(_state = nil)
        h=to_h
        h[:uri]=h[:uri].to_s #h[:uri] is a URIWrapper, so convert it to string so json does not convert it again
        h.to_json
      end

      # strip password
      def to_public
        pub = dup
        pub.password = nil
        pub.to_s
      end

      def strip_user
        pub = dup
        pub.user = nil
        pub.to_s
      end

      # uri=u2.merge(uri) does not work if uri is absolute
      def reverse_merge(u2)
        # return self unless uri.scheme
        u2 = u2.clone
        u2 = self.class.new(u2) unless u2.is_a?(self.class)
        if opaque.nil? == u2.opaque.nil?
          u2.soft_merge(self)
        else
          self
        end
      end

      # merge(u2) replace self by u2 if u2 is aboslute
      # soft_merge looks at each u2 components
      def soft_merge(u2)
        # we want automatic unescaping of u2 components
        u2 = self.class.new(u2) unless u2.is_a?(self.class)
        # only merge if we are both opaque or path like
        if opaque.nil? == u2.opaque.nil?
          components = uri.component
          if components.include?(:userinfo)
            components += %i[user password]
            components.delete(:userinfo)
          end
          components.each do |m|
            # path returns "" by default but we don't want to merge in this case
            if u2.respond_to?(m) && (v = u2.public_send(m)) && !((v == "") && (m == :path))
              uri.public_send(:"#{m}=", v)
            end
          end
        end
        self
      end
    end

    class Wrapper < SimpleDelegator
      def uri
         __getobj__
      end

      def uri=(uri)
        __setobj__(transform_uri(uri))
      end

      include URIHelpers

      def self.parse(s)
        new(::URI.parse(s))
      end

      def self.get_uri_object(uri)
        uri = self.parse(uri.to_s) unless uri.is_a?(::URI)
        uri
      end

      private def transform_uri(uri)
        # wrap the components around escape/unescape
        uri = self.class.get_uri_object(uri)
        if uri.is_a?(::URI::Generic)
          uri.extend(URI::MailToHelper) if uri.is_a?(::URI::MailTo)
          components = uri.component
          components += %i[user password] if components.include?(:userinfo)
          components.each do |m|
            uri.define_singleton_method(m) do
              r = super()
              r && r.is_a?(String) ? URI.unescape(r) : r
              # r && r.is_a?(String) ? ::URI.decode_www_form_component(r) : r
            end
            uri.define_singleton_method(:"#{m}=") do |v|
              begin
                super(v && v.is_a?(String) ? URI.escape(v) : v)
                # super(v && v.is_a?(String) ? ::URI.encode_www_form_component(v) : v)
              rescue ::URI::InvalidURIError => e
                warn "#{e} in (#{self}).#{m}=#{v}"
                 # require 'pry'; binding.pry
              end
            end
          end
        end
        uri
      end

      # recall that '//user@server' is an uri while 'user@server' is just a path
      def initialize(uri)
        super
        self.uri = uri
      end
    end

    class Ssh < Wrapper
      def self.parse(s)
        new(::URI::Ssh.parse(s))
      end
    end

    # reimplement deprecated escape and unescape methods since
    # URI.encode_www_form_component does not encode the same way
    # cf the source code of URI::DEFAULT_PARSER.escape
    module URIEscape
      extend self
      def escape(*arg)
        ::URI::DEFAULT_PARSER.escape(*arg)
      end
      def unescape(*arg)
        ::URI::DEFAULT_PARSER.unescape(*arg)
      end
    end
    Escape=URIEscape
    extend URIEscape

    def self.parse(s)
      Wrapper.parse(s)
    end
  end

end
