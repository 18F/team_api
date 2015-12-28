require_relative 'test_helper'

module TeamApi
  class JoinProjectDataTest < ::Minitest::Test
    def setup
      config = {
        'source' => '/',
        'collections' => { 'projects' => { 'output' => true } },
      }
      @site = DummyTestSite.new config: config
      collection = @site.collections['projects']
      doc = ::Jekyll::Document.new(
        '/_projects/msb-usa.md', site: @site, collection: collection)
      doc.data.merge! 'name' => 'MSB-USA', 'status' => 'Hold'
      doc.data.delete 'draft'
      collection.docs << doc
    end

    def project_self_link(name)
      File.join Api.baseurl(@site), 'projects', name
    end

    def test_join_project
      Joiner.join_data @site
      assert_equal(
        { 'msb-usa' =>
          {
            'name' => 'MSB-USA', 'status' => 'Hold',
            'self' => project_self_link('msb-usa'),
            'categories' => []
          },
        },
        @site.data['projects'])
    end

    def test_hide_hold_projects_in_public_mode
      @site.config['public'] = true
      Joiner.join_data @site
      assert_empty @site.data['projects']
    end

    def project_data
      { 'name' => 'test_fm',
        'full_name' => 'project',
        'github' => ['test_fm'],
        'team' => %w(thing1 thing2 thing3),
        'stack' => %w(thing4 thing5),
        'owner_type' => 'project',
      }
    end

    def project_data_with_errors
      with_errors = project_data
      with_errors['errors'] = %w(error1 error2)
      with_errors
    end

    def error_joiner_impl(errors = {})
      @site.data['errors'] = errors
      JoinerImpl.new @site
    end

    def test_store_project_data_new_error
      joiner = error_joiner_impl
      project = project_data
      joiner.store_project_errors project, ['error!']
      assert_equal ['error!'], project['errors']
      assert_equal ['error!'], @site.data['errors']['test_fm']
    end

    def test_store_project_data_no_github
      joiner = error_joiner_impl
      project = project_data
      project.delete 'github'
      joiner.store_project_errors project, []
      assert_empty project['errors']
      assert_empty @site.data['errors']['test_fm']
    end

    def test_store_project_data_new_error_with_project_errors
      joiner = error_joiner_impl
      project = project_data_with_errors
      joiner.store_project_errors project, %w(error1 error2 error!)
      assert_equal %w(error1 error2 error!), project['errors']
      assert_equal %w(error1 error2 error!), @site.data['errors']['test_fm']
    end

    def test_store_project_data_new_error_with_other_data_errors
      joiner = error_joiner_impl('other_fm' => ['error!'])
      project = project_data_with_errors
      joiner.store_project_errors project, %w(error1 error2)
      assert_equal %w(error1 error2), project['errors']
      assert_equal %w(error1 error2), @site.data['errors']['test_fm']
      assert_equal ['error!'], @site.data['errors']['other_fm']
    end
  end
end
