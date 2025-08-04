namespace :db do
  namespace :memory do
    desc "Setup in-memory database for local testing"
    task setup: :environment do
      Rails.env = 'memory'
      
      # Load the schema
      Rake::Task['db:schema:load'].invoke
      
      # Seed the database if needed
      Rake::Task['db:seed'].invoke
      
      puts "In-memory database setup complete!"
    end
    
    desc "Run a Rails console with in-memory database"
    task console: :setup do
      # Start a console with the in-memory database
      ARGV.clear
      require 'irb'
      IRB.start
    end
    
    desc "Run the Rails server with in-memory database"
    task server: :setup do
      # Start the server with the in-memory database
      system("rails server -e memory")
    end
  end
end