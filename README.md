# Ruby-HTML-Website-Manager
The existing Ruby DSL has two files, the main file for defining the components: Templates, execution scope, html escaping, dsl entry point, and extension of the dsl for ease of use
Then there is the test file:  It contains the web templates definition for a home page(title, heading, message, tabs with other templates, user input fields, “Admin” specific fields) and user profile(name, email, user creation date, role). 

cgi:
The cgi library is used for handling Common Gateway Interface (CGI) tasks, such as parsing query parameters, managing form submissions, and encoding/decoding data for web applications. It is particularly useful for building web-based applications that need to process user input or interact with HTTP requests and responses.

webrick:
WEBrick is a lightweight HTTP server library included in Ruby's standard library. It allows developers to create web servers directly in Ruby, making it ideal for serving web pages, handling HTTP requests, and building APIs. In this context, it likely powers the backend of the DSL, enabling it to serve templates and handle user interactions.

json:
The json library provides tools for parsing and generating JSON (JavaScript Object Notation) data. JSON is a widely used format for data exchange between servers and clients. This library is likely used to handle configuration files, user data, or changelogs stored in JSON format.

mail:
The mail gem is a library for creating and sending emails in Ruby. It simplifies the process of composing emails, adding attachments, and sending them via SMTP or other protocols. This might be used in the application for features like sending notifications, user confirmations, or alerts.

securerandom:
The securerandom library is used to generate cryptographically secure random values, such as UUIDs, tokens, or random strings. This is useful for tasks like generating unique identifiers for users, sessions, or other application components where security is a concern.

Running the Program:
Typing ruby test_web_dsl.rb in the console with ruby and dependencies present will load the web page and allow for user input. 

Admin: Loads the full webpage with edit DSL and view user panels.

User: Loads the webpage without admin features.

Editor: Stays in the console to modify test_web_dsl.rb.


DSL Functions
web_templates do ... end
Begins a template collection block. Returns a TemplateManager.
define_template :name do ... end
Defines a named HTML template. You can use @variables passed into render.
render(:template_name, var1: value1, ...)
Renders a template, binding provided variables.
route '/path' do ... end
Defines a server route that serves rendered content.
layout do ... end
Optional layout wrapper for shared HTML (e.g., navigation, styling).
start(port: 4567)
Starts the built-in WEBrick web server.
validate_input(value)
Ensures that required fields are filled in.
update_user_data(user_input)
Stores user-submitted form data into user_data.json.

Interactivity Features
Form Inputs: Automatically mapped to params in routes
Tabbed Templates: User can toggle between multiple layouts/templates
Live Edits: Form content is editable live before submission

Output Features
✅ Save Input to JSON
✅ Send Template to Provided Email
✅ Take Screenshot (via JS frontend)
🖨 Export as PDF (optional enhancement)

Data Persistence
Submitted form data is saved to:
user_data.json
Screenshot captured via:
html2canvas in the frontend
