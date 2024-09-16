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

You can also customize the included and excluded files using a `.gptconfig.yml` configuration file placed in the root directory of your Rails application. The configuration file should contain a dictionary with keys specifying which categories of files to include (e.g., `backend`, `tests`, `views`, `configuration`, `lib`, `stylesheets`, `javascript`) and values set to true or false. You can also specify additional files to exclude or include using exclude_files and include_files keys with lists of file patterns.

Here is an example of a `.gptconfig.yml` file:

```yaml
include:
  tests: false
  views: false
  configuration: false
  backend: true
  lib: false
  stylesheets: false
  javascript: false
exclude_files:
  - "db/seeds.rb"
  - "vendor/**/*"
include_files:
  - "lib/tasks/*.rake"
  ```

This configuration file will only include backend files and will exclude db/seeds.rb and all files in the vendor directory. It will also include all .rake files located in lib/tasks.

`exclude_files` will have precedence over `include_files`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can run tests using the `bundle exec rake test` command.

## Contributing

Bug reports and pull requests are welcome on Github at [https://github.com/travisp/rails_gpt_loader](https://github.com/travisp/rails_gpt_loader).

## License

The gem is available as open source under the terms of the MIT License.
