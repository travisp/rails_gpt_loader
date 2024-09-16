require "find"
require "open3"
require "logger"
require "yaml"

module RailsGptLoader
  class Loader
    DEFAULT_IGNORE_LIST = [
      ".gitignore",
      "*.yml.enc",
      "*.key",
      "public/robots.txt",
      "bin/*",
      "CHANGELOG.md",
      "LICENSE.txt",
      "Gemfile.lock",
      "**.yml"
    ]

    FILE_PATTERNS = {
      backend: /(app\/models|app\/controllers|app\/helpers|app\/jobs)/,
      tests: /(spec|test)/,
      views: /(app\/views)/,
      configuration: /(config)/,
      lib: /(lib)/,
      stylesheets: /(app\/assets\/stylesheets)/,
      javascript: /(app\/assets\/javascripts|app\/javascript)/
    }

    def initialize(repo_path, options: {})
      @repo_path = repo_path
      @output_file_path = options.fetch(:output_file_path, "output.txt")
      @preamble_file = options.fetch(:preamble_file, nil)
      @config_file = File.join(repo_path, options[:config_file]) if options[:config_file]
      @options = load_options(options)
      @logger = Logger.new($stdout)
    end

    def load_options(cli_options)
      default_options = {
        include: {
          tests: false,
          views: false,
          configuration: false,
          backend: true,
          lib: false,
          stylesheets: false,
          javascript: false
        },
        exclude_files: [],
        include_files: [],
        remove_comments: false
      }

      if @config_file && File.exist?(@config_file)
        yaml_options = YAML.load_file(@config_file)
        default_options = deep_merge_hashes(default_options, deep_symbolize_keys(yaml_options))
      end

      deep_merge_hashes(default_options, deep_symbolize_keys(cli_options))
    end

    def deep_merge_hashes(first, second)
      merger = proc { |_, v1, v2|
        if Hash === v1 && Hash === v2
          v1.merge(v2, &merger)
        elsif Array === v1 && Array === v2
          v1 | v2
        else
          [:undefined, nil, :nil].include?(v2) ? v1 : v2
        end
      }
      first.merge(second, &merger)
    end

    def deep_symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        new_key = key.to_sym
        new_value = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
        result[new_key] = new_value
      end
    end

    def should_include?(file_path)
      # Priority: exclude_files explicitly specified, include_files explicitly specified
      # then our default ignore list, then the include patterns.
      return false if @options[:exclude_files].any? { |pattern| File.fnmatch(pattern, file_path) }
      return true if @options[:include_files].any? { |pattern| File.fnmatch(pattern, file_path) }
      return false if DEFAULT_IGNORE_LIST.any? { |pattern| File.fnmatch(pattern, file_path) }

      @options[:include].any? do |key, value|
        value && file_path.match?(FILE_PATTERNS[key])
      end
    end

    def git_tracked_files
      stdout, _stderr, _status = Open3.capture3("git -C #{@repo_path} ls-files")
      stdout.split("\n").reject { |file| file.start_with?(".") }
    end

    # Processes the repository, reads the preamble if provided, and writes the output file.
    def process_repository
      File.open(@output_file_path, "w") do |output_file|
        if @preamble_file
          File.open(@preamble_file, "r") do |pf|
            output_file.write(pf.read)
          end
        else
          output_file.write("The following text is a Git repository with code. The structure of the text are sections that begin with ----, followed by a single line containing the file path and file name, followed by a variable amount of lines containing the file contents. The text representing the Git repository ends when the symbols --END-- are encounted. Any further text beyond --END-- are meant to be interpreted as instructions using the aforementioned Git repository as context.\n")
        end

        git_tracked_files.each do |relative_file_path|
          file_path = File.join(@repo_path, relative_file_path)
          next if !should_include?(relative_file_path)
          next if empty_or_blank_file?(file_path)
          next if !text_file?(file_path)

          # relative_file_path = path.gsub("#{@repo_path}/", '')
          output_file.write("-" * 4 + "\n")
          output_file.write("#{relative_file_path}\n")
          output_file.write(process_file(file_path) + "\n")
        end

        output_file.write("--END--")
      end
    rescue => e
      @logger.error("Error processing repository: #{e.message}")
      @logger.error("Backtrace:\n#{e.backtrace.join("\n")}")
    end

    def process_file(file_path)
      content = safe_file_read(file_path)
      return content unless @options[:remove_comments]

      case file_path
      when /\.css\z/
        content.gsub(/(\s*\/\*.*?\*\/)/m, "")
      when /\.rb\z/
        content.gsub(/^\s*#.*$/, "")
      when /\.js\z/
        content.gsub(/^\s*\/\/.*$/, "")
      when /\.html\z/, /\.htm\z/, /\.html\.erb\z/
        content = content.gsub(/(\s*<!--.*?-->)/m, "")
        content.gsub(/(\s*<%#.*?%>)/m, "")
      else
        content
      end
    end

    # Safely reads a file's content, handling encoding issues.
    # @param file_path [String] the path to the file
    # @return [String] the file's content, or an empty string if there are encoding issues
    def safe_file_read(file_path)
      File.read(file_path, encoding: "UTF-8")
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      @logger.warn("Encoding issue with file '#{file_path}': #{e.message}. Skipping this file.")
    end

    def empty_or_blank_file?(file_path)
      content = File.read(file_path).strip
      content.empty?
    rescue Encoding::CompatibilityError
      false
    end

    def text_file?(file_path)
      begin
        output, status = Open3.capture2("file", file_path)

        if status.success?
          return output.include?("text")
        else
          @logger.warn("An error occurred running the file command to determine if a file is text or binary. Skipping file.")
          return false
        end
      rescue
        @logger.warn("An error occurred running the file command to determine if a file is text or binary. Skipping file.")
        return false
      end
      true
    end
  end
end
