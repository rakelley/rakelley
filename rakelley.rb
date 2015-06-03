# rakelley.rb
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class Rakelley < Sinatra::Base
  register Sinatra::Partial

  set :haml, :format => :html5, :ugly => true
  set :markdown, :layout_engine => :haml, :fenced_code_blocks => true

  helpers do
    # Get array of post URLs sorted by most recent, with optional limit
    def get_posts(count=nil)
      @files = Dir.glob("views/posts/*.md").sort
      if count
        @files = @files.last(count)
      end
      @files.reverse.map! {|s| s[/(\/posts\/[\w\-]+)(.md)/, 1].gsub('_', '/')}
    end

    # Assert file exists
    def must_exist(file_name)
      halt 404 unless File.exist?(file_name)
    end
  end

  get '/' do
    @layout_title = "Home"
    @posts = get_posts(5)
    haml :post_list do
      markdown :index
    end
  end

  get '/about' do
    @layout_title = "About Me"
    markdown :about
  end

  get '/posts' do
    @layout_title = "Recent Posts"
    @posts = get_posts()
    haml :post_list do
      markdown :posts_stub
    end
  end

  get '/posts/:year/:month/:day/:title' do
    @view = "posts/#{params[:year]}_#{params[:month]}_#{params[:day]}_#{params[:title]}"
    must_exist("views/#{@view}.md")
    @layout_title = params[:title].split('-').map(&:capitalize).join(' ')
    markdown @view.to_sym
  end

  get '/projects' do
    @layout_title = "Projects"
    markdown :project_list
  end

  get '/projects/:name' do
    must_exist("views/projects/#{params[:name]}.md")
    @layout_title = params[:name]
    markdown "projects/#{params[:name]}".to_sym
  end
end
