# @author Mike Bland (michael.bland@gsa.gov)

require_relative 'api'
require 'hash-joiner'

module TeamApi
  class UnknownTeamMemberReferenceError < StandardError
  end

  class UnknownSnippetUsernameError < StandardError
  end

  # Joins the data from collections into +site.data+. Also filters out private
  # data when +site.config[+'public'] is +true+ (aka "public mode").
  class Joiner
    # Executes all of the steps to join the different data sources into
    # +site.data+ and filters out private data when in public mode.
    #
    # +site+:: Jekyll site data object
    def self.join_data(site)
      impl = JoinerImpl.new site
      site.data.merge! impl.collection_data
      impl.create_indexes
      impl.promote_or_remove_data
      impl.join_project_data
      Api.add_self_links site
      impl.join_snippet_data
    end
  end

  # Implements Joiner operations.
  class JoinerImpl
    attr_reader :site, :data, :public_mode

    # +site+:: Jekyll site data object
    def initialize(site)
      @site = site
      @data = site.data
      @public_mode = site.config['public']
    end

    def collection_data
      @collection_data ||= site.collections.map do |data_class, collection|
        groups = groups collection
        result = (groups[:public] || {})
        result.merge!('private' => groups[:private]) if groups[:private]
        [data_class, result] unless result.empty?
      end.compact.to_h
    end

    def groups(collection)
      collection.docs
        .select { |doc| doc.data['published'] != false }
        .group_by { |doc| doc_visibility doc }
        .map { |group, docs| [group, docs_data(docs)] }
        .to_h
    end

    def doc_visibility(doc)
      parent = File.basename File.dirname(doc.cleaned_relative_path)
      (parent == 'private') ? :private : :public
    end

    def docs_data(docs)
      docs.map { |doc| [doc.basename_without_ext, doc.data] }.to_h
    end

    def promote_or_remove_data
      private_data_method = public_mode ? :remove_data : :promote_data
      HashJoiner.send private_data_method, data, 'private'
    end

    def join_project_data
      # A little bit of project data munging. Can go away after the .about.yml
      # convention takes hold, hopefully.
      projects = (data['projects'] ||= {})
      projects.delete_if { |_, p| p['status'] == 'Hold' } if @public_mode
      projects.values.each { |p| join_team_list p['team'] }
    end

    def team
      data['team'] ||= {}
    end

    def create_indexes
      team_by_email
      team_by_github
    end

    # Returns an index of team member usernames keyed by email address.
    def team_by_email
      @team_by_email ||= team_index_by_field 'email'
    end

    # Returns an index of team member usernames keyed by email address.
    def team_by_github
      @team_by_github ||= team_index_by_field 'github'
    end

    # Returns an index of team member usernames keyed by a particular field.
    def team_index_by_field(field)
      team_members.map do |member|
        value = member[field]
        value = member['private'][field] if value.nil? && member['private']
        [value, member['name']] unless value.nil?
      end.compact.to_h
    end

    # Returns the list of team members, with site.data['team']['private']
    # members included.
    def team_members
      @team_members ||= team.map { |key, value| value unless key == 'private' }
        .compact
        .concat((team['private'] || {}).values)
    end

    # Replaces each member of team_list with a key into the team hash.
    # Values can be:
    # - Strings that are already team hash keys
    # - Strings that are email addresses
    # - Strings that are GitHub usernames
    # - Hashes that contain an 'email' property
    # - Hashes that contain a 'github' property
    def join_team_list(team_list)
      (team_list || []).map! do |reference|
        member = team_member_from_reference reference
        if member.nil?
          fail UnknownTeamMemberReferenceError, reference unless public_mode
        else
          member['name']
        end
      end.compact
    end

    def team_member_from_reference(reference)
      key = (reference.instance_of? String) ? reference : (
        reference['id'] || reference['email'] || reference['github'])
      team[key] || team[team_by_email[key] || team_by_github[key]]
    end

    SNIPPET_JOIN_FIELDS = %w(name full_name first_name last_name self)

    # Joins snippet data into +site.data[+'snippets'] and filters out snippets
    # from team members not appearing in +site.data[+'team'] or
    # +team_by_email+.
    def join_snippet_data
      raw_snippets = data['snippets']
      return if raw_snippets.nil?
      data['snippets'] = raw_snippets.map do |timestamp, snippets|
        joined = snippets.map { |snippet| join_snippet snippet }
          .compact.each { |i| i.delete 'username' }
        [timestamp, joined] unless joined.empty?
      end.compact.to_h
    end

    def join_snippet(snippet)
      username = snippet['username']
      member = team[username] || team[team_by_email[username]]

      if member.nil?
        fail UnknownSnippetUsernameError, username unless public_mode
      else
        member = member.select { |k, _| SNIPPET_JOIN_FIELDS.include? k }
        snippet.merge member
      end
    end
  end
end
