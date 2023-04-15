require "find"
require "open3"
require "logger"

module RailsGptLoader
  class Loader
    DEFAULT_IGNORE_LIST = [
      ".gitignore",
      "*.yml.enc",
      "*.key",
      "public/robots.txt",
      "bin/*",
      "CHANGELOG.md",
      "LICENSE.txt"
    ]

    # Initializes the Loader with the provided parameters and sets up the ignore list.
    # @param repo_path [String] the path to the repository
    # @param output_file_path [String] the path to the output file (default: 'output.txt')
    # @param preamble_file [String] the path to the optional preamble file (default: nil)
    # @param gptignore_file [String] the path to the optional .gptignore file (default: '.gptignore')
    def initialize(repo_path, output_file_path: "output.txt", preamble_file: nil, gptignore_file: ".gptignore")
      @repo_path = repo_path
      @output_file_path = output_file_path
      @preamble_file = preamble_file
      @gptignore_file = File.join(repo_path, gptignore_file)
      @ignore_list = load_ignore_list
      @logger = Logger.new($stdout)
    end

    # Loads the ignore list, merging the default ignore list, the custom ignore list, and the contents of the .gptignore file if it exists.
    # @param custom_ignore_list [Array] the list of additional file patterns to ignore
    # @return [Array] the combined ignore list
    def load_ignore_list
      return DEFAULT_IGNORE_LIST unless File.exist?(@gptignore_file)

      File.readlines(@gptignore_file).map(&:strip) + DEFAULT_IGNORE_LIST
    end

    def should_ignore?(file_path)
      @ignore_list.any? { |pattern| File.fnmatch(pattern, file_path) }
    end

    def git_tracked_files
      stdout, _stderr, _status = Open3.capture3("git -C #{@repo_path} ls-files")
      stdout.split("\n")
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
          next if should_ignore?(relative_file_path)
          next if empty_or_blank_file?(file_path)
          next unless text_file?(file_path)

          # relative_file_path = path.gsub("#{@repo_path}/", '')
          output_file.write("-" * 4 + "\n")
          output_file.write("#{relative_file_path}\n")
          output_file.write(safe_file_read(file_path) + "\n")
        end

        output_file.write("--END--")
      end
    rescue => e
      @logger.error("Error processing repository: #{e.message}")
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
    end

    def text_file?(file_path)
      begin
        output, status = Open3.capture2e("file", file_path)

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
