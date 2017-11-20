class WSLocalStorage < Hash
	def WSLocalStorage.new(identifier)
		$local ||= {}
		$local[identifier] ||= {}
		return $local[identifier]
	end
end
