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
		def to_s(show_attr: false)
			@name + (show_attr && ! attributes.empty? ? " #{attributes}" : "")
		end
		def inspect
			"#{self.class}: #{to_s(show_attr: true)}"+(graph.nil? ? "" : " (#{graph})")
		end
		def to_graph(indent_level: 0, show_attr: true)
			sout = ""
			margin = ''
			0.upto(indent_level/STEP-1) { |p| margin += (p==0 ? ' ' : '|') + ' '*(STEP - 1) }
			margin += '|' + '-'*(STEP - 2)
			sout += margin + "#{to_s(show_attr: show_attr)}\n"
			@children.each do |child|
				sout += child.to_graph(indent_level: indent_level+STEP, show_attr: show_attr)
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
		def initialize(*nodes, attributes: {}, infos: nil)
			@nodes=[]
			build(*nodes, attributes: {}, infos: infos)
		end
		def each(&b)
			@nodes.each(&b)
		end
		def to_a
			return @nodes
		end
		def to_h(methods: [:children,:parents,:attributes], compact: true, recursive: true)
			Converter.to_hash(@nodes, methods:methods, recursive: recursive, compact: compact)
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

		def to_children
			Converter.to_hash(@nodes, methods:[:children], recursive: true, compact: true).map { |k,v| [k.name, v.map(&:name)]}.to_h
		end

		def inspect
			"#{self.class}: #{map {|x| x.to_s}}"
		end

		#construct a node (without edges)
		def new_node(node,**attributes)
			n=case node
			when Node
				node.graph == self ? node : Node.new(node.name, graph: self, attributes: node.attributes)
			else
				@nodes.find {|n| n.name == node} || Node.new(node, graph: self)
			end
			n.update_attributes(attributes)
			n
		end

		#add a node (and its edges, recursively)
		def add_node(node, children: [], parents: [], attributes: {}, infos: nil)
			graph_node=new_node(node,**attributes)
			if infos.respond_to?(:call)
				info=infos.call(node)||{}
				children.concat([*info[:children]])
				parents.concat([*info[:parents]])
				attributes.merge!(info[:attributes]||{})
			end
			if node.is_a?(Node) and node.graph != self
				graph_node.add_child(* node.children.map {|c| add_node(c,**attributes)})
				graph_node.add_parent(* node.parents.map {|c| add_node(c,**attributes)})
			end
			graph_node.add_child(*children.map { |child| add_node(child) })
			graph_node.add_parent(*parents.map { |parent| add_node(parent) })
			graph_node
		end

		#build from a list of nodes or hash
		def build(*nodes, attributes: {}, infos: nil)
			nodes.each do |node|
				case node
				when Hash
					node.each do |name,children|
						add_node(name,children: [*children], attributes: attributes, infos: infos)
					end
				else
					add_node(node,**attributes, infos: infos)
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

		def dump(mode: :graph, nodes_list: :roots, show_attr: true, **unused)
			n=case nodes_list
				when :roots; roots
				when :all; all
				when Symbol; nodes.select {|n| n.attributes[:nodes_list]}
				else nodes_list.to_a
			end
			sout = ""
			case mode
			when :graph; n.each do |node| sout+=node.to_graph(show_attr: show_attr) end
			when :list; n.each do |i| sout+="- #{i}\n" end
			when :dot;
				sout+="digraph gems {\n"
				sout+=n.map {|node| node.to_dot}.inject(:+).uniq!.join("\n")
				sout+="}\n"
			end
			return sout
		end

		def to_nodes(*nodes)
			nodes.map {|n| self[n]}.compact
		end

		#return the connected set containing nodes (following the direction
		#given)
		def connected(*nodes, down:true, up:true)
			nodes=to_nodes(*nodes)
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
			return found
		end
		#return all parents
		def ancestors(*nodes)
			nodes=to_nodes(*nodes)
			connected(*nodes, up:true, down:false)
		end
		#return all childern
		def descendants(*nodes)
			nodes=to_nodes(*nodes)
			connected(*nodes, up:false, down:true)
		end

		#from a list of nodes, return all nodes that are not descendants of
		#other nodes in the graph
		#needed: the nodes whose descendants we keep
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
		#return all dependencies that are not needed by any more nodes, except
		#the ones we are removing
		#If some dependencies should be kept (think manual install), add them
		#to the unneeded parameter
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
		#graph [edges] in case the components are not connected
		def subgraph(*nodes)
			nodes=to_nodes(*nodes)
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
