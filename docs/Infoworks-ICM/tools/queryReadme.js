var url = "https://rawgit.com/sancarn/Innovyze-ICM-Libraries/master/docs/Infoworks-ICM/README.md";
var request = new XMLHttpRequest(url);
request.open("GET", url, true);
request.onreadystatechange = function(){
  if(this.readyState==4 && this.status == 200){
    analyse(this.responseText);
  }
};
request.send(null);


var analyse = function(text){
  window.text = text
  text = text.substr(/^InfoWorks ICM API Reference$/mi.exec(text).index); //Strip down to API Reference
  text = text.substr(0,/^Appendix$/m.exec(text).index);                   //Strip up to Appendix
  var lines = text.split("\n");
  var matches = []
  lines.forEach(function(line){
    var match_class = /^### (\w+)$/i.exec(line)[1]
    var match_method = /^#### \`(\w+)\`.+$/.exec(line)[1]
    
    if( match_class != nil){
      console.log(match_class)
      matches.push(match_class)
    } else if(match_method!=nil){
      console.log(match_method)
      matches.push(match_method)
    }
  });
  
  console.clear()
  console.log(matches.join("\n"))
}
