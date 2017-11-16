class WSLocalStorage < Hash
	def initialize(identifier)
		$local ||= {}
		$local[identifier] ||= {}
		self = $local[identifier]
	end
end
