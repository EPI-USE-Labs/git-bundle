# Git-bundle

This gem simplifies working with [gems from git repositories](http://bundler.io/v1.5/git.html):
```ruby
gem 'some_gem_or_rails_engine', git: => 'https://github.com/author/some_gem_or_rails_engine.git'
```
in combination with [local overrides](http://bundler.io/v1.5/git.html#local):
```shell
bundle config local.some_gem_or_rails_engine /path/to/local/git/repository
```

## Usage examples

Let's say you have a Rails application that uses two of your own reusable Rails engines called "forum_engine" and
"blog_engine".  This is what your Gemfile looks like:
```ruby
gem 'forum_engine', git: 'https://github.com/your_name/forum_engine.git', branch: :master
gem 'blog_engine', git: 'https://github.com/your_name/blog_engine.git', branch: :master
```

You then add local overrides to your bundle config so that you can work on them like you would work on your main Rails
application with any change taking immediate effect:
```shell
bundle config local.some_gem_or_rails_engine /path/to/forum/git/repository
bundle config local.some_gem_or_rails_engine /path/to/blog/git/repository
```

### Running the same git command on all local overrides


### Committing and/or pushing changes

When you want to commit your changes, you need to commit the engine git repositories first and then run bundle install
in the main Rails application so that it updates the Gemfile.lock with the new git revisions.  Example Gemfile.lock entry:
```
GIT
  remote: https://github.com/your_name/forum_engine.git
  revision: b9270e61abb89e1ff77fb8cfacb463e4d04388ad
  branch: master
```

This gem combines these steps into one by detecting that your Gemfile.lock needs to be updated when you push your
changes.  It will run bundle install, add the Gemfile.lock to a new commit and push it with your other commits.  This is
what it would look like if you run **gitb push** in the main Rails application:

```shell
gitb push

=== forum_engine (master)
Counting objects: 11, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (13/13), done.
Writing objects: 100% (13/13), 2.42 KiB | 0 bytes/s, done.
Total 11 (delta 6), reused 0 (delta 0)
   ba4b3bf..ca4f753  master -> master

=== blog_engine (master)
Counting objects: 4, done.
Delta compression using up to 6 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (5/5), 2.42 KiB | 0 bytes/s, done.
Total 11 (delta 6), reused 0 (delta 0)
   ac1b3bf..b4bf753  master -> master

=== your-rails-application (master)
Local gems were updated. Building new Gemfile.lock with bundle install.

Counting objects: 13, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (12/12), done.
Writing objects: 100% (13/13), 2.32 KiB | 0 bytes/s, done.
Total 13 (delta 6), reused 0 (delta 0)
   ce2b3bf..f0bf753  master -> master
```

## Installation

You can install it yourself:

```shell
gem install git-bundle
```

Or alternatively add this line to your application's Gemfile:

```ruby
group :development do
    gem 'git-bundle'
end
```

Both should allow you to use the **gitb** command anywhere

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/EPI-USE-Labs/git-bundle.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).