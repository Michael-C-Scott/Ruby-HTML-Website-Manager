# test_web_dsl.rb
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
  end  # ✅ closes the app block properly and returns the application

# Ask for user role.
puts "Enter your role (admin/user/editor):"
role = gets.chomp.strip.downcase
$current_role = role

# If the role is editor, allow modifications to this file.
if role == "editor"
  puts "\n-- Editor Mode --"
  file = "test_web_dsl.rb"
  puts "Opening #{file} for editing..."


  def list_templates_and_functions(file)
    content = File.read(file)
    templates = content.scan(/define_template\s+:([a-zA-Z0-9_]+)/).flatten
    functions = content.scan(/def\s+([a-zA-Z0-9_]+)/).flatten.uniq - ["list_templates_and_functions"]
    return templates, functions
  end

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
    puts "8. Switch to page mode"
    puts "9. Exit Program"

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
      templates, functions = list_templates_and_functions(file)
      puts "\nTemplates:"
      puts templates.empty? ? "  (none found)" : templates.map { |t| "  - #{t}" }
      puts "\nFunctions:"
      puts functions.empty? ? "  (none found)" : functions.map { |f| "  - #{f}" }
    when "2"
      print "Enter new template name: "
      name = gets.chomp.strip.to_sym
      puts "Enter template HTML (end with EOF or Ctrl+D):"
      html = STDIN.read
      modify_file(file) do |content|
        content + "\n\ndefine_template :#{name} do\n  <<~HTML\n#{html.lines.map { |l| "    #{l}" }.join}  HTML\nend\n"
      log_change("Michael", "Added Template", { name: name, fields: content })
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
      modify_file(file) do |content|
        content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, '').
                gsub(/^\s*def\s+#{name}.*?^end\n/m, '')
      log_change("Michael", "Removed Function", { name: name })
      end
    when "5"
      print "Name of template/function to modify: "
      name = gets.chomp.strip
      puts "Enter the new code (end with EOF or Ctrl+D):"
      new_code = STDIN.read
      modify_file(file) do |content|
        content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, "define_template :#{name} do\n  <<~HTML\n#{new_code.lines.map { |l| "    #{l}" }.join}  HTML\nend\n").
                gsub(/^\s*def\s+#{name}.*?^end\n/m, "def #{name}\n#{new_code.lines.map { |l| "  #{l}" }.join}end\n")
      log_change("Michael", "Edited Template/Function", { name: name, changes: content })
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
            puts "  Editor: #{entry["editor"]}"
            puts "  Action: #{entry["action"]}"
            puts "  Timestamp: #{entry["timestamp"]}"
            puts "  Details: #{entry["details"].to_json}"
          end
        end
      else
        puts "changelog.json does not exist."
      end
    when "8"
      puts "Switching to page mode..."
      puts "Enter the new role (admin/user):"
      role = gets.chomp.strip.downcase
      if %w[admin user].include?(role)
        $current_role = role
        puts "Role switched to #{role}. Launching the webpage..."
        $app.start(port: 4567) # Start the web application on port 4567
      else
        puts "Invalid role. Please enter 'admin' or 'user'."
      end
    when "9"
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
  
    res.status = 200
    "<p>Thank you, #{submitted_data[:name]}! Your submission has been saved.</p>"
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

  define_template :form_variant do
    <<~HTML
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Ruby-HTML DSL</title>
        <style>
          .tab { display: none; }
          .tab.active { display: block; }
          button.tab-btn { margin-right: 8px; }
          .carousel { display: flex; overflow-x: auto; gap: 10px; }
          .carousel img { max-height: 100px; border: 1px solid #ccc; border-radius: 6px; }
          .modal { position: fixed; background: 10%; left: 10%; width: 80%; height: 80%; background: #fff; border: 2px solid #333; overflow: auto; z-index: 1000; padding: 20px; }
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
              <h1 style="background:${background}; font-weight: bold;">${heading}</h1>
              <form>${formElements}</form>
            `;
          }

          // Set up live event listeners
          document.addEventListener("DOMContentLoaded", () => {
            document.querySelector('[name="heading"]').addEventListener('input', liveUpdateUserDesign);
            document.querySelector('[name="background"]').addEventListener('input', liveUpdateUserDesign);
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
        <h2>Choose a Template Variant</h2>
        <div>
          <button class="tab-btn" onclick="switchTab('v1')">Page 1</button>
          <button class="tab-btn" onclick="switchTab('v2')">Page 2</button>
          <button class="tab-btn" onclick="switchTab('v3')">Webpage Display</button>
          <button class="tab-btn" onclick="switchTab('v4')">User Design</button>
          <button class="tab-btn" onclick="switchTab('v5')">View Users</button>
        </div>

        <form action="/submit" method="post" enctype="multipart/form-data">
          <div id="v1" class="tab active">
            <h3>Template Variant 1</h3>
            <input type="text" name="name" placeholder="Full Name"><br><br>
            <input type="email" name="email" placeholder="Email"><br><br>
            <textarea name="about" placeholder="About you..."></textarea>
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
            <input type="color" name="background" value="#ffffff"><br><br>
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

          #{'<div id="v5" class="tab-content" style="display: none;">
  <h2>Admin &ndash; User Management Panel</h2>
  <div id="userList">Loading users...</div>
</div>' if role == 'admin'}

          <br><br>
          <button type="submit">Submit</button>
          <button type="button" onclick="saveScreenshot()">Save Screenshot</button>
          #{'<button type="button" onclick="openEditor()">Edit DSL</button>' if role == 'admin'}
        </form>

        <div id="editorModal" class="modal" style="display:none;">
          <h3>Edit test_web_dsl.rb</h3>
          <textarea id="editorTextarea"></textarea><br>
          <button onclick="saveEditor()">Save and Reload</button>
          <button onclick="document.getElementById('editorModal').style.display='none'">Close</button>
        </div>
      </body>
      </html>
    HTML
  end

  # Home route.
  route "/" do |req, res, sess|
    # Set session role if not already defined.
    sess["role"] ||= role
    render(:form_variant)
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

  # Admin routes for managing users.
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
      "<h3>User deleted successfully!</h3><a href='/view_users'>Go Back</a>"
    else
      "<h3>User not found!</h3><a href='/view_users'>Go Back</a>"
    end
  end

  route "/view_users" do |req, res, sess|
    unless sess["role"] == "admin"
      res.status = 403
      return "<p>Access denied.</p>"
    end
  
    users = load_users
  
    html_content = "<div style='font-family: Arial, sans-serif; padding: 10px;'>"
    html_content += "<h2>Admin - User Management Panel</h2>"
  
    if users.empty?
      html_content += "<p>No users found.</p>"
    else
      html_content += <<~HTML
        <table border='1' cellpadding='5' cellspacing='0' style='border-collapse: collapse; width: 100%;'>
          <thead style='background-color: #f2f2f2;'>
            <tr>
              <th>Username</th>
              <th>Email</th>
              <th>Role</th>
              <th>Submitted At</th>
            </tr>
          </thead>
          <tbody>
      HTML
  
      users.each do |user|
        name = CGI.escapeHTML(user["name"].to_s)
        email = CGI.escapeHTML(user["email"].to_s)
        submitted = CGI.escapeHTML(user["submitted_at"].to_s)
        role = CGI.escapeHTML((user["role"] || "user").to_s)
        html_content += "<tr><td>#{name}</td><td>#{email}</td><td>#{role}</td><td>#{submitted}</td></tr>"
      end
  
      html_content += "</tbody></table>"
    end
  
    html_content += "</div>"
  
    # Apply layout rendering if it's set
    if @layout
      renderer = Object.new
      renderer.define_singleton_method(:capture) { html_content }
      renderer.instance_eval(&@layout)
    else
      html_content
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
      <h2>Edit User</h2>
      <form action="/update_user" method="post">
        <label>Name:</label><br>
        <input type="text" name="name" value="#{user["name"]}" required><br>
        <label>Email:</label><br>
        <input type="email" name="email" value="#{user["email"]}" required><br><br>
        <button type="submit">Update</button>
      </form>
      <a href="/view_users">Cancel</a>
      HTML
    else
      "<h3>User not found!</h3><a href='/view_users'>Go Back</a>"
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
      save_users(users)
      log_change(sess["role"], "Edit", "Updated user #{before['name']} (#{before['email']}) → #{user['name']} (#{user['email']})")
      "<h3>User updated successfully!</h3><a href='/view_users'>Go Back</a>"
    else
      "<h3>User not found!</h3><a href='/view_users'>Go Back</a>"
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

# Start the server only if the role is admin or user.
if $current_role == "admin" || $current_role == "user"
  $app.start(port: 4567)
end

def my_template
end
