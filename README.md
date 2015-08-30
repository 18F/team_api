# 18F Team API

Compiles information about team members, projects, etc. and exposes it via a
JSON API.

Targeted consumers of this API include:

- [18F Hub](https://github.com/18F/hub)
- [18F Dashboard](https://github.com/18F/dashboard)
- [18F.gsa.gov](https://github.com/18F/18f.gsa.gov)

## Installation

This gem currently serves as a [Jekyll](https://jekyllrb.com/) plugin, though
it may become decoupled in the future. Presuming you're using
[Bundler](http://bundler.io) in your Jekyll project, add the following to your
`Gemfile`:

```ruby
group :jekyll_plugins do
  gem 'team_api'
end
```

Then, make sure to add an entry for `api_index_layout:` to your `_config.yml`
file. The index page will have an `endpoints` collection with one entry per
data collection, where each element has:

* `endpoint`: the URL of the collection's JSON endpoint
* `title`: title of the collection
* `description`: description of the collection

Here's a sample bare-bones template you can drop into your prefered layout:

```html
<h1>API Endpoint Index</h1>
<br/>{% for i in page.endpoints %}
<div class="api_endpoint_desc">
<h2><a href="{{ i.endpoint }}"<code>{{ i.endpoint }}</code></a> - {{ i.title }}</h2>
<p>{{ i.description }}</p>
</div>
{% endfor %}
```

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0
>dedication. By submitting a pull request, you are agreeing to comply
>with this waiver of copyright interest.
