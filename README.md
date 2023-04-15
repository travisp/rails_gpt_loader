# Rails GPT Loader

RailsGptLoader is a Ruby gem that helps you generate a text representation of your Git repository, including only the necessary files for GPT-based analysis or processing. It helps you create a text version of your repository, which can be used as input for language models like OpenAI's GPT.

This gem was inspired by Michael Poon's [gpt-repository-loader](https://github.com/mpoon/gpt-repository-loader).

## Installation

To install RailsGptLoader and add it to your application's Gemfile, execute:

```ruby
gem 'rails_gpt_loader'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install rails_gpt_loader
```

## Usage
To use Rails GPT Loader, navigate to your Rails application directory and run the following command:

```bash
$ bundle exec rails_gpt_loader /path/to/git/repository
```

This command will create an `output.txt` file in the current directory, containing the relevant code from your Rails app.

By default, Rails GPT Loader will ignore any files listed in your `.gitignore` file (and files not checked into your git repository), empty or blank files, and a small list of files to ignore by default.

### Customization

By default, the output file will be named output.txt and will be located in the current directory. You can customize the output file path and other options when initializing the loader:

- `-o`: Optional: specify the output file path. Example: `-o path/to/output_file.txt`
- `-p`: Optional: specify a preamble file to prepend to the output file. Example: `-p path/to/preamble.txt`

Additionally, you can specify a list of files to ignore when generating the output file. This is useful if you want to ignore files that are checked into your git repository, but you don't want to include in the output file. To do this, create a file named `.gptignore` in the root directory of your Rails application. This file should contain a list of files to ignore, one per line.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can run tests using the `ruby -Ilib:test test/test_rails_gpt_loader.rb` command.

## Contributing

Bug reports and pull requests are welcome on Github at [https://github.com/travisp/rails_gpt_loader](https://github.com/travisp/rails_gpt_loader).

## License

The gem is available as open source under the terms of the MIT License.
