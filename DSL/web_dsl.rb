# web_dsl.rb
require 'cgi'
require 'webrick'
require 'json'
require 'mail'
require 'securerandom'

# Extend String with HTML-escaping convenience.
class String
  def html_escape
    CGI.escapeHTML(self)
  end
end

module WebFramework
  class App
    attr_accessor :routes, :templates, :layout, :session_store

    def initialize
      @routes = {}
      @templates = {}
      @layout = nil
      @session_store = {}  # Simple session storage hash keyed by session_id.
      @user_data = load_user_data
      setup_mail
    end

    # Returns the session hash for the request.
    # Uses a cookie called 'session_id' to identify the session.
    def session(req, res)
      cookie = req.cookies.find { |c| c.name == 'session_id' }
      session_id = cookie ? cookie.value : SecureRandom.hex(16)
      res.cookies << WEBrick::Cookie.new('session_id', session_id) unless cookie
      @session_store[session_id] ||= {}
    end

    def load_users(file = "users.json")
      return [] unless File.exist?(file)
      puts JSON.parse(File.read(file))
    end

    def save_users(users, file = "users.json")
      File.write(file, JSON.pretty_generate(users))
    end

    def load_user_data
      return {} unless File.exist?('user_data.json')
      JSON.parse(File.read('user_data.json'))
    end

    def save_user_data
      File.write('user_data.json', @user_data.to_json)
    end

    def setup_mail
      Mail.defaults do
        delivery_method :smtp, {
          address: "smtp.gmail.com",
          port: 587,
          user_name: 'your_email@gmail.com',
          password: 'your_password',
          authentication: 'plain',
          enable_starttls_auto: true
        }
      end
    end

    def send_email(to_email, html_body)
      mail = Mail.new do
        from    'your_email@gmail.com'
        to      to_email
        subject 'Your Customized Web Page'
        html_part do
          content_type 'text/html; charset=UTF-8'
          body html_body
        end
      end
      mail.deliver!
    end

    def route(path, &block)
      @routes[path] = block
    end

    def define_template(name, &block)
      @templates[name.to_sym] = block
    end

    def layout(&block)
      @layout = block
    end

    def render(name, context = {})
      unless @templates.key?(name.to_sym)
        return "<h3>Error: Template not found: #{name}</h3>"
      end
      begin
        renderer = Object.new
        context.each { |key, value| renderer.instance_variable_set("@#{key}", value) }
        renderer.define_singleton_method(:capture) { |&blk| renderer.instance_eval(&blk) }
        renderer.instance_eval(&@templates[name.to_sym])
      rescue => e
        "<h3>Error rendering template: #{e.message}</h3>"
      end
    end

    def start(port: 4567)
      server = WEBrick::HTTPServer.new(Port: port)

      # Route for file uploads.
      server.mount_proc('/upload') do |req, res|
        if req.request_method == 'POST'
          uploaded = req.query['image']
          if uploaded && uploaded.respond_to?(:filename)
            filename = "uploads/#{SecureRandom.hex}_#{uploaded.filename}"
            File.open(filename, 'wb') { |f| f.write(uploaded.content) }
            res.body = "Uploaded to #{filename}"
          else
            res.body = "No image uploaded."
          end
        else
          res.body = "Upload an image."
        end
        res['Content-Type'] = 'text/html'
      end

      # Mount each defined route.
      @routes.each do |path, block|
        server.mount_proc path do |req, res|
          # Retrieve (or create) the session for the request.
          sess = session(req, res)
          res.body = instance_exec(req, res, sess, &block)
          res['Content-Type'] = 'text/html'
        end
      end

      trap("INT") { server.shutdown }
      server.start
    end
  end

  # Convenience method to build a new app.
  def self.app(&block)
    application = App.new
    application.instance_eval(&block)
    application
  end

  # Helper functions for managing users and changelog.
  def load_users(file = "users.json")
    return [] unless File.exist?(file)
    JSON.parse(File.read(file))
  end

  def save_users(users, file = "users.json")
    File.write(file, JSON.pretty_generate(users))
  end

  def load_changelog(file = "changelog.json")
    return [] unless File.exist?(file)
    JSON.parse(File.read(file))
  end

  def save_changelog(logs, file = "changelog.json")
    File.write(file, JSON.pretty_generate(logs))
  end

  def log_change(session_role, action, detail)
    logs = load_changelog
    logs << {
      action: action,
      detail: detail,
      by: session_role,
      timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
    }
    save_changelog(logs)
  end
end
