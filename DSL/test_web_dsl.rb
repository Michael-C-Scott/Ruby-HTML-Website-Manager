# test_web_dsl.rb
require_relative 'web_dsl'
include WebFramework

# Ask for user role.
puts "Enter your role (admin/user/editor):"
role = gets.chomp.strip.downcase

# Define a template for viewing users (accessible only to admin).
define_method :view_users do
  app.route('/view_users') do |req, res, sess|
    users = load_users
    html = "<h2>Admin - User Management Panel</h2>"
    if users.empty?
      html += "<p>No users found.</p>"
    else
      html += <<~HTML
        <table border='1' cellpadding='5'>
          <tr><th>Username</th><th>Email</th><th>Submitted At</th></tr>
      HTML
      users.each do |user|
        html += "<tr><td>#{user['name'].html_escape}</td><td>#{user['email'].html_escape}</td><td>#{user['submitted_at'].html_escape}</td></tr>"
      end
      html += "</table>"
    end
    html
  end
end

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
    updated = yield(content)
    File.write(file, updated)
    puts "Changes saved to #{file}."
  end

  loop do
    puts "\n-- DSL Editor Menu --"
    puts "1. List templates/functions"
    puts "2. Add new template"
    puts "3. Add new function"
    puts "4. Remove template/function"
    puts "5. Modify template/function"
    puts "6. Exit"

    print "Choose an option: "
    choice = gets.chomp.strip

    case choice
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
      end
    when "3"
      print "Enter new function name: "
      fname = gets.chomp.strip
      puts "Enter Ruby code for the function (end with EOF or Ctrl+D):"
      code = STDIN.read
      modify_file(file) do |content|
        content + "\n\ndef #{fname}\n#{code.lines.map { |l| "  #{l}" }.join}end\n"
      end
    when "4"
      print "Name of template or function to remove: "
      name = gets.chomp.strip
      modify_file(file) do |content|
        content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, '').
                gsub(/^\s*def\s+#{name}.*?^end\n/m, '')
      end
    when "5"
      print "Name of template/function to modify: "
      name = gets.chomp.strip
      puts "Enter the new code (end with EOF or Ctrl+D):"
      new_code = STDIN.read
      modify_file(file) do |content|
        content.gsub(/^\s*define_template\s+:#{name}\s+do.*?^end\n/m, "define_template :#{name} do\n  <<~HTML\n#{new_code.lines.map { |l| "    #{l}" }.join}  HTML\nend\n").
                gsub(/^\s*def\s+#{name}.*?^end\n/m, "def #{name}\n#{new_code.lines.map { |l| "  #{l}" }.join}end\n")
      end
    when "6"
      puts "Exiting editor mode."
      exit
    else
      puts "Invalid choice. Try again."
    end
  end
end

# Build the application and define routes.
app = WebFramework.app do
  define_template :form_variant do
    <<~HTML
      <html>
      <head>
        <title>Ruby-HTML DSL</title>
        <style>
          .tab { display: none; }
          .tab.active { display: block; }
          button.tab-btn { margin-right: 8px; }
          .carousel { display: flex; overflow-x: auto; gap: 10px; }
          .carousel img { max-height: 100px; border: 1px solid #ccc; border-radius: 6px; }
          .modal { position: fixed; top: 10%; left: 10%; width: 80%; height: 80%; background: #fff; border: 2px solid #333; overflow: auto; z-index: 1000; padding: 20px; }
          .modal textarea { width: 100%; height: 80%; }
        </style>
        <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
        <script>
          function switchTab(id) {
            document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
            document.getElementById(id).classList.add('active');
          }
          function saveScreenshot() {
            html2canvas(document.body).then(canvas => {
              let link = document.createElement('a');
              link.download = 'screenshot.png';
              link.href = canvas.toDataURL();
              link.click();
            });
          }
          function previewUserDesign() {
            fetch('/user_display.json')
              .then(res => res.json())
              .then(data => {
                document.getElementById('user_output').innerHTML = `
                  <h1 style="background:${data.background}; font-weight: bold;">${data.heading}</h1>
                  <form>
                    ${data.fields.map(f => {
                      if(f.type === 'text') return `<input type='text' placeholder='${f.label}'><br>`;
                      if(f.type === 'checkbox') return `<label><input type='checkbox'> ${f.label}</label><br>`;
                      if(f.type === 'dropdown') return `<label>${f.label}<select>${f.options.map(o => `<option>${o}</option>`).join('')}</select></label><br>`;
                      return '';
                    }).join('')}
                  </form>
                `;
                if (data.images) {
                  document.getElementById('carousel').innerHTML = data.images.map(src => `<img src="${src}" alt="carousel">`).join('');
                }
              });
          }
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
      <body onload="previewUserDesign()">
        <h2>Choose a Template Variant</h2>
        <div>
          <button class="tab-btn" onclick="switchTab('v1')">Page 1</button>
          <button class="tab-btn" onclick="switchTab('v2')">Page 2</button>
          <button class="tab-btn" onclick="switchTab('v3')">Webpage Display</button>
          <button class="tab-btn" onclick="switchTab('v4')">User Design</button>
          #{'<button class="tab-btn" onclick="switchTab(\'v5\')">View Users</button>' if role == 'admin'}
        </div>

        <form action="/save_data" method="post" enctype="multipart/form-data">
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
            <h4>Upload Images:</h4>
            <input type="file" name="images[]" multiple><br><br>
          </div>

          <div id="v4" class="tab">
            <h3>User Design Preview</h3>
            <div id="user_output"></div>
            <div class="carousel" id="carousel"></div>
          </div>

          #{'<div id="v5" class="tab"><h3>Admin - User Management Panel</h3><p>(Feature Placeholder)</p></div>' if role == 'admin'}

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
    if sess["role"] == "admin"
      render(:view_users)
    else
      "<h3>Access Denied</h3><p>You are not authorized to view this page.</p>"
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
if role == "admin" || role == "user"
  app.start(port: 4567)
end

def my_template
end
