

suite('pr-handler', function() {
	var exampleJson = 
	setup(function(done) {
		done()
		fs.readFile('./json.txt', 'utf8', function(err, fileContents) {
		if (err) throw err;
			tests = JSON.parse(fileContents);
		});
	});

	test('should return -1 when not present', function() {
		
	});
});