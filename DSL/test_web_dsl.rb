# test_web_dsl.rb
# This script defines a web application using a custom Ruby-based DSL (Domain-Specific Language) for web development.
# It includes functionality for user role management, dynamic template and function editing, and user data handling.
# The application supports multiple routes and provides an interactive interface for administrators and editors.

# Key Features:
# - Role-based access control: Supports "admin", "user", and "editor" roles with specific permissions.
# - Dynamic editing: Allows "editor" role to modify templates and functions directly within the script.
# - User management: Enables "admin" role to add, edit, delete, and view users via a web interface.
# - JSON-based data handling: Stores user submissions, changelogs, and other data in JSON files.
# - Live preview: Provides a live preview of user-designed webpages with real-time updates.
# - Changelog tracking: Logs all changes made to templates, functions, and user data for auditing purposes.

# Routes:
# - "/" (Home): Displays the main form and user interface based on the current role.
# - "/login": Handles user login and sets session roles.
# - "/submit": Processes user submissions and saves them to a JSON file.
# - "/save_data": Saves user-designed webpage data to a JSON file.
# - "/load_test_dsl": Loads the current DSL script for editing.
# - "/save_test_dsl": Saves updates to the DSL script and reloads the application.
# - "/view_users": Displays a list of registered users (admin-only).
# - "/add_user": Provides a form for adding new users (admin-only).
# - "/create_user": Processes the addition of a new user (admin-only).
# - "/edit_user": Displays a form for editing an existing user (admin-only).
# - "/update_user": Processes updates to an existing user (admin-only).
# - "/delete_user": Deletes a user from the system (admin-only).
# - "/changelog": Displays a changelog of all actions performed (admin-only).
# - "/session_status": Displays active sessions with options to close individual sessions (admin-only).
# - "/close_session": Closes a specific session by ID (admin-only).
# - "/close_all_sessions": Ends all active web sessions and updates page status (admin-only).
# - "/shutdown": Gracefully shuts down the entire web server/page (admin-only).

# Templates:
# - :form_variant: A dynamic HTML template for rendering the main user interface with tabs and forms.
# - :contact_page: A simple contact form template.

# Helper Functions:
# - initialize_lists(file): Extracts templates and functions from the script for editing.
# - modify_file(file): Modifies the script file based on user input.
# - liveUpdateUserDesign(): JavaScript function for live preview of user-designed webpages.
# - log_change(editor, action, details): Logs changes to a JSON-based changelog.

# Usage:
# - Run the script and follow the prompts to select a role.
# - Admins can manage sessions, users, and view the changelog.
# - Editors can dynamically edit templates and functions.
# - Users can interact with the forms and submit data.

# Note:
# - Ensure required JSON files (e.g., users.json, changelog.json) exist in the working directory.
# - The application runs on port 4567 and requires the WebFramework module.
require 'cgi'
require_relative 'web_dsl'
include WebFramework

# Build the application and define routes.
$app = WebFramework.app do
  route "/login" do |req, res, sess|
    if req.method == "POST"
      role = req.query["role"] || "user"
      sess["role"] = role
      res.redirect("/")
    else
      res.status = 405
      "Method Not Allowed"
    end
  end  # closes the app block properly and returns the application

# Ask for user role.
puts "Enter your role (admin/user/editor):"
role = gets.chomp.strip.downcase
$current_role = role

# If the role is editor, allow modifications to this file.
if role == "editor"
  puts "\n-- Editor Mode --"
  file = "test_web_dsl.rb"
  puts "Opening #{file} for editing..."


@templates = []
@functions = []

def initialize_lists(file)
  content = File.read(file)
  @templates = content.scan(/define_template\s+:([a-zA-Z0-9_]+)/).flatten
  @functions = content.scan(/def\s+([a-zA-Z0-9_]+)/).flatten.uniq
end

# Initialize the lists when entering editor mode
initialize_lists(file)

  def modify_file(file)
    content = File.read(file)
    updated_content = yield(content)
    File.write(file, updated_content)
    puts "Changes saved to #{file}."
  end

  loop do
    puts "\n-- DSL Editor Menu --"
    puts "0. View Input Examples"
    puts "1. List templates/functions"
    puts "2. Add new template"
    puts "3. Add new function"
    puts "4. Remove template/function"
    puts "5. Modify template/function"
    puts "6. List all users from users.json"
    puts "7. View JSON-based changelog"
    puts "8. End All Web Sessions"
    puts "9. Shutdown Web Server"
    puts "10. Restart Application"
    puts "11. Exit Program"

    print "Choose an option: "
    choice = gets.chomp.strip

    case choice
    when "0"
      file = "editor_input_examples.json"
      if File.exist?(file)
        examples = JSON.parse(File.read(file))
        puts "\n--- Editor Input Examples ---\n\n"
        examples.each do |entry|
          entry.each do |key, value|
            puts "#{key}:"
            puts value.strip.gsub(/^/, '  ')
            puts "-" * 40
          end
        end
      else
        puts "No example input file found."
      end
    when "1"
      puts "\nTemplates:"
      puts @templates.empty? ? "  (none found)" : @templates.map { |t| "  - #{t}" }
      puts "\nFunctions:"
      puts @functions.empty? ? "  (none found)" : @functions.map { |f| "  - #{f}" }
    when "2"
      print "Enter new template name: "
      name = gets.chomp.strip.to_sym
      if @templates.include?(name.to_s)
        puts "Template '#{name}' already exists."
      else
        puts "Enter template HTML (end with EOF or Ctrl+D):"
        html = STDIN.read
        modify_file(file) do |content|
          content + "\n\ndefine_template :#{name} do\n  <<~HTML\n#{html.lines.map { |l| "    #{l}" }.join}  HTML\nend\n"
        end
        @templates << name.to_s
        log_change("Michael", "Added Template", { name: name })
        puts "Template '#{name}' added successfully."
      end
    when "3"
      print "Enter new function name: "
      fname = gets.chomp.strip
      puts "Enter Ruby code for the function (end with EOF or Ctrl+D):"
      code = STDIN.read
      modify_file(file) do |content|
        content + "\n\ndef #{fname}\n#{code.lines.map { |l| "  #{l}" }.join}end\n"
      log_change("Michael", "Added Function", { name: fname, fields: content })
      end
    when "4"
      print "Name of template or function to remove: "
      name = gets.chomp.strip
      if @templates.include?(name)
        modify_file(file) do |content|
          content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, '')
        end
        @templates.delete(name)
        log_change("Michael", "Removed Template", { name: name })
        puts "Template '#{name}' removed successfully."
      elsif @functions.include?(name)
        modify_file(file) do |content|
          content.gsub(/^\s*def\s+#{name}.*?^end\n/m, '')
        end
        @functions.delete(name)
        log_change("Michael", "Removed Function", { name: name })
        puts "Function '#{name}' removed successfully."
      else
        puts "No template or function found with the name '#{name}'."
      end
    when "5"
      print "Name of template/function to modify: "
      name = gets.chomp.strip
      if @templates.include?(name)
        puts "Enter the new HTML code (end with EOF or Ctrl+D):"
        new_code = STDIN.read
        modify_file(file) do |content|
          content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, "define_template :#{name} do\n  <<~HTML\n#{new_code.lines.map { |l| "    #{l}" }.join}  HTML\nend\n")
        end
        log_change("Michael", "Modified Template", { name: name })
        puts "Template '#{name}' modified successfully."
      elsif @functions.include?(name)
        puts "Enter the new Ruby code (end with EOF or Ctrl+D):"
        new_code = STDIN.read
        modify_file(file) do |content|
          content.gsub(/^\s*def\s+#{name}.*?^end\n/m, "def #{name}\n#{new_code.lines.map { |l| "  #{l}" }.join}end\n")
        end
        log_change("Michael", "Modified Function", { name: name })
        puts "Function '#{name}' modified successfully."
      else
        puts "No template or function found with the name '#{name}'."
      end
    when "6"
      file = "users.json"
      if File.exist?(file)
        users = JSON.parse(File.read(file))
        if users.empty?
          puts "\nNo users found."
        else
          puts "\n--- Users ---"
          users.each_with_index do |user, index|
            puts "\nUser ##{index + 1}:"
            puts "  Name: #{user['name']}"
            puts "  Email: #{user['email']}"
            puts "  Role: #{user['role'] || 'user'}"
            puts "  Submitted At: #{user['submitted_at']}"
          end
        end
      else
        puts "users.json not found."
      end
    when "7"
      if File.exist?("changelog.json")
        changelog = JSON.parse(File.read("changelog.json"))
        if changelog.empty?
          puts "No changes logged yet."
        else
          puts "\n--- Changelog Entries ---"
          changelog.each_with_index do |entry, i|
            puts "\nEntry ##{i + 1}:"
            puts "  Editor: #{entry["editor"] || entry["by"] || "N/A"}"
            puts "  Action: #{entry["action"]}"
            puts "  Timestamp: #{entry["timestamp"]}"
            details = entry["details"] || entry["detail"]
            if details
              puts "  Details:"
              if details.is_a?(Hash) || details.is_a?(Array)
                details.each do |k, v|
                  puts "    #{k}: #{v}"
                end
              else
                puts "    #{details}"
              end
            else
              puts "  Details: (none provided)"
            end
          end
        end
      else
        puts "changelog.json does not exist."
      end
    when "8"
      puts "Ending all web sessions..."
      close_all_sessions
      log_change("editor", "All Sessions Closed", "All active web sessions ended from editor console")
      puts "All active web sessions have been closed successfully."
      puts "Session end page active status: COMPLETED"
    when "9"
      print "Are you sure you want to shutdown the web server? (yes/no): "
      confirmation = gets.chomp.strip.downcase
      if confirmation == "yes"
        puts "Shutting down web server..."
        log_change("editor", "Server Shutdown", "Web server shutdown initiated from editor console")
        shutdown_server
        puts "Server shutdown initiated. Exiting editor mode."
        sleep(1)
        exit
      else
        puts "Shutdown cancelled."
      end
    when "10"
      puts "Restarting the application..."
      exec("ruby", "test_web_dsl.rb")
    when "11"
      puts "Exiting editor mode."
      exit
    else
      puts "Invalid choice. Try again."
    end
  end
end

  route "/submit" do |req, res, sess|
    submitted_data = normalize_submission_data(req)
  
    data = if File.exist?("submitted_data.json")
      begin
        content = File.read("submitted_data.json")
        content.strip.empty? ? [] : JSON.parse(content)
      rescue JSON::ParserError
        []
      end
    else
      []
    end
  
    data << submitted_data
    File.write("submitted_data.json", JSON.pretty_generate(data))
  
    # Format the submitted data as HTML for email
    email_body = <<~HTML
      <h2>New Form Submission</h2>
      <p><strong>Name:</strong> #{submitted_data[:name].html_escape}</p>
      <p><strong>Email:</strong> #{submitted_data[:email].html_escape}</p>
      <p><strong>About:</strong></p>
      <p>#{submitted_data[:about].html_escape.gsub("\n", "<br>")}</p>
      <p><strong>Project:</strong> #{submitted_data[:project].html_escape}</p>
      <p><strong>Description:</strong></p>
      <p>#{submitted_data[:description].html_escape.gsub("\n", "<br>")}</p>
      <p><strong>Priority:</strong> #{submitted_data[:priority].html_escape}</p>
      <p><strong>Page Title:</strong> #{submitted_data[:page_title].html_escape}</p>
      <p><strong>Background Color:</strong> #{submitted_data[:background_color].html_escape}</p>
      <p><strong>Include Email:</strong> #{submitted_data[:include_email] ? 'Yes' : 'No'}</p>
      <p><strong>Include Image:</strong> #{submitted_data[:include_image] ? 'Yes' : 'No'}</p>
      <p><strong>Layout Style:</strong> #{submitted_data[:layout_style].html_escape}</p>
      <p><strong>Submitted At:</strong> #{submitted_data[:submitted_at].html_escape}</p>
    HTML
    
    # Send email with submitted data
    email_result = send_email("pgwmichaelscott@gmail.com", email_body, "New Form Submission from #{submitted_data[:name]}")
    
    if email_result[:success]
      email_status = "<p style='color: green;'><strong>✓ Email sent successfully!</strong></p>"
    else
      email_status = "<p style='color: orange;'><strong>⚠ Submission saved, but email issue: #{email_result[:message].html_escape}</strong></p>"
    end
  
    res.status = 200
    "<p>Thank you, #{submitted_data[:name]}! Your submission has been saved.</p>#{email_status}"
  end

  route "/save_data" do |req, res, sess|
    fields = req.query
    images = req.query["images[]"] || []
    data = {
      heading: fields["heading"] || "",
      background: fields["background"] || "#ffffff",
      fields: JSON.parse(fields["fields"] || "[]"),
      images: images.is_a?(Array) ? images : [images]
    }
    File.write("user_display.json", data.to_json)
    "<h3>Data saved successfully!</h3><a href='/'>Go Back</a>"
  end

  # Welcome/Login Page Template
  define_template :welcome_login do
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
        <meta http-equiv="Pragma" content="no-cache">
        <meta http-equiv="Expires" content="0">
        <title>Welcome - Ruby-HTML DSL</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
          }
          .container {
            background: white;
            max-width: 500px;
            width: 100%;
            padding: 50px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            text-align: center;
          }
          .header {
            margin-bottom: 40px;
          }
          .header h1 {
            color: #333;
            font-size: 32px;
            margin-bottom: 10px;
          }
          .header p {
            color: #666;
            font-size: 16px;
          }
          .welcome-message {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            color: #555;
            line-height: 1.6;
          }
          .button-group {
            display: flex;
            flex-direction: column;
            gap: 15px;
          }
          .btn {
            padding: 14px 30px;
            font-size: 16px;
            font-weight: 600;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
            width: 100%;
          }
          .btn-login {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
          }
          .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          }
          .btn-register {
            background: white;
            color: #667eea;
            border: 2px solid #667eea;
          }
          .btn-register:hover {
            background: #f8f9fa;
            transform: translateY(-2px);
          }
          .divider {
            margin: 30px 0;
            color: #ccc;
            font-size: 14px;
          }
          .footer {
            font-size: 12px;
            color: #999;
            margin-top: 30px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎮 Welcome</h1>
            <p>Ruby-HTML DSL Platform</p>
          </div>
          
          <div class="welcome-message">
            <p>Welcome to the Ruby-HTML Website Manager! Please select an option to get started.</p>
          </div>
          
          <div class="button-group">
            <a href="/login" class="btn btn-login">Existing User - Login</a>
            <div class="divider">or</div>
            <a href="/register" class="btn btn-register">New User - Register</a>
          </div>
          
          <div class="footer">
            <p>Secure and easy authentication for all users.</p>
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  # Login Page Template
  define_template :login_page do
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
        <meta http-equiv="Pragma" content="no-cache">
        <meta http-equiv="Expires" content="0">
        <title>Login - Ruby-HTML DSL</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
          }
          .container {
            background: white;
            max-width: 450px;
            width: 100%;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .header h1 {
            color: #333;
            font-size: 28px;
            margin-bottom: 10px;
          }
          .header p {
            color: #666;
            font-size: 14px;
          }
          .form-group {
            margin-bottom: 20px;
          }
          label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
          }
          input[type="email"],
          input[type="text"] {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
          }
          input[type="email"]:focus,
          input[type="text"]:focus {
            outline: none;
            border-color: #667eea;
          }
          .error-message {
            display: none;
            padding: 12px;
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 6px;
            color: #856404;
            margin-bottom: 20px;
            font-size: 14px;
          }
          .error-message.show {
            display: block;
          }
          .success-message {
            display: none;
            padding: 12px;
            background: #d4edda;
            border: 1px solid #28a745;
            border-radius: 6px;
            color: #155724;
            margin-bottom: 20px;
            font-size: 14px;
          }
          .success-message.show {
            display: block;
          }
          button {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            margin-top: 10px;
          }
          button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          }
          button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
          }
          .footer {
            text-align: center;
            margin-top: 25px;
            font-size: 14px;
          }
          .footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
          }
          .footer a:hover {
            text-decoration: underline;
          }
          .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
          }
          .back-link:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <a href="/" class="back-link">← Back</a>
          
          <div class="header">
            <h1>Login</h1>
            <p>Welcome back! Please log in to continue.</p>
          </div>
          
          <div id="errorMessage" class="error-message"></div>
          <div id="successMessage" class="success-message"></div>
          
          <form id="loginForm" method="POST" action="/authenticate_user">
            <div class="form-group">
              <label for="email">Email Address</label>
              <input 
                type="email" 
                id="email" 
                name="email" 
                placeholder="Enter your email" 
                required
                autocomplete="email"
              >
            </div>
            
            <button type="submit">Login</button>
          </form>
          
          <div class="footer">
            Don't have an account? <a href="/register">Create one here</a>
          </div>
        </div>
        
        <script>
          const form = document.getElementById('loginForm');
          const errorMessage = document.getElementById('errorMessage');
          const successMessage = document.getElementById('successMessage');
          
          form.addEventListener('submit', function(e) {
            e.preventDefault();
            errorMessage.classList.remove('show');
            successMessage.classList.remove('show');
            
            const emailInput = document.getElementById('email');
            const email = emailInput.value.trim();
            
            if (!email) {
              errorMessage.textContent = 'Please enter your email address.';
              errorMessage.classList.add('show');
              return;
            }
            
            // Submit the form
            form.submit();
          });
        </script>
      </body>
      </html>
    HTML
  end

  # Registration Page Template
  define_template :register_page do
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
        <meta http-equiv="Pragma" content="no-cache">
        <meta http-equiv="Expires" content="0">
        <title>Register - Ruby-HTML DSL</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
          }
          .container {
            background: white;
            max-width: 450px;
            width: 100%;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .header h1 {
            color: #333;
            font-size: 28px;
            margin-bottom: 10px;
          }
          .header p {
            color: #666;
            font-size: 14px;
          }
          .form-group {
            margin-bottom: 20px;
          }
          label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
          }
          input[type="text"],
          input[type="email"] {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
          }
          input[type="text"]:focus,
          input[type="email"]:focus {
            outline: none;
            border-color: #667eea;
          }
          .error-message {
            display: none;
            padding: 12px;
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 6px;
            color: #856404;
            margin-bottom: 20px;
            font-size: 14px;
          }
          .error-message.show {
            display: block;
          }
          button {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            margin-top: 10px;
          }
          button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          }
          button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
          }
          .footer {
            text-align: center;
            margin-top: 25px;
            font-size: 14px;
          }
          .footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
          }
          .footer a:hover {
            text-decoration: underline;
          }
          .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
          }
          .back-link:hover {
            text-decoration: underline;
          }
          .info-text {
            background: #e7f3ff;
            padding: 12px;
            border-left: 4px solid #667eea;
            border-radius: 4px;
            font-size: 12px;
            color: #004085;
            margin-bottom: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <a href="/" class="back-link">← Back</a>
          
          <div class="header">
            <h1>Create Account</h1>
            <p>Welcome! Please create a new account.</p>
          </div>
          
          <div class="info-text">
            <strong>ℹ️ Note:</strong> Your account will be created with a standard "user" role. Contact an administrator for elevated privileges.
          </div>
          
          <div id="errorMessage" class="error-message"></div>
          
          <form id="registerForm" method="POST" action="/register_user">
            <div class="form-group">
              <label for="name">Full Name</label>
              <input 
                type="text" 
                id="name" 
                name="name" 
                placeholder="Enter your full name" 
                required
                autocomplete="name"
              >
            </div>
            
            <div class="form-group">
              <label for="email">Email Address</label>
              <input 
                type="email" 
                id="email" 
                name="email" 
                placeholder="Enter your email" 
                required
                autocomplete="email"
              >
            </div>
            
            <button type="submit">Create Account</button>
          </form>
          
          <div class="footer">
            Already have an account? <a href="/login">Login here</a>
          </div>
        </div>
        
        <script>
          const form = document.getElementById('registerForm');
          const errorMessage = document.getElementById('errorMessage');
          
          form.addEventListener('submit', function(e) {
            e.preventDefault();
            errorMessage.classList.remove('show');
            
            const nameInput = document.getElementById('name');
            const emailInput = document.getElementById('email');
            const name = nameInput.value.trim();
            const email = emailInput.value.trim();
            
            if (!name) {
              errorMessage.textContent = 'Please enter your full name.';
              errorMessage.classList.add('show');
              return;
            }
            
            if (!email) {
              errorMessage.textContent = 'Please enter your email address.';
              errorMessage.classList.add('show');
              return;
            }
            
            // Submit the form
            form.submit();
          });
        </script>
      </body>
      </html>
    HTML
  end

  define_template :form_variant do
    <<~HTML
      <html>
      <head>
        <meta charset="UTF-8">
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
        <meta http-equiv="Pragma" content="no-cache">
        <meta http-equiv="Expires" content="0">
        <title>Ruby-HTML DSL</title>
        <style>
          .tab { display: none; }
          .tab.active { display: block; }
          button.tab-btn { margin-right: 8px; }
          .carousel { display: flex; overflow-x: auto; gap: 10px; }
          .carousel img { max-height: 100px; border: 1px solid #ccc; border-radius: 6px; }
          .modal { 
            position: fixed; 
            background: 10%; 
            left: 50%; 
            top: 50%; 
            transform: translate(-50%, -50%); 
            width: 80%; 
            height: 80%; 
            background: #fff; 
            border: 2px solid #333; 
            overflow: auto; 
            z-index: 1000; 
            padding: 20px; 
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2); 
            border-radius: 8px;
          }
          .modal textarea { width: 100%; height: 80%; }
        </style>
        <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
        <script>
          function switchTab(id) {
            document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
            document.getElementById(id).classList.add('active');
            if (id === 'v5') {
              const userListDiv = document.getElementById('userList');
              if (userListDiv) {
                fetch('/view_users')
                  .then(res => res.text())
                  .then(html => {
                    userListDiv.innerHTML = html;
                  })
                  .catch(err => {
                    userListDiv.innerHTML = "<p>Error loading users.</p>";
                    console.error("Failed to load users:", err);
                  });
              } else {
                console.warn("User list container not found.");
              }
            }
          }
          function saveScreenshot() {
            html2canvas(document.body).then(canvas => {
              let link = document.createElement('a');
              link.download = 'screenshot.png';
              link.href = canvas.toDataURL();
              link.click();
            });
          }
          function liveUpdateUserDesign() {
            const heading = document.querySelector('[name="heading"]').value;
            const background = document.querySelector('[name="background"]').value;
            const headerColor = document.querySelector('[name="header_color"]').value;
            const fieldsInput = document.querySelector('[name="fields"]').value;
            const imageInput = document.querySelector('[name="image"]');

            let fields = [];
            try {
              fields = JSON.parse(fieldsInput);
            } catch (e) {
              // Invalid JSON, skip live render
            }

            const formElements = fields.map(f => {
              if (f.type === 'text') return `<input type='text' placeholder='${f.label}'><br>`;
              if (f.type === 'checkbox') return `<label><input type='checkbox'> ${f.label}</label><br>`;
              if (f.type === 'dropdown') {
                return `<label>${f.label}<select>${(f.options || []).map(o => `<option>${o}</option>`).join('')}</select></label><br>`;
              }
              return '';
            }).join('');

            const carousel = document.getElementById('carousel');
            const images = Array.from(imageInput.files).map(file => {
              const reader = new FileReader();
              const img = document.createElement('img');
              reader.onload = function (e) {
                img.src = e.target.result;
                carousel.appendChild(img);
              };
              reader.readAsDataURL(file);
              return img;
            });

            document.getElementById('user_output').innerHTML = `
              <h1 style="background:${background}; color:${headerColor}; font-weight: bold;">${heading}</h1>
              <form>${formElements}</form>
            `;
          }

          // Set up live event listeners
          document.addEventListener("DOMContentLoaded", () => {
            document.querySelector('[name="heading"]').addEventListener('input', liveUpdateUserDesign);
            document.querySelector('[name="background"]').addEventListener('input', liveUpdateUserDesign);
            document.querySelector('[name="header_color"]').addEventListener('input', liveUpdateUserDesign);
            document.querySelector('[name="fields"]').addEventListener('input', liveUpdateUserDesign);
            document.querySelector('[name="image"]').addEventListener('change', liveUpdateUserDesign);

            // Initial render
            liveUpdateUserDesign();
          });

          function openEditor() {
            fetch('/load_test_dsl')
              .then(r => r.text())
              .then(txt => {
                document.getElementById('editorTextarea').value = txt;
                document.getElementById('editorModal').style.display = 'block';
              });
          }
          function saveEditor() {
            const updated = document.getElementById('editorTextarea').value;
            fetch('/save_test_dsl', {
              method: 'POST',
              headers: {'Content-Type': 'application/json'},
              body: JSON.stringify({ updated })
            }).then(() => location.reload());
          }
        </script>
      </head>
      <body onload="liveUpdateUserDesign()">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; color: white; display: flex; justify-content: space-between; align-items: center; border-radius: 5px; margin-bottom: 20px;">
          <div>
            <h2 style="margin: 0; font-size: 24px;">Ruby-HTML DSL Platform</h2>
            <p style="margin: 5px 0 0 0; font-size: 14px;">Logged in as: <strong><%= @user_name || "User" %></strong> (<%= @user_email %>) - Role: <strong><%= @user_role %></strong></p>
          </div>
          <a href="/logout" style="background: white; color: #667eea; padding: 10px 20px; border-radius: 5px; text-decoration: none; font-weight: bold; cursor: pointer;">Logout</a>
        </div>
        
        <h2>Local Host Testing</h2>
        <div>
          <button class="tab-btn" onclick="switchTab('v1')">User Data</button>
          <button class="tab-btn" onclick="switchTab('v2')">Project Info</button>
          <button class="tab-btn" onclick="switchTab('v3')">Webpage Builder</button>
          <button class="tab-btn" onclick="switchTab('v4')">User Webpage</button>
          #{'<button class="tab-btn" onclick="switchTab(\'v5\')">Admin Controls</button>' if @user_role == 'admin'}
        </div>

        <form action="/submit" method="post" enctype="multipart/form-data">
          <div id="v1" class="tab active">
            <h3>Template Variant 1</h3>
            <input type="text" name="name" placeholder="Full Name"><br><br>
            <input type="email" name="email" placeholder="Email"><br><br>
            <textarea name="about" placeholder="About you..."></textarea>
          </div>
          <div id="v5" class="tab">
            <h3>Admin - User Management Panel</h3>
            <div id="userList">
              <p>Loading users...</p>
            </div>
            <button type="button" onclick="location.href='/add_user'">Add User</button>
            <hr>
            <h3>Session Management</h3>
            <p><strong>End web sessions:</strong></p>
            <button type="button" onclick="location.href='/session_status'">View/Close Sessions</button>
            <button type="button" onclick="if(confirm('Close all active sessions?')) location.href='/close_all_sessions'">End All Sessions</button>
            <hr>
            <h3>Web Page Control</h3>
            <p><strong>Close the entire web page:</strong></p>
            <button type="button" onclick="if(confirm('Shutdown the entire web server? This will close the page.')) location.href='/shutdown'" style="background-color: #ff6b6b; color: white; padding: 10px; border-radius: 5px; cursor: pointer; font-weight: bold;">🔴 Shutdown Web Server</button>
          </div>
          <div id="v2" class="tab">
            <h3>Template Variant 2</h3>
            <input type="text" name="project" placeholder="Project Title"><br><br>
            <textarea name="description" placeholder="Project Description"></textarea>
            <select name="priority">
              <option>Low</option>
              <option>Medium</option>
              <option>High</option>
            </select>
          </div>

          <div id="v3" class="tab">
            <h3>Webpage Display Builder</h3>
            <input type="text" name="heading" placeholder="Heading Text"><br><br>
            <h5>header background<h5>
            <input type="color" name="background" value="#ffffff"><br><br>
            <h5>header text<h5>
            <input type="color" name="header_color" value="#000000"><br><br>
            <h4>Add Fields:</h4>
            <textarea name="fields" placeholder='[{"type":"text","label":"Your Name"}, {"type":"checkbox","label":"Subscribe"}]' rows="6" cols="60"></textarea>
            <h4>Upload Image:</h4>
            <input type="file" name="image" accept="image/*" multiple><br><br>
          </div>

          <div id="v4" class="tab">
            <h3>User Design Preview</h3>
            <div id="user_output"></div>
            <div class="carousel" id="carousel"></div>
          </div>

          <br><br>
          <button type="submit">Submit</button>
          <button type="button" onclick="saveScreenshot()">Save Screenshot</button>
          #{'<button type="button" onclick="openEditor()">Edit DSL</button>' if @user_role == 'admin'}
        </form>
        <script>
          document.addEventListener("DOMContentLoaded", () => {
            const editorModal = document.getElementById('editorModal');
            const editorTextarea = document.getElementById('editorTextarea');

            document.querySelectorAll('button[onclick="openEditor()"]').forEach(button => {
              button.addEventListener('click', () => {
                fetch('/load_test_dsl')
                  .then(response => response.text())
                  .then(content => {
                    editorTextarea.value = content;
                    editorModal.style.display = 'block';
                  })
                  .catch(error => console.error('Error loading DSL:', error));
              });
            });

            document.querySelectorAll('button[onclick="saveEditor()"]').forEach(button => {
              button.addEventListener('click', () => {
                const updatedContent = editorTextarea.value;
                fetch('/save_test_dsl', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ updated: updatedContent })
                })
                  .then(() => {
                    editorModal.style.display = 'none';
                    location.reload();
                  })
                  .catch(error => console.error('Error saving DSL:', error));
              });
            });

            document.querySelectorAll('button[onclick="document.getElementById(\'editorModal\').style.display=\'none\'"]').forEach(button => {
              button.addEventListener('click', () => {
                editorModal.style.display = 'none';
              });
            });
          });
        </script>
        <div id="editorModal" class="modal" style="display:none;">
          <h3>Edit test_web_dsl.rb</h3>
          <textarea id="editorTextarea"></textarea><br>
          <h2>Saved changes will be shown on next page start<h2>
          <button onclick="saveEditor()">Save for reload</button>
          <button onclick="document.getElementById('editorModal').style.display='none'">Close</button>
        </div>
      </body>
      </html>
    HTML
  end

  # Welcome/Login Flow Routes
  
  # Welcome page - first landing page
  route "/welcome" do |req, res, sess|
    render(:welcome_login)
  end
  
  # Login page
  route "/login" do |req, res, sess|
    render(:login_page)
  end
  
  # Register page
  route "/register" do |req, res, sess|
    render(:register_page)
  end
  
  # Authenticate user - handles login
  route "/authenticate_user" do |req, res, sess|
    email = req.query["email"].to_s.strip.downcase
    
    if email.empty?
      res.status = 400
      next "Email is required."
    end
    
    users = load_users
    user = users.find { |u| u["email"].to_s.downcase == email }
    
    if user
      # User exists - set session and redirect to main app
      sess["authenticated"] = true
      sess["user_email"] = email
      sess["user_name"] = user["name"]
      sess["user_role"] = user["role"] || "user"
      sess["role"] = user["role"] || "user"
      
      log_change(user["name"], "Login", "User #{user['name']} (#{email}) logged in")
      
      "<script>
        setTimeout(function() {
          window.location.href = '/';
        }, 500);
      </script>
      <p>Login successful! Redirecting...</p>"
    else
      # User not found - show error with option to register
      error_html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>User Not Found</title>
          <style>
            body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              padding: 20px;
            }
            .container {
              background: white;
              max-width: 450px;
              width: 100%;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
              text-align: center;
            }
            .error-box {
              background: #fff3cd;
              border: 2px solid #ffc107;
              color: #856404;
              padding: 20px;
              border-radius: 8px;
              margin-bottom: 25px;
            }
            h2 {
              color: #333;
              margin-bottom: 10px;
            }
            p {
              color: #555;
              margin-bottom: 20px;
            }
            .button-group {
              display: flex;
              gap: 10px;
              flex-direction: column;
            }
            a, button {
              padding: 12px;
              font-size: 16px;
              font-weight: 600;
              border: none;
              border-radius: 8px;
              cursor: pointer;
              text-decoration: none;
              display: block;
              transition: all 0.3s;
            }
            .btn-register {
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
            }
            .btn-register:hover {
              transform: translateY(-2px);
              box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
            }
            .btn-back {
              background: white;
              color: #667eea;
              border: 2px solid #667eea;
            }
            .btn-back:hover {
              background: #f8f9fa;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-box">
              <h2>User Not Found</h2>
              <p>The email <strong>#{CGI.escapeHTML(email)}</strong> is not registered in our system.</p>
              <p>Would you like to create a new account?</p>
            </div>
            
            <div class="button-group">
              <a href="/register" class="btn-register">Create New Account</a>
              <a href="/login" class="btn-back">Try Another Email</a>
            </div>
          </div>
        </body>
        </html>
      HTML
      next error_html
    end
  end
  
  # Register new user
  route "/register_user" do |req, res, sess|
    name = req.query["name"].to_s.strip
    email = req.query["email"].to_s.strip.downcase
    
    # Validation
    if name.empty? || email.empty?
      res.status = 400
      next "Name and email are required."
    end
    
    users = load_users
    
    # Check if email already exists
    if users.any? { |u| u["email"].to_s.downcase == email }
      error_html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Email Already Registered</title>
          <style>
            body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              padding: 20px;
            }
            .container {
              background: white;
              max-width: 450px;
              width: 100%;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
              text-align: center;
            }
            .error-box {
              background: #f8d7da;
              border: 2px solid #f5c6cb;
              color: #721c24;
              padding: 20px;
              border-radius: 8px;
              margin-bottom: 25px;
            }
            h2 {
              color: #333;
              margin-bottom: 10px;
            }
            p {
              color: #555;
              margin-bottom: 20px;
            }
            .button-group {
              display: flex;
              gap: 10px;
              flex-direction: column;
            }
            a {
              padding: 12px;
              font-size: 16px;
              font-weight: 600;
              border: none;
              border-radius: 8px;
              cursor: pointer;
              text-decoration: none;
              display: block;
              transition: all 0.3s;
            }
            .btn-login {
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
            }
            .btn-login:hover {
              transform: translateY(-2px);
              box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
            }
            .btn-back {
              background: white;
              color: #667eea;
              border: 2px solid #667eea;
            }
            .btn-back:hover {
              background: #f8f9fa;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-box">
              <h2>Email Already Registered</h2>
              <p>The email <strong>#{CGI.escapeHTML(email)}</strong> is already associated with an account.</p>
              <p>Please log in or use a different email address.</p>
            </div>
            
            <div class="button-group">
              <a href="/login" class="btn-login">Go to Login</a>
              <a href="/register" class="btn-back">Try Different Email</a>
            </div>
          </div>
        </body>
        </html>
      HTML
      next error_html
    end
    
    # Create new user
    new_user = {
      "name" => name,
      "email" => email,
      "role" => "user",
      "submitted_at" => Time.now.utc.iso8601
    }
    
    users << new_user
    save_users(users)
    
    # Authenticate the new user
    sess["authenticated"] = true
    sess["user_email"] = email
    sess["user_name"] = name
    sess["user_role"] = "user"
    sess["role"] = "user"
    
    log_change(name, "Registration", "New user #{name} (#{email}) registered")
    
    success_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Account Created</title>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
          }
          .container {
            background: white;
            max-width: 450px;
            width: 100%;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            text-align: center;
          }
          .success-box {
            background: #d4edda;
            border: 2px solid #c3e6cb;
            color: #155724;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
          }
          h2 {
            color: #333;
            margin-bottom: 10px;
          }
          p {
            color: #555;
            margin-bottom: 20px;
          }
          .icon {
            font-size: 50px;
            margin-bottom: 15px;
          }
          a {
            padding: 12px 30px;
            font-size: 16px;
            font-weight: 600;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            text-decoration: none;
            display: inline-block;
            margin-top: 10px;
            transition: all 0.3s;
          }
          a:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          }
        </style>
        <script>
          setTimeout(function() {
            window.location.href = '/';
          }, 3000);
        </script>
      </head>
      <body>
        <div class="container">
          <div class="icon">✅</div>
          <div class="success-box">
            <h2>Account Created Successfully!</h2>
            <p>Welcome <strong>#{CGI.escapeHTML(name)}</strong>!</p>
            <p>Your account has been created with email <strong>#{CGI.escapeHTML(email)}</strong>.</p>
          </div>
          
          <p>Redirecting to the application in 3 seconds...</p>
          <a href="/">Continue Now</a>
        </div>
      </body>
      </html>
    HTML
    next success_html
  end
  
  # Logout route
  route "/logout" do |req, res, sess|
    if sess["user_name"]
      log_change(sess["user_name"], "Logout", "User #{sess["user_name"]} logged out")
    end
    
    # Clear authenticated session
    sess["authenticated"] = false
    sess["user_email"] = nil
    sess["user_name"] = nil
    sess["user_role"] = nil
    sess["role"] = nil
    
    res.status = 302
    res['Location'] = '/welcome'
    ""
  end

  # Home route - check if authenticated
  route "/" do |req, res, sess|
    # Check if user is authenticated
    unless sess["authenticated"]
      res.status = 302
      res['Location'] = '/welcome'
      next ""
    end
    
    # Set session role if not already defined
    sess["role"] ||= sess["user_role"] || "user"
    
    # Pass user info to template
    render(:form_variant, 
      user_name: sess["user_name"] || "User",
      user_email: sess["user_email"] || "",
      user_role: sess["user_role"] || "user"
    )
  end

  route "/user_display.json" do |req, res, sess|
    File.exist?("user_display.json") ? File.read("user_display.json") : "{}"
  end

  route "/load_test_dsl" do |req, res, sess|
    File.read("test_web_dsl.rb")
  end

  route "/save_test_dsl" do |req, res, sess|
    data = JSON.parse(req.body)
    File.write("test_web_dsl.rb", data["updated"])
    load "test_web_dsl.rb"
    "Saved and Reloaded"
  end

  route "/delete_user" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    index = req.query["index"].to_i
    users = load_users
    if user = users[index]
      users.delete_at(index)
      save_users(users)
      log_change(sess["role"], "Delete", "Removed user #{user['name']} (#{user['email']})")
      "<h3>User deleted successfully!</h3><a href='/'>Go Back</a>"
    else
      "<h3>User not found!</h3><a href='/'>Go Back</a>"
    end
  end

  route "/close_session" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    
    session_id = req.query["session_id"]
    if session_id
      if close_session(session_id)
        log_change(sess["role"], "Session Closed", "Closed session #{session_id}")
        "<h3>Session closed successfully!</h3><a href='/'>Go Back</a>"
      else
        "<h3>Session not found!</h3><a href='/'>Go Back</a>"
      end
    else
      "<h3>No session ID provided!</h3><a href='/'>Go Back</a>"
    end
  end

  route "/close_all_sessions" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    
    close_all_sessions
    log_change(sess["role"], "All Sessions Closed", "Closed all active web sessions")
    "<h3>All sessions closed successfully!</h3><em>Session end page active status updated.</em><br><a href='/'>Go Back</a>"
  end

  route "/session_status" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    
    active_sessions = get_active_sessions
    status_html = "<h3>Active Web Sessions: #{active_sessions.count}</h3>"
    
    if active_sessions.empty?
      status_html += "<p><em>No active sessions currently.</em></p>"
    else
      status_html += "<ul>"
      active_sessions.each do |session_id, info|
        created = info[:created_at].strftime("%Y-%m-%d %H:%M:%S")
        status_html += "<li>#{session_id[0..7]}... (Created: #{created}) <a href='/close_session?session_id=#{session_id}'>Close</a></li>"
      end
      status_html += "</ul>"
    end
    
    status_html += "<button onclick=\"location.href='/close_all_sessions'\">End All Sessions</button><br><br><a href='/'>Go Back</a>"
    status_html
  end

  route "/shutdown" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    
    log_change(sess["role"], "Server Shutdown", "Web page/server shutdown initiated by admin")
    
    # Schedule shutdown to happen after response is sent
    Thread.new { sleep(0.5); shutdown_server }
    
    # Redirect to server closed page
    res.status = 302
    res['Location'] = '/server_closed'
    res['Custom-Header'] = 'Redirect-to-closed'
    ""
  end

  route "/server_closed" do |req, res, sess|
    server_closed_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
        <meta http-equiv="Pragma" content="no-cache">
        <meta http-equiv="Expires" content="0">
        <title>Server Closed</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          .container {
            text-align: center;
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            max-width: 500px;
          }
          h1 {
            color: #ff6b6b;
            margin-top: 0;
          }
          .icon {
            font-size: 60px;
            margin-bottom: 20px;
          }
          p {
            color: #555;
            line-height: 1.6;
            margin: 20px 0;
          }
          .note {
            background: #f0f0f0;
            padding: 15px;
            border-left: 4px solid #667eea;
            margin: 20px 0;
            text-align: left;
            border-radius: 5px;
          }
          button {
            background: #667eea;
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            border-radius: 5px;
            cursor: pointer;
            margin-top: 20px;
          }
          button:hover {
            background: #764ba2;
          }
        </style>
        <script>
          // Prevent caching
          if (window.history && window.history.pushState) {
            window.history.pushState(null, null, window.location.href);
            window.onpopstate = function() {
              window.history.pushState(null, null, window.location.href);
            };
          }
          // Refresh every 5 seconds to check if server is back online
          setTimeout(function() {
            location.reload();
          }, 5000);
        </script>
      </head>
      <body>
        <div class="container">
          <div class="icon">🔴</div>
          <h1>Server Closed</h1>
          <p>The web server has been shut down.</p>
          <div class="note">
            <strong>ℹ️ Note:</strong><br>
            The back button will not work to return to previous pages. The server is offline.
          </div>
          <p style="font-size: 14px; color: #999;">
            This page will automatically refresh every 5 seconds to check if the server comes back online.
          </p>
          <button onclick="location.reload()">Check Again Now</button>
        </div>
      </body>
      </html>
    HTML
    
    server_closed_html
  end
  route "/add_user" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end

    <<~HTML
      <h3>Add New User</h3>
      <form action="/create_user" method="post">
        <label>Name:</label><br>
        <input type="text" name="name" required><br>
        <label>Email:</label><br>
        <input type="email" name="email" required><br>
        <label>Role:</label><br>
        <select name="role" required>
          <option value="user">User</option>
          <option value="admin">Admin</option>
          <option value="editor">Editor</option>
        </select><br><br>
        <button type="submit">Add User</button>
      </form>
      <a href="/">Cancel</a>
    HTML
  end

  route "/create_user" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end

    users = load_users
    new_user = {
      "name" => req.query["name"],
      "email" => req.query["email"],
      "role" => req.query["role"],
      "submitted_at" => Time.now.to_s
    }
    users << new_user
    save_users(users)
    log_change(sess["role"], "Add", "Added user #{new_user['name']} (#{new_user['email']}, #{new_user['role']})")
    "<h3>User added successfully!</h3><a href='/'>Go Back</a>"
  end

  route "/add_user_page" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end

    <<~HTML
      <h3>Add New User</h3>
      <form action="/create_user" method="post">
        <label>Name:</label><br>
        <input type="text" name="name" required><br>
        <label>Email:</label><br>
        <input type="email" name="email" required><br>
        <label>Role:</label><br>
        <select name="role" required>
          <option value="user">User</option>
          <option value="admin">Admin</option>
          <option value="editor">Editor</option>
        </select><br><br>
        <button type="submit">Add User</button>
      </form>
      <a href="/view_users">Back to User List</a>
    HTML
  end
  route "/view_users" do |req, res, sess|
    unless sess["role"] == "admin"
      res.status = 403
      return "<p>Access denied.</p>"
    end

    users = load_users

    if users.empty?
      "<p>No users found.</p>"
    else
      rows = users.each_with_index.map do |user, index|
        <<~ROW
          <tr>
            <td>#{CGI.escapeHTML(user["name"].to_s)}</td>
            <td>#{CGI.escapeHTML(user["email"].to_s)}</td>
            <td>#{CGI.escapeHTML((user["role"] || "user").to_s)}</td>
            <td>#{CGI.escapeHTML(user["submitted_at"].to_s)}</td>
            <td>
              <a href="/edit_user?index=#{index}">Edit</a> |
              <a href="/delete_user?index=#{index}" onclick="return confirm('Are you sure you want to delete this user?');">Delete</a>
            </td>
          </tr>
        ROW
      end.join

      <<~HTML
        <h3>Registered_Users_Table</h3>
        <table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">
          <thead style="background-color: #f2f2f2;">
            <tr>
              <th>Username</th>
              <th>Email</th>
              <th>Role</th>
              <th>Submitted At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
      HTML
    end
  end

  route "/edit_user" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    index = req.query["index"].to_i
    users = load_users
    if user = users[index]
      sess["edit_index"] = index
      <<~HTML
        <h3>Edit User</h3>
        <form action="/update_user" method="post">
          <label>Name:</label><br>
          <input type="text" name="name" value="#{CGI.escapeHTML(user["name"].to_s)}" required><br>
          <label>Email:</label><br>
          <input type="email" name="email" value="#{CGI.escapeHTML(user["email"].to_s)}" required><br>
          <label>Role:</label><br>
          <select name="role" required>
            <option value="user" #{'selected' if user["role"] == "user"}>User</option>
            <option value="admin" #{'selected' if user["role"] == "admin"}>Admin</option>
            <option value="editor" #{'selected' if user["role"] == "editor"}>Editor</option>
          </select><br><br>
          <button type="submit">Update</button>
        </form>
        <a href="/">Cancel</a>
      HTML
    else
      "<h3>User not found!</h3><a href='/'>Go Back</a>"
    end
  end

  route "/update_user" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    index = sess["edit_index"].to_i
    users = load_users
    if user = users[index]
      before = user.dup
      user["name"] = req.query["name"]
      user["email"] = req.query["email"]
      user["role"] = req.query["role"]
      save_users(users)
      log_change(sess["role"], "Edit", "Updated user #{before['name']} (#{before['email']}, #{before['role']}) → #{user['name']} (#{user['email']}, #{user['role']})")
      "<h3>User updated successfully!</h3><a href='/'>Go Back</a>"
    else
      "<h3>User not found!</h3><a href='/'>Go Back</a>"
    end
  end

  route "/changelog" do |req, res, sess|
    if sess["role"] != "admin"
      res.status = 403
      next "Unauthorized"
    end
    logs = load_changelog.reverse
    rows = logs.map do |log|
      <<~ROW
        <tr>
          <td>#{log["timestamp"]}</td>
          <td>#{log["action"]}</td>
          <td>#{log["detail"]}</td>
          <td>#{log["by"]}</td>
        </tr>
      ROW
    end.join
    <<~HTML
      <h2>Changelog</h2>
      <table border="1" cellpadding="5">
        <tr><th>Timestamp</th><th>Action</th><th>Detail</th><th>By</th></tr>
        #{rows}
      </table>
      <br><a href="/">Back</a>
    HTML
  end
end

# Start the server if the role is not editor
# (Editor mode runs in the console/terminal above)
if $current_role != "editor"
  puts "\n🚀 Starting Ruby-HTML DSL Web Server..."
  puts "📍 Access the application at: http://localhost:4567"
  puts "🔐 You will be prompted to log in or create an account."
  puts "📊 Available roles: admin, user, editor"
  puts "\n"
  $app.start(port: 4567)
end

def my_template
end


define_template :contact_page do
  <<~HTML
    \n<form>\n  <label>Name:</label><input type=\"text\" name=\"name\"><br>\n  <label>Email:</label><input type=\"email\" name=\"email\"><br>\n  <input type=\"submit\" value=\"Send\">\n</form>\n
  HTML
end
