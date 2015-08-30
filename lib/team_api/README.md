## 18F Team API Plugins

Plugins are used to create data joins and cross-references needed to produce
the API. The basic flow is:

* Join private data with public data
* Process snippet data
* Build cross-references between data elements
* Perform canonicalization of names and their ordering
* Generate API endpoints based on the joined, cross-referenced data

[generator.rb](generator.rb) is the entry point for this entire process. It
contains `TeamApi::Generator`, which performs all of the above steps in order.

### Data Joining

[joiner.rb](joiner.rb) contains the plugins that join public, private, and
local data into the `site.data` object.

### Cross-Referencing

[cross_referencer.rb](cross_referencer.rb) builds links between `site.data`
data collections which are used to generate cross-referenced pages.

### Canonicalization

[canonicalizer.rb](canonicalizer.rb) contains functions used to canonicalize
names and the sort order of collections in `site.data`.

### API Endpoint Generation

[api.rb](api.rb) generates all API endpoints and provides an index under
`/api`.
