require 'set'
#Originally inspired by depgraph: https://github.com/dcadenas/depgraph

module DR
	class Node
		include Enumerable
		attr_reader :graph
		attr_accessor :name, :attributes, :parents, :children
		def initialize(name, attributes: {}, graph: nil)
			@name = name.to_s
			@children = []
			@parents = []
			@attributes = attributes
			@graph=graph
			graph.nodes << self if @graph
		end
		def each(&b)
			@children.each(&b)
		end
		def <=>(other)
			return @name <=> other.name
		end

		def ancestors
			self.graph.ancestors(self, ourselves: false)
		end
		def descendants
			self.graph.descendants(self, ourselves: false)
		end

		NodeError=Class.new(RuntimeError)
		def check_node(node)
			raise NodeError.new("wrong class: #{node.class}") unless node.is_a?(Node)
			raise NodeError.new("wrong graph: #{node.graph}") if self.graph != node.graph
		end

		def update_attributes(new_attr)
			@attributes.merge!(new_attr)
		end

		#self.add_child(ploum) marks ploum as a child of self (ie ploum depends on self)
		def add_child(*nodes)
			nodes.each do |node|
				check_node(node)
				if not @children.include?(node)
					@children << node
					node.parents << self
				end
			end
		end
		def rm_child(*nodes)
			nodes.each do |node|
				check_node(node)
				if @children.include?(node)
					@children.delete(node)
					node.parents.delete(self)
				end
			end
		end
		def add_parent(*nodes)
			nodes.each do |node|
				check_node(node)
				if not @parents.include?(node)
					@parents << node
					node.children << self
				end
			end
		end
		def rm_parent(*nodes)
			nodes.each do |node|
				check_node(node)
				if @parents.include?(node)
					@parents.delete(node)
					node.children.delete(self)
				end
			end
		end

		STEP = 4
		def to_s(show_attr: true)
			@name + (show_attr && ! attributes.empty? ? " #{attributes}" : "")
		end
		def inspect
			"#{self.class}: #{to_s(show_attr: true)}"+(graph.nil? ? "" : " (#{graph})")
		end
		# output like a graph
		def to_graph(indent_level: 0, show_attr: true, out: [])
			margin = ''
			0.upto(indent_level/STEP-1) { |p| margin += (p==0 ? ' ' : '|') + ' '*(STEP - 1) }
			margin += '|' + '-'*(STEP - 2)
			out << margin + "#{to_s(show_attr: show_attr)}"
			@children.each do |child|
				child.to_graph(indent_level: indent_level+STEP, show_attr: show_attr, out: out)
			end
			return out
		end
		def to_dot(out: [])
			out << "\""+name+"\""
			@children.each do |child|
				out <<  "\"#{@name}\" -> \"#{child.name}\""
				child.to_dot(out: out)
			end
			return out
		end
	end

	class Graph
		attr_accessor :nodes
		include Enumerable
		def initialize(*nodes, attributes: {}, infos: nil)
			@nodes=[]
			# a node can be a Hash or a Node
			build(*nodes, attributes: {}, infos: infos)
		end
		def each(&b)
			@nodes.each(&b)
		end

		def clone
			Graph.new.build(*all, recursive: false)
		end

		def to_a
			return @nodes
		end
		def to_hash(methods: [:children,:parents,:attributes], compact: true, recursive: true)
			require 'dr/base/converter'
			Converter.to_hash(@nodes, methods: methods, recursive: recursive, compact: compact)
		end

		def [](node)
			if node.is_a?(Node) and node.graph == self
				return node
			elsif node.is_a?(Node)
				name=node.name
			else
				name=node
			end
			@nodes.find {|n| n.name == name}
		end
		def to_h
			h=to_hash(methods: [:children])
			Hash[h.map {|k,v| [k.name, v.map(&:name)]}]
		end
		alias to_children to_h

		def to_children
			require 'dr/base/converter'
			Converter.to_hash(@nodes, methods:[:children], recursive: true, compact: true).map { |k,v| [k.name, v.map(&:name)]}.to_h
		end

		def inspect
			"#{self.class}: #{map {|x| x.to_s}}"
		end

		#construct a node (without edges)
		def new_node(node,**attributes)
			n=case node
			when Node
				node.graph == self ? node : new_node(node.name, **node.attributes)
			else
				@nodes.find {|n| n.name == node} || Node.new(node, graph: self)
			end
			n.update_attributes(attributes)
			n
		end

		# add a node (and its edges, recursively by default)
		# TODO in case of a loop this is currently non terminating when recursive
		# we would need to keep track of handled nodes
		def add_node(node, children: [], parents: [], attributes: {}, infos: nil, recursive: true)
			if infos.respond_to?(:call)
				info=infos.call(node)||{}
				children.concat([*info[:children]])
				parents.concat([*info[:parents]])
				attributes.merge!(info[:attributes]||{})
			end
			if node.is_a?(Node) and node.graph != self
				children.concat(node.children)
				parents.concat(node.parents)
			end
			graph_node=new_node(node,**attributes)
			if recursive
				graph_node.add_child(*children.map { |child| add_node(child) })
				graph_node.add_parent(*parents.map { |parent| add_node(parent) })
			else
				#just add the children
				graph_node.add_child(*children.map { |child| new_node(child) })
			end
			graph_node
		end

		#build from a list of nodes or hash
		def build(*nodes, attributes: {}, infos: nil, recursive: true)
			nodes.each do |node|
				case node
				when Hash
					node.each do |name,children|
						add_node(name,children: [*children], attributes: attributes, infos: infos, recursive: recursive)
					end
				else
					add_node(node, attributes: attributes, infos: infos, recursive: recursive)
				end
			end
			self
		end

		def all
			@nodes.sort
		end
		def roots
			@nodes.select{ |n| n.parents.length == 0}.sort
		end
		def bottom
			@nodes.select{ |n| n.children.length == 0}.sort
		end

		# allow a hash too
		def |(graph)
			graph=Graph.new(graph) unless Graph===graph
			build(*graph.all, recursive: false)
		end
		def +(graph)
			clone.|(graph)
		end

		def dump(mode: :graph, nodes_list: :roots, show_attr: true, out: [], **_opts)
			n=case nodes_list
				when :roots; roots
				when :all; all
				when Symbol; nodes.select {|n| n.attributes[:nodes_list]}
				else nodes_list.to_a
			end
			case mode
			when :graph; n.each do |node| node.to_graph(show_attr: show_attr, out: out) end
			when :list; n.each do |i| out << "- #{i}" end
			when :dot;
				out << "digraph gems {"
				#out << n.map {|node| node.to_dot}.inject(:+).uniq!.join("\n")
				n.map {|node| node.to_dot(out: out)}
				out << "}"
			end
			return out
		end

		def to_nodes(*nodes)
			nodes.map {|n| self[n]}.compact
		end

		#return the connected set containing nodes (following the direction
		#given)
		def connected(*nodes, down:true, up:true, ourselves: true)
			nodes=to_nodes(*nodes)
			onodes=nodes.dup
			found=[]
			while !nodes.empty?
				node=nodes.shift
				found<<node
				new_nodes=Set[node]
				new_nodes.merge(node.children) if down
				new_nodes.merge(node.parents) if up
				new_nodes-=(found+nodes)
				nodes.concat(new_nodes.to_a)
			end
			found-=onodes if !ourselves
			return found
		end
		#return all parents
		def ancestors(*nodes, ourselves: true)
			nodes=to_nodes(*nodes)
			connected(*nodes, up:true, down:false, ourselves: ourselves)
		end
		#return all childern
		def descendants(*nodes, ourselves: true)
			nodes=to_nodes(*nodes)
			connected(*nodes, up:false, down:true, ourselves: ourselves)
		end

		#from a list of nodes, return all nodes that are not descendants of
		#other nodes in the graph
		#needed: the nodes whose descendants we keep, by default the complement
		#of nodes
		def unneeded(*nodes, needed: nil)
			nodes=to_nodes(*nodes)
			if needed
				needed=to_nodes(needed)
			else
				needed=@nodes-nodes
			end
			unneeded=[]
			nodes.each do |node|
				unneeded << node if (ancestors(node) & needed).empty?
			end
			unneeded
		end
		#like unneeded(descendants(*nodes))
		#return all dependencies that are not needed by any more other nodes (except
		#the ones we are removing)
		#If some dependencies should be kept (think manual install), add them
		#to the needed parameter
		def unneeded_descendants(*nodes, needed:[])
			nodes=to_nodes(*nodes)
			needed=to_nodes(*needed)
			needed-=nodes #nodes to delete are in priority
			deps=descendants(*nodes)
			deps-=needed #but for children nodes, needed nodes are in priority
			unneeded(*deps)
		end
		#So to implement the equivalent of pacman -Rc packages
		#it suffices to add the ancestors of packages
		#For pacman -Rs, this is exactly unneeded_descendants
		#and pacman -Rcs would be unneeded_descendants(ancestors)
		#finally to clean all unneeded packages (provided we have a list of
		#packages 'tokeep' to keep), either use unneeded(@nodes-tokeep)
		#or unneeded_descendants(roots, needed:tokeep)

		#return the subgraph containing all the nodes passed as parameters,
		#and the complementary graph. The union of both may not be the full
		#graph [missing edges] in case the components are connected
		def subgraph(*nodes, complement: false)
			nodes=to_nodes(*nodes)
			subgraph=Graph.new()
			compgraph=Graph.new() if complement
			@nodes.each do |node|
				if nodes.include?(node)
					n=subgraph.new_node(node)
					node.children.each do |c|
						n.add_child(subgraph.new_node(c)) if nodes.include?(c)
					end
				else
					if complement
						n=compgraph.new_node(node)
						node.children.each do |c|
							n.add_child(compgraph.new_node(c)) unless nodes.include?(c)
						end
					end
				end
			end
			complement ? (return subgraph, compgraph) : (return subgraph)
		end

		def -(other)
			if other.is_a? Graph
				#in this case we want to remove the edges
				other.each do |n|
					self[n].rm_child(*n.children)
				end
			else
				#we remove a list of nodes
				nodes=@nodes-to_nodes(*other)
				subgraph(*nodes)
			end
		end

		#Graph.build(nodes,&b) allows to build a graph using &b
		#if recursive is true each time we get new nodes we add them to the graph
		#otherwise just run once
		#if recursive=0 we even restrict the graph to the current nodes
		#Note: to construct a graph from one node to a list it suffice to call
		#nodes.map(&b).reduce(:|)
		def self.build(nodes, recursive: true)
			g=yield(*nodes)
			g=Graph.new(g) unless g.is_a?(Graph)
			new_nodes=g.nodes.map(&:name)-nodes
			if recursive==0 and !new_nodes.empty?
				g-(new_nodes)
			elsif recursive
				while !new_nodes.empty?
					g2=yield(*new_nodes)
					g2=Graph.new(g2) unless g2.is_a?(Graph)
					g|g2
					nodes=nodes.concat(new_nodes)
					new_nodesg.nodes.map(&:name)-nodes
				end
				g
			else
				g
			end
		end
	end
end
