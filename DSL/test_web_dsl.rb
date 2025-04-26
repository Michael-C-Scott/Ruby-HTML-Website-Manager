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
    puts "8. Restart Application"
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
      puts "Restarting the application..."
      exec("ruby", "test_web_dsl.rb")
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
        <h2>Local Host Testing</h2>
        <div>
          <button class="tab-btn" onclick="switchTab('v1')">User Data</button>
          <button class="tab-btn" onclick="switchTab('v2')">Project Info</button>
          <button class="tab-btn" onclick="switchTab('v3')">Webpage Builder</button>
          <button class="tab-btn" onclick="switchTab('v4')">User Webpage</button>
          #{'<button class="tab-btn" onclick="switchTab(\'v5\')">View Users</button>' if role == 'admin'}
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
          #{'<button type="button" onclick="openEditor()">Edit DSL</button>' if role == 'admin'}
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

# Start the server only if the role is admin or user.
if $current_role == "admin" || $current_role == "user"
  $app.start(port: 4567)
end

def my_template
end


define_template :contact_page do
  <<~HTML
    \n<form>\n  <label>Name:</label><input type=\"text\" name=\"name\"><br>\n  <label>Email:</label><input type=\"email\" name=\"email\"><br>\n  <input type=\"submit\" value=\"Send\">\n</form>\n
  HTML
end
