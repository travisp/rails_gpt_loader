# frozen_string_literal: true

require "test_helper"

class TestRailsGptLoader < Minitest::Test
  def setup
    @test_data_path = File.join(File.dirname(__FILE__), 'fixtures')
    @example_repo_path = File.join(@test_data_path, 'example_repo')
    @output_file_path = File.join(Dir.mktmpdir, 'output.txt')
  end

  def teardown
    FileUtils.remove_entry(File.dirname(@output_file_path))
  end

  def test_that_it_has_a_version_number
    refute_nil ::RailsGptLoader::VERSION
  end

  def test_end_to_end
    expected_output_file_path = File.join(@test_data_path, 'expected_output.txt')

    loader = RailsGptLoader::Loader.new(@example_repo_path, output_file_path: @output_file_path)
    loader.process_repository

    output_content = File.read(@output_file_path)
    expected_output_content = File.read(expected_output_file_path)

    assert_equal expected_output_content, output_content
  end

  def test_ignores_empty_files
    loader = RailsGptLoader::Loader.new(@example_repo_path, output_file_path: @output_file_path)
    loader.process_repository

    output_content = File.read(@output_file_path)

    # Check that the ignored files are not in the output
    refute_match /\.keep/, output_content
  end

  def test_ignores_gitignore_files
    loader = RailsGptLoader::Loader.new(@example_repo_path, output_file_path: @output_file_path)
    loader.process_repository

    output_content = File.read(@output_file_path)

    # Check that the ignored files are not in the output
    refute_match /\.gitignore/, output_content
  end

  def test_files_not_tracked_by_git_ignored
    File.write(File.join(@example_repo_path, 'app/models/tmp_files', 'NEW_FILE.rb'), "This is an new file.")

    loader = RailsGptLoader::Loader.new(@example_repo_path, output_file_path: @output_file_path)
    loader.process_repository

    output_content = File.read(@output_file_path)

    # Check that the ignored files are not in the output
    refute_match /NEW_FILE\.RB/, output_content

    File.delete(File.join(@example_repo_path, 'app/models/tmp_files', 'NEW_FILE.rb'))
  end
end
