var url = "https://rawgit.com/sancarn/Innovyze-ICM-Libraries/master/docs/Infoworks-ICM/README.md";
var request = new XMLHttpRequest(url);

if(window.text==undefined){
  request.open("GET", url, true);
  request.onreadystatechange = function(){
    if(this.readyState==4 && this.status == 200){
      analyse(this.responseText);
    }
  };
  request.send(null);
} else {
  analyse(window.text)
}


var analyse = function(text){
  window.text = text
  text = text.substr(/^InfoWorks ICM API Reference$/mi.exec(text).index); //Strip down to API Reference
  text = text.substr(0,/^Appendix$/m.exec(text).index);                   //Strip up to Appendix
  var lines = text.split("\n");
  var matches = []
  lines.forEach(function(line){
    var match_class = /^### (.+)$/i.exec(line)
    var match_method = /^#### \`(.+)\`.*$/.exec(line)
    
    if( match_class != null){
      console.log(match_class[1])
      matches.push(match_class[1])
    } else if(match_method!=null){
      console.log(match_method[1])
      matches.push("  " + match_method[1])
    }
  });
  
  console.clear()
  console.log(matches.join("\n"))
}
