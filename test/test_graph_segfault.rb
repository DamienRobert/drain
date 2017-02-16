class Node
	attr_accessor :name, :parents, :children
	def initialize(name)
		@name = name.to_s
		@children = []
		@parents = []
	end

	def add_child(node)
		if not @children.include?(node)
			@children << node
			node.parents << self
		end
	end
end

foo=Node.new("foo")
bar=Node.new("bar")
baz=Node.new("baz")
foo.add_child(bar)
bar.add_child(baz)
baz.add_child(foo)
