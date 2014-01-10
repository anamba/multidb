#About MultiDB

MultiDB is a multitenant extension for Rails (or just ActiveRecord) that allows you to isolate each tenant into its own individual database without requiring major changes to your application code.

MultiDB is _not_ meant for systems that may have large numbers of tenants; you wouldn't want to have that many databases. It was designed for a system with 100-200 tenants, with the option to go to 1,000, and an absolute upper limit of 10,000. If you anticipate having more, MultiDB may not be an appropriate solution. (MySQL itself does not specify an upper limit on the number of databases, but it will be constrained by open file limits and, in some cases, directory entry limits.)

To minimize API changes for you, MultiDB patches ActiveRecord, ActionController and their associated rake tasks as needed to enable database switching at appropriate times and add support for three sets of schemas and migrations. ActiveRecord::SessionStore::Session has also been patched.

Internally, MultiDB refers to tenants as organizations. In addition to the organization databases, two additional databases are created: one is just for sessions, and the other is referred to as the master database, which houses the organizations table (tenants), and all other tables not associated with a particular organization. (Yes, it seems like these two additional databases could be combined, but it is a design decision intended to keep all essential data out of the default database. More on this later.)

MultiDB, when used with Rails (ActionController), determines which database to connect to at the beginning of each request by checking for `request.host`, `params[:org_code]`, then `session[:org_code]`. In a test environment, it can will also check the environment variable `RAILS_ORG`. If no organization code is found in any of those places, the sessions database is used (which is one reason it is important that no actual data be stored there).


## Versioning & Compatibility
MultiDB follows semantic versioning, but because it is closely tied to Rails/ActiveRecord, it uses the same major/minor version numbers to make it easy to determine which version of MultiDB to use. Patch numbers may vary.

### Rails & ActiveRecord
MultiDB 3.2 works with Rails 3.2. A new branch will be created to work with Rails 4.

The concept should work with just ActiveRecord (no Rails), but this use case has not been tested. (Pull requests welcome.)

### Database Adapters
Warning: MultiDB works only with mysql2 at present. If you are handy with Ruby, please help to add support for more adapters. See the "Contributing" section below.

MultiDB is known to work with [Makara](https://github.com/taskrabbit/makara) in a production environment.


##Get Started With MultiDB

Add it to your Gemfile:

    gem 'multidb', '~> 3.2.0'  # note: MultiDB 3.2 works with Rails 3.2

Or install by hand:

    gem install multidb

Then have your Organization class inherit from MultiDB::Organization. This gets you:

    Organization#connect(set_env = false)
    Organization#create_database
    Organization#drop_database!

Your table will need to have columns for `code` (string) and `active` (boolean), and to use the request.host feature, you will need organization_hosts as well. Recommended migration:

    create_table "organization_hosts", :force => true do |t|
      t.integer  "organization_id", :null => false
      t.string   "host",            :null => false
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
    end
    add_index "organization_hosts", ["host"], :name => "index_organization_hosts_on_host", :unique => true
    
    create_table "organizations", :force => true do |t|
      t.string   "name"
      t.string   "code",                         :null => false
      t.boolean  "active",     :default => true, :null => false
      t.datetime "created_at",                   :null => false
      t.datetime "updated_at",                   :null => false
    end
    add_index "organizations", ["code"], :name => "index_organizations_on_code", :unique => true


## Contributing

Pull requests welcome. Don't forget tests! When adding support for a new adapter, create a new Rails app for your adapter (e.g. `rails _3.2.16_ new testapp_postgresql`), customize database.yml and other files as needed, then add specs to that app.
