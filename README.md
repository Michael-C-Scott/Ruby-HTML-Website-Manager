# Ruby-HTML-Website-Manager
The existing Ruby DSL has two files, the main file for defining the components: Templates, execution scope, html escaping, dsl entry point, and extension of the dsl for ease of use
Then there is the test file:  It contains the web templates definition for a home page(title, heading, message, tabs with other templates, user input fields, “Admin” specific fields) and user profile(name, email, user creation date, role). 
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
