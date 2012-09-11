String.prototype.trim=function(){
  var x=this;
  x=x.replace(/^\s*(.*)/,"$1");
  x=x.replace(/(.*?)\s*$/,"$1");
  return x;
}
String.prototype.unescape=function(){
	if(this!=null&&this==""){return null;}
	return unescape(this);
}
String.prototype.contains=function(value,ignoreCase){
	var src=this;
	if(ignoreCase){src=src.toLowerCase();value=value.toLowerCase();}
	return (src.indexOf(value)>-1);
}
String.prototype.startsWith=function(value,ignoreCase){
	var src=this;
	if(ignoreCase){src=src.toLowerCase();value=value.toLowerCase();}
	return (src.indexOf(value)==0);
}
String.prototype.endsWith=function(value,ignoreCase){
	var src=this;
	if(ignoreCase){src=src.toLowerCase();value=value.toLowerCase();}
	var at=src.lastIndexOf(value);
	if(at<0){return false;}
	if((at+value.length)==src.length){return true;}return false;
}
String.prototype.replaceAll=function(searchFor,replaceWith,ignoreCase){
	var f="g";if(ignoreCase){f+="i";}
	var re=new RegExp(searchFor,f);
	return this.replace(re,replaceWith);
}
String.prototype.equals=function(val,ignoreCase){
	if(val==null){return false;}
	var src=this;
	if(ignoreCase){src=src.toLowerCase();val=val.toLowerCase();}
	return (src==val);
}

Soap=function(){
	this.isIE=false;this.isNS=true;
	this.services={};
	this.services.onfault=null;
	this.services.onerror=null;
	this.services.onload=null;
}

Soap.prototype.ns=function(ns){
	var p=ns.split(".");
	var r=window;
	for(var i=0;i<p.length;i++){
		if(r[p[i]]==null||typeof(r[p[i]])=="undefined"){r[p[i]]={};}
		r=r[p[i]];
	}
	return r;
}

Soap.prototype.createEnvelope=function(namespace,method,names,values){
	var s='',val=null;
	s+='<?xml version="1.0" encoding="utf-8"?>';
	s+='<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns="'+ namespace +'">';
	s+='<soap:Body>';
	s+='<'+ method +'>';
	for(var i=0;i<names.length;i++) {
		s+='<'+ names[i] +'>'+ this.serialize(values[i]) +'</'+ names[i] +'>';
	}
	s+='</'+ method +'>';
	s+='</soap:Body>';
	s+='</soap:Envelope>';
	return s;
}

Soap.prototype.secure=function(){return false;}

Soap.prototype.getXml=function(url,post,action,callback,caller){
	if(url==null||url==""){url=action;}
	var method="GET";
	var async=(callback!=null);
	if(post!=null){method="POST";}

	var req=this.createHttp();
	req.open(method,url,async);
	req.setRequestHeader("Content-Type","text/xml")
	if(action!=null&&action!=""){
		req.setRequestHeader("SOAPAction",action);
	}
	if(async){
		if(!caller){caller=this;}
		var handler=new SOAPHandler(req);
		this.addHandler(handler,"onload");
		this.addHandler(handler,"onfault");
		this.addHandler(handler,"onerror");
		
		req.onreadystatechange=function(){
			if(req&&(req.readyState==4||req.readyState=='complete')){
				if(req.status){
					callback(req,handler,caller);
				}else{
					throw new Error("Cannot contact the web service");
				}
			}
		}
	}
	req.send(post);
	if(async){
		return handler;
	}else{
		if(req.status==200){return req.responseXML;}
		return null;
	}
}

Soap.prototype.addHandler=function(h,fn){
	if(typeof(this.services[fn])=="function"){h[fn]=this.services[fn];}
}

Soap.prototype.createHttp=function(){
	try {
		if(window.XMLHttpRequest){
			var req=new XMLHttpRequest();
			if(req.readyState==null){
				req.readyState=1;
				req.addEventListener("load",function(){
					req.readyState=4;
					if(typeof(req.onreadystatechange)=="function"){req.onreadystatechange();}
				},false);
			}
			return req;
		}
		if(window.ActiveXObject){
			return new ActiveXObject("Microsoft.XMLHTTP");
		}
	} catch (ex) {
  	throw new Error("Your browser does not support XmlHttp objects");
	}
}

Soap.prototype.loadXml=function(xmlString){
	var doc=null;
	try{
		if(document.ActiveXObject){
			this.isIE=true;this.isNS=false;
			doc=new ActiveXObject("Microsoft.XMLDOM");
			doc.loadXML(xmlString);
		}else{
			var parser=new DOMParser();
			doc=parser.parseFromString(xmlString,"text/xml");
		}
		return doc;
	}catch(ex){
		throw new Error("Cannot parse the web service feed");
	}
}
Soap.prototype.selectSingleNode=function(parent,local,prefix){
	var a=this.selectNodes(parent,local,prefix);
	for(var i=0;i<a.length;i++){
		if(a[i].parentNode==parent){return a[i];}
	}
	return this.selectNode(parent,local,prefix,0);
}

Soap.prototype.selectNode=function(parent,local,prefix,index){
	if(!parent){return null;}
	var a=this.selectNodes(parent,local,prefix);
	if(!index){index=0;}
	if(a&&a.length>index){return a[index];}
	return null;
}

Soap.prototype.selectNodes=function(parent,local,prefix){
	if(!parent){return null;}
	var tn=local;if(prefix){tn=prefix+":"+local;}
	var t=parent.getElementsByTagName(tn);
	if(!t||t.length<1){t=parent.getElementsByTagName(local);}
	return t;
}

Soap.prototype.isAncestorOf=function(parent,child){
	var p=child;
	while(p=p.parentNode){
		if(p==parent){return true;}
	}
	return false;
}

Soap.prototype.getValue=function(node){
	if(node){
		if(node.firstChild){node=node.firstChild;}
		return node.nodeValue;
	}
	return null;
}

Soap.prototype.getBody=function(doc,tag){
	if(!tag){tag="Body";}
	var node=this.selectSingleNode(doc,"Envelope","soap");
	if(node!=null){node=this.selectSingleNode(node,tag,"soap");}
	return node;
}

Soap.prototype.getFault=function(doc){
	var node=this.getBody(doc);
	if(node!=null){return this.selectSingleNode(node,"Fault","soap");}
	return null;
}

Soap.prototype.getNode=function(node,name,local){
	var parent=node;
	if(typeof(local)!="undefined"&&!local){parent=this.getBody(node);}
	if(!parent){parent=node;}
	return this.selectSingleNode(parent,name);
}

Soap.prototype.prepare=function(response){
	var doc=response.responseXML;
	return doc;
}

Soap.prototype.getArray=function(node,objType){
	var a=[];
	if(node!=null){
		for(var i=0;i<node.childNodes.length;i++){
			var child=node.childNodes[i];
			a[i]=this.convertType(child,objType);
		}
	}
	return a;
}

Soap.prototype.isArray=function(objType){
	if(objType&&objType.toLowerCase&&objType.toLowerCase().indexOf("array")>-1){return true;}
	return false;
}

Soap.prototype.hasChildElements=function(node){
	if(node==null){return false;}
	for(var i=0;i<node.childNodes.length;i++){
		if(node.childNodes[i].nodeType==1){return true;}
	}
	return false;
}

var __tempObject=null;
var __tempChildNode=null;

Soap.prototype.convertType=function(node,objType){
	var val=null;
	if(this.hasChildElements(node)){
		if(this.isArray(objType)){
			val=this.getArray(node,node.firstChild.tagName);
		}else{
			__tempChildNode=node;
			var stmt="var __tempObject = new "+node.tagName+"(__tempChildNode);";
			try{window.eval(stmt);}catch(ex){}
			val=__tempObject;
		}
	}else{
		val=this.getValue(node);
		
		if(objType){
			var colon=objType.indexOf(":");
			if(colon>-1){objType=objType.substring(colon+1);}
			objType=objType.toLowerCase();
		}
		switch(objType) {
			case "int":
				try{val=new Number(val);}catch(ex){}break;
			case "float":
				try{val=new Number(val);}catch(ex){}break;
			case "date":
				try{val=this.createDate(val);}catch(ex){}break;
			case "datetime":
				try{val=this.createDate(val);}catch(ex){}break;
			case "boolean":
				if(val.toLowerCase()=="true"){
					val=true;
				}else{
					val=false;
				}
				break;
		}
	}
	return val;
}
	
Soap.prototype.serialize=function(obj){
	var o='';var isObj=false;
	try{if(obj.__keys.length>0){isObj=true;}}catch(ex){}
	if(isObj){
    for(var i=0;i<obj.__keys.length;i++){
      var key=obj.__keys[i];
      o+='<'+key+'>'+this.serialize(obj[key])+'</'+key+'>';
    }
		return o;
	}
	if(obj!=null){
		if(this.isDate(obj)){return this.formatDate(obj);}
		if(typeof(obj)=="object") {
		  for(var a in obj) {
		    var i=new Number(a);
		    if((i+"")!="NaN"){
		      var n="item";
		      if(obj[a]["__class"]!=null){n=obj[a]["__class"];}
  		    o += "<"+ n +">" + this.serialize(obj[a]) + "</"+ n +">";
		    } else {
  		    o += "<"+ a + ">" + this.serialize(obj[a]) + "</" + a + ">";
  		  }
		  }
		  return o;
		}
		return obj+"";
	}else{return"";}
}

Soap.prototype.isDate=function(dt){
	return (typeof(dt.getTime)=="function");
}

Soap.prototype.createDate=function(str){
	if(!str){return null;}
	if(str.length<10){return null;}
	var dt=str.substring(5,7)+"/"+str.substring(8,10)+"/"+str.substring(0,4);
	if(str.length>=19){
		dt+=" "+str.substring(11,13)+":"+str.substring(14,16)+":"+str.substring(17,19);
	}
	var dt=new Date(dt);
	return dt;
}

Soap.prototype.formatDate=function(dt){
	var o="";
	var y=dt.getFullYear();
	var m=dt.getMonth()+1;if(m<10){m="0"+m;}
	var d=dt.getDate();if(d<10){d="0"+d;}
	var h=dt.getHours();if(h<10){h="0"+h;}
	var n=dt.getMinutes();if(n<10){n="0"+n;}
	var s=dt.getSeconds();if(s<10){s="0"+s;}
	return y+"-"+m+"-"+d+"T"+h+":"+n+":"+s;
}

Soap.prototype.init=function(obj,node,keys,types){
	obj.__keys=keys;
	for(var i=0;i<keys.length;i++){
		obj[keys[i]]=null;
		if(node){
			var t=null;
			var el=soap.getNode(node,keys[i],true);
			if(types&&types.length>i){t=types[i];}
			if(el){obj[keys[i]]=soap.convertType(el,t);}
		}
	}
}

Soap.prototype.extend=function(tgt,src){
	for(var a in src){tgt[a]=src[a];}
}

Soap.prototype.createCallback=function(response,handler){
	var fault=new SOAPFault(response);
	if(fault.hasFault){
		handler.onfault(fault);return null;
	}else{
		if(response.status!=200){
			handler.onerror(response);return null;
		}
		try {
			return soap.prepare(response);
		} catch(ex){
			handler.onerror(response,ex);return null;
		}
	}
}

var soap=new Soap();

function SOAPHandler(object){
	this.object=object;
	this.onload=function(object){}
	this.onfault=function(fault){}
	this.onerror=function(response,exception){
		if(exception){throw exception;}
	}
}

function SOAPFault(response){
	this.faultCode=null;
	this.faultString=null;
	this.faultActor=null;
	this.detail=null;
	this.hasFault=false;
	this.xml=null;
	this.doc=null;
	if(response){
		if(response.status!=200||response.responseText.toLowerCase().indexOf("fault")>0){
			this.xml=response.responseText;
			this.doc=response.responseXML;
			if(this.doc){
				var fault=soap.getFault(this.doc);
				if(fault) {
					this.faultCode=soap.getValue(soap.getNode(fault,"faultcode"));
					this.faultString=soap.getValue(soap.getNode(fault,"faultstring"));
					this.faultActor=soap.getValue(soap.getNode(fault,"faultactor"));
					this.detail=soap.getValue(soap.getNode(fault,"detail"));
					this.hasFault=true;
				}
			}
		}
	}
}

SOAPFault.prototype.toString=function(){return this.xml;}