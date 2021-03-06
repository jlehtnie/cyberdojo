require File.dirname(__FILE__) + '/../test_helper'
require 'GitDiff'

# > ruby test/functional/git_diff_view_tests.rb

class GitDiffViewTests < ActionController::TestCase

  include GitDiff
  
  ROOT_TEST_FOLDER = RAILS_ROOT + '/test/test_dojos'
  DOJO_NAME = 'Jon Jagger'
  # the test_dojos sub-folder for 'Jon Jagger' is
  # 38/1fa3eaa1a1352eb4bd6b537abbfc4fd57f07ab

  def root_test_folder_reset
    system("rm -rf #{ROOT_TEST_FOLDER}")
    Dir.mkdir ROOT_TEST_FOLDER
  end

  def make_params
    { :dojo_name => DOJO_NAME, 
      :dojo_root => ROOT_TEST_FOLDER,
      :filesets_root => RAILS_ROOT + '/filesets',
      'kata' => 'Unsplice',
      'language' => 'Ruby'
    }
  end

  #-----------------------------------------------

  def test_building_diff_view_from_git_repo
    root_test_folder_reset
    params = make_params
    assert Dojo::create(params)
    Dojo::configure(params)
    dojo = Dojo.new(params)
    avatar = Avatar.new(dojo, 'wolf')    
    # that will have created tag 0 in the repo

    manifest =
    {
      :visible_files =>
      {
        'cyberdojo.sh'     => { :content => cyberdojo_sh },
        'untitled.rb'      => { :content => untitled_rb },
        'test_untitled.rb' => { :content => test_untitled_rb },
        'output'           => { :content => '' }
      }
    }

    # create tag 1 in the repo
    avatar.run_tests(manifest)
    assert_equal :failed, avatar.increments.last[:outcome]

    # create tag 2 in the repo 
    manifest[:visible_files]['untitled.rb'][:content] = untitled_rb.sub('42', '54')
    avatar.run_tests(manifest)
    assert_equal :passed, avatar.increments.last[:outcome]
    
    tag = 2    
    view = git_diff_view(avatar, tag)
    view.delete('output')
    
    expected =
    {
      'untitled.rb' =>
      [
        { :line => "def answer", :type => :same,  :number => 1 },
        { :line => "  42",       :type => :deleted             },
        { :line => "  54",       :type => :added, :number => 2 },
        { :line => "end",        :type => :same,  :number => 3 },
      ],
      'test_untitled.rb' => sameify(test_untitled_rb),
      'cyberdojo.sh' => sameify(cyberdojo_sh)
    }
    
    assert_equal expected, view
    
  end

  #-----------------------------------------------

  def cyberdojo_sh
<<HERE
ruby test_untitled.rb
HERE
  end
  
  #-----------------------------------------------
  
  def test_untitled_rb 
<<HERE
require 'untitled'
require 'test/unit'

class TestUntitled < Test::Unit::TestCase

  def test_simple
    assert_equal 9 * 6, answer
  end

end
HERE
  end

  #-----------------------------------------------
  
  def untitled_rb
<<HERE
def answer
  42
end
HERE
  end  
  
end
