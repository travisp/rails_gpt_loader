require 'find'
require 'open3'

module RailsGptLoader
  class Loader
    def initialize(repo_path, output_file_path: 'output.txt', preamble_file: nil, gptignore_file: '.gptignore')
      @repo_path = repo_path
      @output_file_path = output_file_path
      @preamble_file = preamble_file
      @gptignore_file = File.join(repo_path, gptignore_file)
      @ignore_list = load_ignore_list
    end

    def load_ignore_list
      return [] unless File.exist?(@gptignore_file)

      File.readlines(@gptignore_file).map(&:strip)
    end

    def should_ignore?(file_path)
      @ignore_list.any? { |pattern| File.fnmatch(pattern, file_path) }
    end

    def git_tracked_files
      stdout, _stderr, _status = Open3.capture3("git -C #{@repo_path} ls-files")
      stdout.split("\n")
    end

    def process_repository
      File.open(@output_file_path, 'w') do |output_file|
        if @preamble_file
          File.open(@preamble_file, 'r') do |pf|
            output_file.write(pf.read)
          end
        else
          output_file.write("The following text is a Git repository with code. The structure of the text are sections that begin with ----, followed by a single line containing the file path and file name, followed by a variable amount of lines containing the file contents. The text representing the Git repository ends when the symbols --END-- are encounted. Any further text beyond --END-- are meant to be interpreted as instructions using the aforementioned Git repository as context.\n")
        end

        git_tracked_files.each do |relative_file_path|
          file_path = File.join(@repo_path, relative_file_path)
          next if should_ignore?(relative_file_path)

          #relative_file_path = path.gsub("#{@repo_path}/", '')
          output_file.write("-" * 4 + "\n")
          output_file.write("#{relative_file_path}\n")
          output_file.write(File.read(file_path) + "\n")
        end

        output_file.write("--END--")
      end
    end
  end
end
