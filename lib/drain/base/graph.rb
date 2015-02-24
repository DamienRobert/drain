require 'set'
#Originally inspired by depgraph: https://github.com/dcadenas/depgraph

module DR
	class Node
		include Enumerable
		attr_reader :graph
		attr_accessor :name, :attributes, :parents, :children
		def initialize(name, attributes: nil, graph: nil)
			@name = name
			@children = []
			@parents = []
			@attributes = attributes
			@graph=graph
			graph.nodes << self if @graph
		end
		def each
			@children.each
		end
		def <=>(other)
			return @name <=> other.name
		end
		#self.add_child(ploum) marks ploum as a child of self (ie ploum depends on self)
		def add_child(*nodes)
			nodes.each do |node|
				if not @children.include?(node)
					@children << node
					node.parents << self
				end
			end
		end
		def rm_child(*nodes)
			nodes.each do |node|
				if @children.include?(node)
					@children.delete(node)
					node.parents.delete(self)
				end
			end
		end
		def add_parent(*nodes)
			nodes.each do |node|
				if not @parents.include?(node)
					@parents << node
					node.children << self
				end
			end
		end
		def rm_parent(*nodes)
			nodes.each do |node|
				if @parents.include?(node)
					@parents.delete(node)
					node.children.delete(self)
				end
			end
		end

		STEP = 4
		def to_s
			return @name
		end
		def to_graph(indent_level: 0)
			sout = ""
			margin = ''
			0.upto(indent_level/STEP-1) { |p| margin += (p==0 ? ' ' : '|') + ' '*(STEP - 1) }
			margin += '|' + '-'*(STEP - 2)
			sout += margin + "#{@name}\n"
			@children.each do |child|
				sout += child.to_graph(indent_level: indent_level+STEP)
			end
			return sout
		end
		def to_dot
			sout=["\""+name+"\""]
			@children.each do |child|
				sout.push  "\"#{@name}\" -> \"#{child.name}\""
				sout += child.to_dot
			end
			return sout
		end
	end

	class Graph
		attr_accessor :nodes
		include Enumerable
		def initialize(g=nil)
			@nodes=[]
			if g #convert a hash to a graph
				g.each do |name,children|
					n=build(name)
					n.add_child(*children)
				end
			end
		end
		def build(node, children: [], parents: [], **keywords)
			graph_node=
			case node
			when Node
				match = @nodes.find {|n| n == node} and return match
				Node.new(node.name, graph: self, **keywords.merge({attributes: node.attributes||keywords[:attributes]}))
				node.children.each do |c|
					build(c,**keywords)
				end
			else
				match = @nodes.find {|n| n.name == node}
				match || Node.new(node, graph: self, **keywords)
			end
			graph_node.add_child(*children.map { |child| build(child) })
			graph_node.add_parent(*parents.map { |child| build(child) })
			return graph_node
		end
		def each
			@nodes.each
		end
		def to_a
			return @nodes
		end
		def all
			@nodes.sort
		end
		def roots
			@nodes.select{ |n| n.parents.length == 0}.sort
		end
		def dump(mode: :graph, nodes_list: :roots, **unused)
			n=case nodes_list
				when :roots; roots
				when :all; all
				when Symbol; nodes.select {|n| n.attributes[:nodes_list]}
				else nodes_list.to_a
			end
			sout = ""
			case mode
			when :graph; n.each do |node| sout+=node.to_graph end
			when :list; n.each do |i| sout+="- #{i}\n" end
			when :dot;
				sout+="digraph gems {\n"
				sout+=n.map {|node| node.to_dot}.inject(:+).uniq!.join("\n")
				sout+="}\n"
			end
			return sout
		end

		#return the connected set containing nodes (following the direction
		#given)
		def connected(*nodes, down:true, up:true)
			r=Set.new()
			nodes.each do |node|
				unless r.include?(node)
					new_nodes=Set.new()
					new_nodes.merge(node.children) if down
					new_nodes.merge(node.parents) if up
					r.merge(connected(*new_nodes, down:down,up:up))
				end
			end
			return r
		end
		#return all parents
		def ancestors(*nodes)
			connected(*nodes, up:true, down:false)
		end
		#return all childern
		def descendants(*nodes)
			connected(*nodes, up:false, down:true)
		end

		#from a list of nodes, return all nodes that are not descendants of
		#other nodes in the graph
		def unneeded(*nodes)
			tokeep.merge(@nodes-nodes)
			nodes.each do |node|
				unneeded << node unless ancestors(node).any? {|c| tokeep.include?(c)}
			end
		end
		#return all dependencies that are not needed by any more nodes.
		#If some dependencies should be kept (think manual install), add them
		#to the unneeded parameter
		def unneeded_descendants(*nodes, needed:[])
			needed-=nodes #nodes to delete are in priority
			deps=descendants(*nodes)
			deps-=needed #but for children nodes, needed nodes are in priority
			unneeded(*deps)
		end
		#So to implement the equivalent of pacman -Rc packages
		#it suffices to add the ancestors of packages
		#For pacman -Rs, this is exactly unneeded_descendants
		#and pacman -Rcs would be ancestors(unneeded_descendants)
		#finally to clean all unneeded packages (provided we have a list of
		#packages 'tokeep' to keep), either use unneeded(@nodes-tokeep)
		#or unneeded_descendants(roots, needed:tokeep)

		#return the subgraph containing all the nodes passed as parameters,
		#and the complementary graph. The union of both may not be the full
		#graph [edges] in case the components are not connected
		def subgraph(*nodes)
			subgraph=Graph.new()
			compgraph=Graph.new()
			@nodes.each do |node|
				if nodes.include?(node)
					n=subgraph.build(node.name)
					node.children.each do |c|
						n.add_child(c) if nodes.include?(c)
					end
				else
					n=compgraph.build(node.name)
					node.children.each do |c|
						n.add_child(c) unless nodes.include?(c)
					end
				end
			end
			return subgraph, compgraph
		end

	end
end
