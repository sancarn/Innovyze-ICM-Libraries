var fs = require('fs')
fs.readFile("..\\README.md", function(err,out){
	if(err) throw new Error(err)
	
	re = /^####? ([^ \r\n]+)/gm
	data = out.toString()
	while(m=re.exec(data)) console.log(m[1] + "\r")
})