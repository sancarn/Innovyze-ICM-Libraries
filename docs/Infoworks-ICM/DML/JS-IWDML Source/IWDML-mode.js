if(typeof(module)=="undefined") var module = {};
module.exports = (function(Empirler, callback){
    //the syntaxes{
    const langAcronyms = {js:"javascript"};
    const langList = ["abap","abc","actionscript","ada","apache_conf","asciidoc","assembly_x86","autohotkey","batchfile","c9search","c_cpp","cirru","clojure","cobol","coffee","coldfusion","csharp","css","curly","d","dart","dml", "diff","dockerfile","dot","dummy","dummysyntax","eiffel","ejs","elixir","elm","erlang","forth","ftl","gcode","gherkin","gitignore","glsl","golang","groovy","haml","handlebars","haskell","haxe","html","html_ruby","ini","io","jack","jade","java","javascript","json","jsoniq","jsp","jsx","julia","latex","less","liquid","lisp","livescript","logiql","lsl","lua","luapage","lucene","makefile","markdown","mask","matlab","mel","mushcode","mysql","nix","objectivec","ocaml","pascal","perl","pgsql","php","powershell","praat","prolog","properties","protobuf","python","r","rdoc","rhtml","ruby","rust","sass","scad","scala","scheme","scss","sh","sjs","smarty","snippets","soy_template","space","sql","stylus","svg","tcl","tex","text","textile","toml","twig","typescript","vala","vbscript","velocity","verilog","vhdl","xml","xquery","yaml"];
    
    //ace locations for serverside transpiling (relative path)
    var themePath = "Ace/lib/ace/theme/";
    var highlighterPath = "Ace/lib/ace/ext/static_highlight.js";
    var modePath = "Ace/lib/ace/mode/";
    
    //ace locations for clientside transpiling (absolute path)
    var themePathBuild = "Ace/build/theme-";
    var highlighterPathBuild = "Ace/build/ext-static_highlight.js";
    var modePathBuild = "Ace/build/mode-";
    var acePathBuild = "Ace/build/ace.js";
    
    var katexPath = "Katex/katex.js";
    var DMLhtmlPath = "DML.html";
    
    var themeName = "xcode";
    
    var highlighter;
    var theme;
    var themeCSS;
    var katex;
    var getMode;
    function initialiseLibraries(){
        var setupAce = function(){
            if(Empirler.runServerSide){
                require("amd-loader");
                var getTheme = function(){
                    Empirler.getLibrary(themePath+"/"+themeName+".js", function(resp){
                        theme = resp;
                        getHighlighter();
                    });
                };
                var getHighlighter = function(){
                    Empirler.getLibrary(highlighterPath, function(resp){
                        highlighter = resp;
                        themeCSS = highlighter.render("", undefined, theme).css;
                        setupKatex();
                    });
                };
                getMode = function(mode, callback){
                    Empirler.getLibrary(modePath+"/"+mode, function(mode){
                        callback(mode.Mode);  
                    });
                };
                getTheme();
            }else{
                //get ace, theme and highlighter
                var getAce = function(){
                    Empirler.getLibrary(acePathBuild, getTheme);
                };
                var getTheme = function(){
                    Empirler.getLibrary(themePathBuild+themeName+".js", getHighlighter);
                };
                var getHighlighter = function(){
                    Empirler.getLibrary(highlighterPathBuild, setupAceE);
                };
                var setupAceE = function(){
                    highlighter = ace.require("ace/ext/static_highlight");
                    theme = ace.require("ace/theme/"+themeName);   
                    themeCSS = highlighter.render("", undefined, theme).css;
                    
                    //a function to retrieve a specific language mode
                    var modes = {};
                    getMode = function(mode, callback){
                        if(!modes[mode]){
                            Empirler.getLibrary(modePathBuild+mode+".js", true, function(){
                                modes[mode] = true;
                                callback(ace.require("ace/mode/"+mode).Mode);    
                            });
                        }else{
                            callback(ace.require("ace/mode/"+mode).Mode);
                        }
                    }
                    setupKatex();
                }
                getAce();
            }   
        }
        var setupKatex = function(){
            //setup katex
            Empirler.getLibrary(katexPath, "katex", function(resp){
                katex = resp;
                setupSyntax();
            });
        }
        setupAce();
    }
    function setupSyntax(){
        //shorthand notation for common structures (bbcode)
        var getAttribute = function(match, name, validateRegex){
            var text = match.match[1]||"";;
            var regex = new RegExp("\\s"+name+"=('((\\\\.|[^'])*)'|\"((\\\\.|[^\"])*)\"|[^\\s\"]*)(\\s|$)", "i");
            var match = text.match(regex);
            if(match)
                if(match[2]!=null) match = match[2];
                else if(match[4]!=null) match = match[4];
                else match = match[1];
            
            if(validateRegex)
                return match&&match.match(validateRegex)? match: null;
            
            return match!=null? match: !!text.match(RegExp("(\\s|^)"+name+"(\\s|$)", "i"));
        };
        var getAtrributes = function(match){
            var regex = /\b(\w[^=]+)=?/g;
            var m;
            var attributes = [];
            while((m = regex.exec(match))){
                var key = m[1];
                var val = getAttribute({match:[0, match]}, key);
                
                attributes.push([key, val]);
                regex.lastIndex += (val.length||1);
            }
            return attributes;
        };
        var bb = [{
            normal: ["bb","BBcode"],
            selfClosing: ["cbb", "closingBBcode"],
            openingMatcher: function(data){
                return {
                    match:new RegExp("\\["+data+"(\\s(?:\\s*(?:=|\"(?:\\\\.|[^\"])*\"|'(?:\\\\.|[^'])*'|[^\\] =\"']*))*)?\\]", "i"),
                    getData: getAttribute, //get data is a special method and can be accessed through the node itself
                    getAttributes: getAtrributes //aby other defined mathods must be accessed through node.startMatch.exp.method
                };
            },
            deletionMatcher: function(data){
                return {match:/^( ){1,4}/, reset:/$/};
            },
            closingMatcher: function(data){
                return {
                    match:new RegExp("\\[\\/"+data+"(\\s(?:\\s*(?:=|\"(?:\\\\.|[^\"])*\"|'(?:\\\\.|[^'])*'|[^\\] =\"']*))*)?\\]", "i"),
                    getData: getAttribute,
                    getAttributes: getAtrributes
                };
            },
            openingReplacement: "",
            closingReplacement: ""
        }];
        
        //get width/height from tag
        function getWidth(tag, def){
            var width = tag.getData("width")||tag.getData("w")||def;
            if(!width) return false;
            if(!width.match(/(%|px|auto)$/)) width+="px";
            return width;
        }
        function getHeight(tag, def){
            var height = tag.getData("height")||tag.getData("h")||def;
            if(!height) return false;
            if(!height.match(/(%|px|auto)$/)) height+="px";
            return height;
        }
        
        
        var Syntax = Empirler.Syntax;
        var RuleSet = Empirler.RuleSet;
        var Rule = Empirler.Rule;
        
        var rUrl = /(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9]\.[^\s]{2,})/;
        var ruleSet = new RuleSet([new Rule({
                n: "escapement",
                o: /\\(.)/,
                or: "@1"
            }), new Rule({
                n: "comment",
                o: "[[",
                or: "",
                c: /$/,
                cr: "",
                dr: "",
                r: null,
            }), new Rule({
                n: "horizontal-line",
                o: "----",
                or: "<div class=horizontalLine></div>"
            }), new Rule({
                n:"quote",
                o: /^\s*\>\s*/,
                c: /$/,
                bb: "quote",
                or: "<div class=quote>",
                cr: "</div>"
            }, bb), new Rule({
                n: "lt",
                o: "<",
                or: "&lt;"
            }), new Rule({
                n: "gt",
                o: ">",
                or: "&gt;"
            }), new Rule({
                n: "linebreak",
                o: /`$/,
                or: "<br>"
            }), new Rule({
                n: "bold",
                o: {match:/\*([^* ])/, rep:"@1"},
                c: "*",
                bb: "b",
                or: "<b>",
                cr: "</b>",
            }, bb), new Rule({
                n: "italic",
                o: "|",
                c: "|",
                bb: "i",
                or: "<i>",
                cr: "</i>",
            }, bb), new Rule({
                n: "underline",
                o: "_",
                c: "_",
                bb: "u",
                or: "<u>",
                cr: "</u>",
            }, bb), new Rule({
                n: "strikethrough",
                o: "~",
                c: "~",
                bb: "s",
                or: "<s>",
                cr: "</s>",
            }, bb), new Rule({
                n: "html",
                bb: "html",
                r: null
            }, bb), new Rule({
                n: "text_align",
                o: /\[(center|right|left)((?:\s(?:\.|[^\]])*)?)\]/i,
                d: {match:/^( ){1,4}/, reset:/$/},
                c: /\[\/@1((?:\s(?:\.|[^\]])*)?)\]/i,
                or:'<div align="@1">',
                cr:'</div>',
            }), new Rule({
                n: "bullet_point",
                o: /(\*+) /,
                or: function(m,g1){
                    var bullets = ["&bullet;","&cir;","&squarf;","&rtrif;"];
                    return "<span>" + bullets[(g1.length-1) % bullets.length] + " </span>";
                },
            }), new Rule({
                n: "header",
                o: /(`)?(#+) ?/,
                bb: ["h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9", "h10"],
                c: /$/,
                or: function(){
                    var callback = arguments[arguments.length-1];
                    if(this.startMatch.match[0][1]=="h"){
                        this.type = Number(this.startMatch.match[0][2]);
                        this.visible = this.getData("visible")=="true";
                    }else{
                        this.type = this.startMatch.match[2].length;
                        this.visible = this.startMatch.match[1]==null;
                    }
                    
                    this.assembleContent(function(text){
                        if(this.visible)
                            this.id = this.input.addHeader(text, this.type);
                        callback("<h"+this.type+" id='"+this.id+"' visible="+this.visible+">");
                    });
                },
                cr: function(){
                    return "</h"+this.type+">";
                },
                r: {
                   r: ["indent"] 
                }
            }, bb), new Rule({
                n: "indent",
                o: /^( +)/,
                d: {match:/^@0/, reset:/$/},
                c: {match:/^/, not:/^@0/, offset:1}, //offset says that the closing should be at least 1 character removed from the deletion and start. otherwise this eleemnt would close after doing its own deletion.
                f: false, //also wrap if no closing is found
                or: function(m){return "<div class=tab style=margin-left:"+(m.length*10)+"px>"},
                cr: "</div>",
            }), new Rule({
                n: "youtube_video",
                bb: ["yt", "youtube"],
                r: null,
                or: function(m,g1){
                    var styled =this.getData("styled");
                    styled = styled?!((styled).match(/^(0|false)/)):true; //true by default
                    var width = getWidth(this, "640");
                    var start = this.getData("start");
                    var end = this.getData("end");
                    // var height = this.getData("height", /^\d+$/)||360;
                    var video  = /(?:v=|youtu.be\/|embed\/)([^\]\[\`&]+)/.exec(this.content[0]||this.getData("url"));
                    if(video){
                        video = video[1];
                        return "<iframe width=${width} "+(styled?"class=styled":"")+" ratio=16:9 src='https://www.youtube.com/embed/"+video+"?iv_load_policy=0&rel=0&showinfo=0"+(start!==false?"&start="+start:"")+(end!==false?"&end="+end:"")+"' iv_load_policy=0 rel=0 showinfo=0 frameborder=0 allowfullscreen></iframe>";
                    }
                    return "";
                },
                dr: ""
            }, bb), new Rule({
                n: "youtube_video_basic",
                o: /(?:https:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?.*v=|youtu\.be\/|youtube.com\/embed\/)([^\]\[\`&\r\n ]+)[^\r\n ]*/,
                or: function(m,g1){
                    return "<iframe width=640 ratio=16:9 class=styled src='https://www.youtube.com/embed/"+g1+"?iv_load_policy=0&rel=0&showinfo=0' frameborder=0 allowfullscreen></iframe>";
                }
            }), new Rule({
                n: "link_dictionary",
                bb: ["ld","linkDictionary"],
                or: "",
                dr: function(text){
                    var lines = text.split("\n");
                    for(var i=0; i<lines.length; i++){
                        var line = lines[i].split("=");
                        if(line.length>=2){
                            var key = this.trim(line[0]);
                            var value = this.trim(line[1]);
                            this.input.linkDictionary[key] = value;
                        }
                    }
                    return "";
                },
                cr: "",
                r: null
            }, bb), new Rule({
                n: "image",
                bb: ["img", "image"],
                r: null,
                or: function(m, g1){
                    var styled =this.getData("styled");
                    styled = styled?!((styled).match(/^(0|false)/)):true; //true by default
                    var width = getWidth(this, "640");
                    var name = this.getData("name")||"";
                    var hasPopup = (this.getData("hasPopup")||"true")!="false"; //defaults to true
                    var showName = (this.getData("showName")||"false")!="false"&&name;
                    // var height = this.getData("height", /^\d+$/)||360;
                    
                    var url = this.content[0]||this.getData("url");
                    if(showName){
                        return "<div class='image"+(styled?" styled":"")+"'>"+
                                    "<img src='"+url+"' class=image name='"+name+"' style=width:"+width+"; hasPopup='"+hasPopup+"'>"+
                                    name+
                                "</div>"; //height:"+height+"px;>";
                    }else{
                        return "<img src='"+url+"' class='image"+(styled?" styled":"")+"' name='"+name+"' style=width:"+width+"; hasPopup='"+hasPopup+"'>"; //height:"+height+"px;>";
                    }
                },
                dr: ""
            }, bb), new Rule({
                n: "codeblock",
                o: /```(\w*)\s*$/,
                or:"",
                cr:"",
                c: /\s*^```/,
                bb: "code",
                dr: function(){
                    var This = this;
                    var callback = arguments[arguments.length-1];
                    
                    var langM = this.getData("language")||this.getData("lang")||this.startMatch.match[1];
                    var title = this.getData("title")||this.getData("name")||null;
                    if(title) title = title.replace(/</g, "&lt;").replace(/>/g, "&gt;");
                    var origin = this.getData("origin")||null;
                    var preview = (this.getData("preview")||"false")!="false";
                    var previewWidth = this.getData("previewWidth")||"640";
                    var previewHeight = this.getData("previewHeight")||"360";
                        
                    var language = langAcronyms[langM]||langM;
                    if(langList.indexOf(language)==-1)
                        language = "text";
                    
                    getMode(language, function(mode){
                        This.assembleContent(function(text){
                            var highlighted = highlighter.render(This.cutDown(text), new mode(), theme);
                            var content = highlighted.html;
                            
                            if(title){
                                callback("<div class=codeBlock 0='"+JSON.stringify(language)+"'>"+
                                            "<div class=codeBlockHeader>"+
                                                "<div class=codeBlockName>"+
                                                    title+
                                                "</div>"+
                                                "<div class='codeBlockCopy fa fa-clone' title='Copy contents'></div>"+
                                                (origin?(
                                                    "<a class=codeBlockOrigin href='"+
                                                        origin+
                                                    "'></a>"
                                                ):"")+
                                                (preview?(
                                                    "<div class='codeBlockPreview fa fa-picture-o' previewWidth="+previewWidth+" previewHeight="+previewHeight+" title='Preview result'></div>"
                                                ):"")+
                                            "</div>"+
                                            "<div class=codeBlockContent>"+
                                                content+
                                            "</div>"+
                                        "</div>");
                            }else{
                                callback("<div class=codeBlock 0='"+JSON.stringify(language)+"'>"+
                                            "<div class=codeBlockContent>"+
                                                content+
                                            "</div>"+
                                        "</div>");
                            }
                        });
                    });
                },
                r: null
            }, bb), new Rule({
                n: "inline codeblock",
                o: /`(\w*) ?/,
                or:"",
                cr:"",
                c: /`/,
                bb: "c",
                dr: function(){
                    var This = this;
                    var callback = arguments[arguments.length-1];
                    
                    var langM = this.getData("language")||this.getData("lang")||this.startMatch.match[1];
                    var consumeFirst = langM==this.startMatch.match[1];;
                    var language = ((langAcronyms[langM]||langM)+"").toLowerCase();
                    if(langList.indexOf(language)==-1){
                        language = "text";
                        consumeFirst = false;
                    }
                        
                    getMode(language, function(mode){
                        This.assembleContent(function(text){
                            if(!consumeFirst && this.startMatch.expIndex>0)
                                text = This.startMatch.match[0].substring(1)+text;
                            
                            var highlighted = highlighter.render(This.cutDown(text), new mode(), theme, 1, true);
                            var content = "<div class='inline-codeblock " + highlighted.html.substring("<div class='".length);
                            callback(content);
                        });
                    });
                },
                r: null,
            }, bb), new Rule({
                n: "literal",
                bb: ["l", "literal"],
                r: {b: [new Rule({
                        n: "lt",
                        o: "<",
                        or: "&lt;"
                    }), new Rule({
                        n: "gt",
                        o: ">",
                        or: "&gt;"
                    }), new Rule({
                        n: "ampersand",
                        o: "&",
                        or: "&#38;"
                    })]
                }
            }, bb), new Rule({
                n: "linebreaks",
                bb: "linebreaks",
                r: [new Rule({
                    n: "crlf",
                    o: /\n/,
                    or: "<br>"
                })],
                dr: function(){
                    var callback = arguments[arguments.length-1];
                    this.assembleContent(function(text){
                        callback(text.replace("<br>","")); //removes the first new line  
                    });
                }
            }, bb), new Rule({
                n: "spoiler",
                bb: "spoiler",
                or: function(m, g1){
                    var callback = arguments[arguments.length-1];
                    
                    var text = this.getData("text")||"";
                    var shownText = this.getData("shownText")||"";
                    var hiddenText = this.getData("hiddenText")||"";
                    var shown = this.getData("shown")=="true"||false;
                    
                    var formatted = true;
                    this.filterChildren(function(child, cb){
                        if(child.rule.name=="spoiler_text"){
                            child.assemble(function(out){
                                text += out;
                                cb(true);
                            });
                        }else if(child.rule.name=="shown_spoiler_text"){
                            if(child.getData("plain")=="true") formatted = false;
                            child.assemble(function(out){
                                shownText += out;
                                cb(true);
                            });
                        }else if(child.rule.name=="hidden_spoiler_text"){
                            if(child.getData("plain")=="true") formatted = false;
                            child.assemble(function(out){
                                hiddenText += out;
                                cb(true);
                            });
                        }else{
                            return false;
                        }
                    }, false, function(){
                        if(formatted)
                            callback("<div class='spoilerText underlined'>"+
                                        "<i class='fa fa-eye'></i> "+
                                        text+
                                        (shownText?
                                            "<span class=shownSpoilerText style=display:"+(shown?"auto":"none")+">"+shownText+"</span>":"")+
                                        (hiddenText?
                                            "<span class=hiddenSpoilerText style=display:"+(shown?"none":"auto")+">"+hiddenText+"</span>":"")+
                                        "</div>"+
                                        "<div class=spoilerContent shown="+shown+" "+(!shown?"style=height:0px":"")+">");
                        else
                            callback("<div class='spoilerText'>"+
                                        text+
                                        (shownText?
                                            "<span class=shownSpoilerText style=display:"+(shown?"auto":"none")+">"+shownText+"</span>":"")+
                                        (hiddenText?
                                            "<span class=hiddenSpoilerText style=display:"+(shown?"none":"auto")+">"+hiddenText+"</span>":"")+
                                        "</div>"+
                                        "<div class=spoilerContent shown="+shown+" "+(!shown?"style=height:0px":"")+">"); 
                    });
                },
                cr: "</div>",
                r: {dca: [
                    new Rule({
                        n: "spoiler_text",
                        bb: "spoilerText"
                    }, bb), new Rule({
                        n: "shown_spoiler_text",
                        bb: "shownSpoilerText"
                    }, bb), new Rule({
                        n: "hidden_spoiler_text",
                        bb: "hiddenSpoilerText"
                    }, bb)
                ]}
            }, bb), new Rule({
                n: "p",
                bb: "p",
                or: "<div class=p>",
                cr: "<br style=clear:both></div>"
            }, bb), new Rule({
                n: "div",
                bb: "div",
                or: function(){
                    var float = this.getData("float");
                    var width = getWidth(this, "auto");
                    var styled =this.getData("styled");
                    var color = this.getData("color");
                    var fontSize = this.getData("fontSize");
                    
                    styled = styled?!((styled).match(/^(0|false)/)):true; //true by default
                    return "<div class='div"+
                        (styled?" styled":"")+
                        "' style=width:"+width+";float:"+float+";"+
                            (color?"color:"+color+";":"")+
                            (fontSize?"font-size:"+fontSize+"px;":"")+
                    ">";
                },
                cr: "</div>"
            }, bb), new Rule({
                n: "iframe",
                bb: "iframe",
                or: function(){
                    var styled =this.getData("styled");
                    styled = styled?!((styled).match(/^(0|false)/)):true; //true by default
                    var width = getWidth(this, "640");
                    var height = getHeight(this, "360");
                    var url = this.content[0]||this.getData("url");
                    
                    return "<iframe src='"+url+"' class='iframe "+(styled?" styled":"")+"' style=width:"+width+";height:"+height+"></iframe>";
                },
                dr: "",
            }, bb), new Rule({
                n: "table",
                bb: "table",
                or: function(){
                    var styled =this.getData("styled");
                    styled = styled?!((styled).match(/^(0|false)/)):true; //true by default
                    return "<table cellspacing='0' "+(styled?"class=styled":"")+">";
                },
                cr: "</table>",
                r: {dca: [new Rule({
                        n: "header_row",
                        bb: "header",
                        or: "<tr>",
                        cr: "</tr>",
                        r: {
                            dca: [new Rule({
                                n: "column",
                                bb: "column",
                                or: function(m, g1, g2){
                                    var w = getWidth(this);
                                    return "<th "+(w?" style=width:"+w:"")+">";
                                },
                                cr: "</th>",
                            }, bb)],
                        }
                    }, bb), new Rule({
                        n: "row",
                        bb: "row",
                        or: function(m, g1){
                            var even = "";
                            var prevRow;
                            for(var i=this.nodeIndex-1; i>=0; i--){
                                var n = this.parentNode.content[i];
                                if(n.rule == this.rule){
                                    prevRow = n;
                                    break;
                                }
                            }
                            if(!prevRow || !prevRow.even){
                                this.even = true;
                                even = " class=even";
                            }
                            return "<tr"+even+">";
                        },
                        cr: "</tr>",
                        r: {
                            dca: [new Rule({
                                n: "column",
                                bb: "column",
                                or: function(m, g1, g2){
                                    var w = getWidth(this);
                                    return "<td "+(w?" style=width:"+w:"")+">";
                                },
                                cr: "</td>",
                            }, bb)],
                        }
                    }, bb)
                ]},
            }, bb), new Rule({
                n: "row",
                bb: "row",
                or: function(){
                    var columnCount = 0;
                    var widthPerSubtract = 0;
                    var widthAbsSubtract = 0;
                    var fitContent = this.getData("fitContent")=="true";
                    this.filterChildren(function(){
                        if(this.rule && this.rule.name=="column" && columnCount>=0){
                            var w = (this.getData("width")||this.getData("w")||"").match(/([0-9]+)(%)?/);
                            if(w){
                                if(w[2]) widthPerSubtract+=Number(w[1]);
                                else     widthAbsSubtract+=Number(w[1]);
                            }else{
                                columnCount++;
                            }
                        }
                        return false;
                    });
                    if(columnCount>0)
                        this.columnPer = "calc("+Math.floor((100-widthPerSubtract)/columnCount)+"% - "+
                            Math.ceil(widthAbsSubtract/columnCount)+"px);";
                    else
                        this.columnPer = "100%;";
                    return "<div class='row"+(fitContent?" fitContent":"")+"'>";
                },
                r: {
                    dca: [new Rule({
                        n: "column",
                        bb: "column",
                        or: function(m, g1, g2){
                            var w = getWidth(this);
                            return "<div class=column style='min-width:fit-content;float:left;width:"+(w?w:this.parentNode.columnPer)+"'>";
                        },
                        cr: "</div>",
                    }, bb)],
                },
                cr: "<br style=clear:both></div>",
            }, bb), new Rule({
                n: "katex",
                bb: "latex",
                or: "<span class=katex>",
                dr: function(){
                    var callback = arguments[arguments.length-1];
                    this.input.usedKatex = true;
                    this.assembleContent(function(text){
                        try{
                            callback(katex.renderToString(text));
                        }catch(e){
                            callback("<span class=error style=background-color:red>"+e+"</span>");
                        }
                    });
                },
                cr: "</span>",
                r: null,
            }, bb), new Rule({
                n: "hyperlink",
                bb: "link",
                or: function(){ 
                    this.linkUrl = this.getData("url");
                    if(this.linkUrl)
                        return '<a href="'+this.linkUrl+'">';
                    else{
                        var callback = arguments[arguments.length-1];
                        this.assembleContent(function(text){
                            var key = this.trim(text);
                            var val = this.input.linkDictionary[key];
                            if(val) this.linkUrl = val;
                            
                            callback('<a href="'+this.linkUrl+'">');
                        });
                    }
                },
                dr: function(){
                    var This = this;
                    var callback = arguments[arguments.length-1];
                    this.assembleContent(function(text){
                        This.linkText = text; 
                        callback(text);
                    });
                },
                cr: "</a>"
            }, bb), new Rule({
                n: "hyperlink_short", //matches [url][text]  or [text][url]
                o: [/\[(.*?)\]\[(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9]\.[^\s]{2,})\]/, /\[(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9]\.[^\s]{2,})\]\[(.*?)\]/],
                or: function(m,g1,g2){
                    if(rUrl.test(g1)){
                        this.linkText = g2;
                        this.linkUrl = g1;
                        return '<a href="'+g1+'">'+g2+'</a>';
                    }else{
                        this.linkText = g1;
                        this.linkUrl = g2;
                        return '<a href="'+g2+'">'+g1+'</a>';
                    }
                }
            }), new Rule({
                n: "site_browser",
                bb: "siteBrowser",
                dr: function(){
                    var callback = arguments[arguments.length-1];
                    this.assembleContent(function(data){
                        this.input.siteNavigator = data;
                        callback("");
                    });
                }
            },bb), new Rule({
                n: "timeStamp",
                bb: "timeStamp",
                dr: function(){
                    var include = this.getData("include");
                    this.input.includeTimeStamp = typeof(include)=="string"?include!="false":true;
                    return "";
                }
            },bb), new Rule({
                n: "head",
                bb: "head",
                dr: function(){
                    var callback = arguments[arguments.length-1];
                    var This = this;
                    this.assemble(function(assembled){
                        This.input.headData += assembled;
                        callback("");
                    });
                }
            },bb), new Rule({
                n: "iw_method",
                bb: ["method"],
                cr:"",
                or: function(m,g1){
                    //#####################################################################################
                    //#####################################################################################
                    //#####################################################################################
					//input [method exchange=false ui=true documentation="official" icmVersion="1.6.6"]
					var isExchange  = this.getData("exchange") == "true"
					var isUI        = this.getData("ui") == "true"
					var version     = this.getData("icmVersion")
					var docType     = this.getData("documentation") || this.getData("docType")
                    
			        var template = 
					'<div style="position:absolute; right:25px;">'                                                                                               + "\n" +
					'	<div class="docVersion" style="float:right;background-color:#ffdddd;border-radius:5px;border:5px solid #ffdddd;"><b>614546119</b></div>' + "\n" +
					'	<div class="docAppType" style="float:right;background-color:#aaaaaa;border-radius:5px;border:5px solid #aaaaaa;"><b>432364246</b></div>' + "\n" +
					'	<div class="docDocType" style="float:right;background-color:#ddffdd;border-radius:5px;border:5px solid #ddffdd;"><b>229633707</b></div>' + "\n" +
					'</div>'
					
					if(isExchange & isUI){
						var appType = "Both"
					} else if(isExchange){
						var appType = "Exchange only"
					} else if(isUI){
						var appType = "UI only"
					} else {
						var appType = "Private"
					}
					
					template = template.replace("614546119",version)
					template = template.replace("432364246",appType)
					template = template.replace("229633707",docType)
					
                    return template;
                    //#####################################################################################
                    //#####################################################################################
                    //#####################################################################################
                }
            }, bb), new Rule({
                n: "bb_code_generic",
                o:/\[([^\[\/][^\s\]]*)(?:\s(?:\s*(?:=|"(?:\\\.|[^\"])*"|'(?:\\.|[^'])*'|[^\\] ="']*))*)?(\s*[^\]]*)\]/i,
                d: {match:/^( ){1,4}/, reset:/$/},
                c: /\[\/@1(\s(?:\s*(?:=|"(?:\\\.|[^\"])*"|'(?:\\.|[^'])*'|[^\\] ="']*))*)?\]/i,
                or: "<div class=@1 @2>",
                cr: "</div>"
            }, bb)
        ]);
        
        var syntax = new Syntax({
            ruleSet: ruleSet,
            preProcessor: function(input, siteNavigator, callback){
                callback = arguments[arguments.length-1];
                input.text = input.text.replace(/\r\n/g, "\n");
                input.headers = [];
                input.linkDictionary = {};
                input.siteNavigator = siteNavigator;
                input.usedKatex = false;
                input.includeTimeStamp = true;
                input.headData = "";
                input.addHeader = function(name, level){
                    var headers = this.headers;
                    var path = "";
                    
                    var clean = function(text){
                        return text.replace(/<\/?\w+(\s("(\\.|[^"])*"|'(\\.|[^'])*'|[^>"']*)*)?>/g, "").replace(/^\s*([^]*?)\s*$/g, "$1").replace(/>|\s/g, "_");
                    };
                    //get the parent header
                    while(headers.length!=0){
                        var h = headers[headers.length-1];
                        if(h.level<level){
                            path += clean(h.name)+">";
                            headers = h.children;
                        }else{
                            break;
                        }
                    }
                    
                    //add the new header
                    var path = path + clean(name);
                    headers.push({name:name, level:level, id:path, children:[]});
                    return path;
                }
                callback();
            },
            postProcessor: function(input, content, elementConverter, requiresConverter, callback){
                callback = arguments[arguments.length-1];
                var out = "";
                
                //create date at bottom of page
                if(input.includeTimeStamp){
                    var date = new Date();
                    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    var month = months[date.getMonth()];
                    date = date.getDate()+" "+month+" "+date.getFullYear();
                    content += "<div class=saveDate>"+
                                    "Page has been last updated on: "+
                                    "<span class=saveDateValue>"+
                                        date+
                                    "<span>"+
                                "</div>";
                }
                
                //content
                Empirler.getFile(DMLhtmlPath, function(file){
                    //create site navigator
                    if(input.siteNavigator){
                        if(input.siteNavigator[0]=="/" && Empirler.runServerSide){
                            var path = require("path");
                            var fs = require("fs");
                            var addDir = function(dir){
                                var out = "";
                                var files = fs.readdirSync(dir);
                                files.forEach(function(file){
                                    var p = dir+"/"+file;
                                    if(fs.lstatSync(p).isDirectory()){
                                        out += "<div class=dir name='"+file+"'>"+
                                                    "<div class=dirName>"+file+"</div>"+
                                                    "<div class=dirChildren>"+addDir(p)+"</div>"+
                                                "</div>";
                                    }else{
                                        var name = file.split(".");
                                        name.pop();
                                        name = name.join(".");
                                        var cwd = process.cwd();
                                        if(p.substring(0, cwd.length)==cwd) p = p.substring(cwd.length)
                                        out += "<div class=file name='"+file+"'>"+
                                                    "<a href='"+p+"'>"+name+"</a>"+
                                                "</div>";
                                    }
                                });
                                return out;
                            };
                            file = file.replace("[BROWSER]", addDir(input.siteNavigator));
                        }else{
                            file = file.replace("[BROWSER]", input.siteNavigator);    
                        }
                    }else{
                        file = file.replace("[BROWSER]", "");
                    }
                    
                    //create index
                    var headerTemplate = "<div class=index id='[ID]'>"+
                                            "<div class=name>[NAME]</div>"+
                                            "<div class=children>"+
                                                "[CHILDREN]"+
                                            "</div>"+
                                        "</div>";
                    function constructHeader(headerList){
                        var out = "";
                        for(var i=0; i<headerList.length; i++){
                            var header = headerList[i];
                            out += headerTemplate.replace("[NAME]", header.name)
                                        .replace("[CHILDREN]", constructHeader(header.children))
                                        .replace("[ID]", header.id);
                        }
                        return out;
                    }         
                    
                    
                    //add katex css
                    // file = file.replace("[KATEXSHEET]", input.usedKatex?'<link rel="stylesheet" href="'+
                    //     (Empirler.runServerSide?Empirler.paths.relativeLibrariesPath:Empirler.paths.absoluteLibrariesPath)+
                    //     '/Katex/katex.css">':"");
                    file = file.replace("[KATEXSHEET]", input.usedKatex?'<link rel="stylesheet" href="'+
                        Empirler.paths.absoluteLibrariesPath+
                        '/Katex/katex.css">':"");
                    
                    //add index
                    file = file.replace("[INDEX]", constructHeader(input.headers));
                    
                    //add content and head
                    out += file.replace("[HEAD]", input.headData).replace("[BODY]", content);
                    
                    //ace css
                    out += "<style>";
                    out += themeCSS +
                        ".inline-codeblock {display: inline-block;}";
                    out += "</style>";
                    
                    //add empirler itself
                    if(requiresConverter)
                        out += elementConverter;
                        
                    callback(out); 
                });
            }
        });
        
        callback(syntax);   
    }
    initialiseLibraries();
});