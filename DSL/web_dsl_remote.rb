# web_dsl_remote.rb
#
# Dev: Michael Cliffton Scott
# Rev: Zero , 11/13/2025
#
# This file defines a lightweight remote web framework module `WebFramework` that provides
# a DSL (Domain-Specific Language) for building simple web applications in Ruby.
# It includes functionality for routing, templating, session management, email sending,
# and file uploads. The framework is built on top of the WEBrick HTTP server.
#
# Classes and Modules:
# - `String`: Extended with an `html_escape` method for HTML-escaping strings.
# - `WebFramework::App`: The main application class that handles routes, templates,
#   sessions, and other web application features.
#
# Key Features:
# - **Routing**: Define routes using the `route` method and associate them with blocks
#   to handle HTTP requests.
# - **Templating**: Define templates using the `define_template` method and render them
#   with the `render` method. Supports layouts for consistent page structure.
# - **Session Management**: Provides simple session storage using cookies and a hash
#   (`session_store`) to store session data.
# - **File Uploads**: Supports file uploads via a `/upload` route.
# - **Email Sending**: Configures email sending using the `mail` gem and provides
#   methods to send emails with HTML content.
# - **User and Changelog Management**: Includes helper methods for loading, saving,
#   and managing user data and changelogs in JSON files.
#
# Methods:
# - `normalize_submission_data(req)`: Normalizes and extracts form submission data
#   from an HTTP request.
# - `session(req, res)`: Retrieves or creates a session for the given request and response.
# - `load_users` / `save_users(users, file)`: Load and save user data from/to a JSON file.
# - `load_user_data` / `save_user_data`: Load and save additional user data from/to a JSON file.
# - `setup_mail`: Configures the email delivery method using SMTP.
# - `send_email(to_email, html_body)`: Sends an email with the specified recipient and HTML body.
# - `route(path, &block)`: Defines a route and associates it with a block to handle requests.
# - `define_template(name, &block)`: Defines a reusable template.
# - `layout(&block)`: Defines a layout for wrapping rendered templates.
# - `render(name, context)`: Renders a template with the given context.
# - `start(port)`: Starts the WEBrick HTTP server on the specified port and mounts routes.
# - `log_change(session_role, action, detail)`: Logs changes to a changelog file.
#
# Usage:
# - Create an application using `WebFramework.app` and define routes, templates, and layouts.
# - Start the application by calling `start` with the desired port.
#
# Example:
# ```ruby
# app = WebFramework.app do
#   route '/' do |req, res, sess|
#     "Hello, World!"
#   end
# end
# app.start(port: 8080)
# ```

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
    def start(port: 4567)
      WebFramework.start(port: port, BindAddress: '0.0.0.0') #This binds the web server to all network interfaces so another computer can reach it.
      #use ip config to get ip so remote computer can remote in, i.e, for 192.168.1.52, search http://192.168.1.52:4567/ on remote pc
      #You must allow inbound connections for the port (4567 by default). Run PowerShell as admin
      #Inside PowerShell: New-NetFirewallRule -DisplayName "RubyDSL" -Direction Inbound -Protocol TCP -LocalPort 4567 -Action Allow
      # for LAN host IP changes, Assign a DHCP reservation in your router for the host machine OR use a local DNS name if your network supports it

    end
    def initialize
      @routes = {}
      @templates = {}
      @layout = nil
      @session_store = {}  # Simple session storage hash keyed by session_id.
      @user_data = load_user_data
      setup_mail
    end

    #Normalize input for json 
    def normalize_submission_data(req)
      {
        name: req.query["name"].to_s.strip,
        email: req.query["email"].to_s.strip,
        about: req.query["about"].to_s.strip,
        project: req.query["project"].to_s.strip,
        description: req.query["description"].to_s.strip,
        priority: req.query["priority"] || "Low",
        page_title: req.query["page_title"].to_s.strip,
        background_color: req.query["background_color"] || "#ffffff",
        include_email: req.query["include_email"] == "on",
        include_image: req.query["include_image"] == "on",
        layout_style: req.query["layout_style"] || "basic",
        submitted_at: Time.now.utc.iso8601
      }
    end

    # Returns the session hash for the request.
    # Uses a cookie called 'session_id' to identify the session.
    def session(req, res)
      cookie = req.cookies.find { |c| c.name == 'session_id' }
      session_id = cookie ? cookie.value : SecureRandom.hex(16)
      res.cookies << WEBrick::Cookie.new('session_id', session_id) unless cookie
      @session_store[session_id] ||= {}
    end

    def load_users
      JSON.parse(File.read("users.json"))
    rescue => e
      puts "Error loading users.json: #{e.message}"
      []
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

    def setup_mail #Use App-Password 2FA or Environment instead of direct link, i.e user_name: ENV['SMTP_USER'], password: ENV['SMTP_PASS']
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
      layout do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>DSL App</title>
            <style>
              body { font-family: Arial, sans-serif; padding: 20px; background: #f9f9f9; }
              h2 { color: #333; }
              table { width: 100%; border-collapse: collapse; }
              th, td { padding: 8px 12px; border: 1px solid #ccc; }
              th { background: #eee; }
            </style>
          </head>
          <body>
            #{capture}
          </body>
          </html>
        HTML
      end
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
  def load_users
    JSON.parse(File.read("users.json"))
  rescue => e
    puts "Error loading users.json: #{e.message}"
    []
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
