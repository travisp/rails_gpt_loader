# frozen_string_literal: true

require "test_helper"

class TestRailsGptLoader < Minitest::Test
  def setup
    @test_data_path = File.join(File.dirname(__FILE__), "fixtures")
    @example_repo_path = File.join(@test_data_path, "example_repo")
    @files_to_clean = []
  end

  def process(options = {})
    output_file_path = File.join(Dir.mktmpdir, "output.txt")
    options[:output_file_path] ||= output_file_path
    @files_to_clean << output_file_path
    loader = RailsGptLoader::Loader.new(@example_repo_path, options: options)
    loader.process_repository
    File.read(output_file_path)
  end

  def teardown
    @files_to_clean.each do |file_path|
      FileUtils.remove_entry(File.dirname(file_path))
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::RailsGptLoader::VERSION
  end

  def test_output_file_sections
    # Test if the generated output file contains the correct sections for each included file
    assert_match(/app\/models\/user\.rb/, process, "Output file should contain the correct section for user.rb")
    # Add more assertions for other files
  end

  def test_default_ignore_list
    # Test if the default ignore list works correctly
    output_content = process
    refute_match(/\.keep/, output_content, "Output file should not contain .keep files")
    refute_match(/\.gitignore/, output_content, "Output file should not contain .gitignore files")
  end

  def test_custom_output_file_path
    custom_output_file_path = File.join(Dir.mktmpdir, "custom_output.txt")
    @files_to_clean << custom_output_file_path
    custom_options = { output_file_path: custom_output_file_path }
    loader = RailsGptLoader::Loader.new(@example_repo_path, options: custom_options)
    loader.process_repository

    assert File.exist?(custom_output_file_path), "Custom output file should be generated"
  end

  def test_custom_preamble_file
    custom_preamble_file = File.join(@test_data_path, "custom_preamble.txt")
    custom_options = { preamble_file: custom_preamble_file }
    output_content = process(custom_options)

    assert_match(/This is a custom preamble/, output_content, "Output file should contain the custom preamble")
  end

  def test_text_file
    process
    assert @loader.text_file?(__FILE__), "This test file should be recognized as a text file"
    refute @loader.text_file?(File.join(@example_repo_path, "test_binary_file.bin")), "The binary file should not be recognized as a text file"
  end

  def test_ignores_empty_files
    # Check that the ignored files are not in the output
    refute_match(/\.keep/, process)
  end

  def test_ignores_gitignore_files
    # Check that the ignored files are not in the output
    refute_match(/\.gitignore/, process)
  end

  def test_files_not_tracked_by_git_ignored
    File.write(File.join(@example_repo_path, "app/models/tmp_files", "NEW_FILE.rb"), "This is an new file.")
    @files_to_clean << File.join(@example_repo_path, "app/models/tmp_files", "NEW_FILE.rb")

    # Check that the ignored files are not in the output
    refute_match(/NEW_FILE\.RB/, process)
  end
end