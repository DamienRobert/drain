== Release v0.5.1 (2020-02-18) ==

	* DR::URI -> DR::URIEscape

== Release v0.5 (2020-02-18) ==

	* Bump version
	* DR::URI.escape
	* Fixes for ruby 2.7
	* URI.encode is obsolete

== Release v0.4 (2019-09-13) ==

	* Bump version
	* Delegator.access_methods
	* delegate: add missing require
	* Delegator.delegate_h
	* Fix a bug in deep_merge
	* Utils: pretty = true means color by default
	* Utils: PPHelper and pretty_print colors
	* time_parse: do not load active_support/time
	* Fix test failures
	* Update Rakefile
	* Update Rakefile
	* Comments
	* graph: to_s and inspect
	* Doc: add warning

== Release v0.3.0 (2018-09-07) ==

	* Bump version
	* test_date_parse.rb: set TZ to GMT to get test working on travis
	* Update travis
	* Utils.rsplit
	* Formatter: clean ups
	* simple_formatter: ability to expand messages
	* Fix test
	* Ad formatter/simple_formatter
	* simple_keywords: strip by default + can now change delims
	* simple_keywords: switch from a Module to a Class
	* parse/simple_keywords
	* URI: rename to_s to to_ssh
	* URI::Ssh.parse: handle empty string
	* SSH Uri: allow non standard hosts
	* Hash#has_keys: bug fix
	* URIWrapper::Ssh
	* Hash#has_keys?
	* Hash#add_to_key: configure behavior via keywords
	* Hash#add_to_key, Hash#set_key
	* Hash#deep_merge: configure how to merge arrays
	* Hash#add_key
	* Hash: add_key, dig_with_default
	* bool.rb: allow to keep Strings/Symbols
	* slice_with_default
	* simple_parser: more parsing methods
	* bool: bug fixes
	* Copyright
	* Hash#reverse_merge
	* Graph#dump: be more flexible to how we dump
	* Graph: allow to merge with a Hash
	* to_caml_case and to_snake_case
	* pretty_print: preserve options
	* base: uri

== Release v0.2.0 (2018-02-01) ==

	* Bump version
	* Update tests
	* utils: pretty_print
	* eruby: add Eruby.process_eruby
	* Eruby: indent Context the same way as other modules
	* Move git.rb to git_helpers
	* fix somg bug in refinements usage
	* tests + more comments
	* graph: Add Graph.build
	* eruby: comments about a possible ruby bug fix in 2.4.1
	* graph: allow to merge graphs
	* graph: bug fixes
	* Eruby: automatically wrap into unbound_instance if a block is passed
	* eruby: streamline implementation and bug fixes
	* eruby: more template possibilities
	* eruby.rb: start adding features from Tilt
	* Eruby: be uniform accross erubi/erubis/erb
	* Clean up comments
	* test_drain: test for Drain::VERSION
	* Add drain.rb which calls dr.rb
	* travis: test agains ruby HEAD
	* Update drain.gemspec
	* Configure travis and streamline rake and test files
	* simple_parser: renders globalopts fully customisable
	* I don't need bundler for travis
	* travis
	* gitignore
	* Try to do a minimal example for ruby's segfault
	* descendants/ancestors: propagate ourselves
	* Correct a bug in graph.rb
	* parse_string: allows to customize the splitting characters
	* Remove Hash#set_keyed_value!
	* Hash#set_keyed_value
	* Copyright
	* simple_parser: document the splitting order
	* simple_parser: add tests
	* Add missing require
	* graph: allow ancestors and descendants on a node
	* Deprecation warning
	* Copyright
	* tests + comments
	* Still more tests for core_ext.rb
	* Still more tests
	* More tests
	* Test Hash#deep_merge
	* Add tests
	* Useless use of slef
	* Converter: test on recursive object
	* git: get config
	* Add Hash#leafs
	* Add to_h to graph
	* graph construction now accepts a lambda
	* Add hash conversion ton graph.rb
	* Add converter.rb (converts an object to an hash) and tests
	* graph: add .compact in to_nodes
	* graph: method to updat node attributes
	* graph: show attributes
	* Graph: improved unneeded, and bug fix in unneeded_descendants
	* Graph#connected: bug fix
	* Graph: check that children are of the same type
	* Refinements: fix syntax errors
	* unneeded_descendants(ancestors) is bigger than ancestors(unneeded_descendants)
	* graph: bug fixes
	* Use dr rather than drain for brevity
	* Graph.rb
	* Git: add a submodules command
	* Graph#build_node
	* Rework Graph#build
	* Test includes_extends_host_with
	* Split core_ext into two files

== Release v0.1.0 (2015-02-24) ==

	* Description
	* Add library files
	* Initial commit.

