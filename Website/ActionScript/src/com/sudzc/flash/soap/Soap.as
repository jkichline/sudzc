package com.sudzc.flash.soap {
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.Dictionary;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	public class SoapProxy {
		public function SoapProxy() {
		}
		
		public static function createEnvelope(ns:String, method:String, values:Dictionary){
			var s:String = "";
			s += "<?xml version=\"1.0\" encoding=\"utf-8\"?>";
			s += "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\""+ ns +"\">";
			s += "<soap:Body>";
			s += "<"+ method + ">";
			for each (var key:Object in values) {
				s += "<"+ key.toString() +">"+ serialize(values[key]) + "</"+ key.toString() +">";
			}
			s += "</"+ method +">";
			s += "</soap:Body>";
			s += "</soap:Envelope>";
			return s;
		}
		
		public function getXml(url:String, post:Object=null, action:String=null, callback:Function=null, username:String=null, password:String=null):void {
			var request:URLRequest = new URLRequest(url);

			if(post != null) {
				request.method = "POST";
				if(post is XMLDocument) {
					request.contentType = "text/xml";
					request.requestHeaders.push(new URLRequestHeader("Content-Type","text/xml"));
					request.data = post.toString();
				}
				if(post is Dictionary) {
					request.requestHeaders.push(new URLRequestHeader("Content-Type","application/x-www-form-urlencoded"));
					request.data = this.getKeyValuePairs(post as Dictionary);
				}
			}
			
			if(action != null && action != "") {
				request.requestHeaders.push(new URLRequestHeader("SOAPAction", action));
			}
			
			var delegate:SoapDelegate = new SoapDelegate(loader); 

			var loader:URLLoader = new URLLoader(request);
			loader["delegate"] = delegate;
			loader.addEventListener(Event.COMPLETE, handleComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleStatus);
			loader.load(request);
			return delegate;
		}
		
		private function handleComplete(event:Event) {
			var loader:URLLoader = URLLoader(event.target);
			var delegate:SoapDelegate = loader["delegate"] as SoapDelegate; 
			var fault:SoapFault = new SoapFault(delegate);
			if(fault.hasFault) {
				delegate.onfault(fault);
			} else {
				
			}
		}
		
		private function handleStatus(event:HTTPStatusEvent) {
			var loader:URLLoader = URLLoader(event.target);
			SoapDelegate(loader["delegate"]).status = event.status;
		}
		
		public function createCallback(response:URLLoader){
			var delegate:SoapDelegate = SoapDelegate(response["delegate"]);
			var fault = new SOAPFault(response);
			if (fault.hasFault) {
				delegate.onfault(fault);
				return null;
			} else {
				if (delegate.status != 200) {
					delegate.onerror(response);
					return null;
				}
				try {
					return new XMLDocument(response.data);
				} catch(ex){
					handler.onerror(response,ex);
					return null;
				}
			}
		}
		
		public static function getKeyValuePairs(dict:Dictionary):String {
			var o:String - "";
			for each(var key:Object in dict) {
				if(o != "") {
					o += "&";
				}
				o += key.toString() + "=" + dict[key].toString();
			}
			return o;
		}
		
		public static function serialize(value:Object):String {
			if(value == null) { return ""; }
			var date:Date = Date(value);
			if(date) { return formatDate(date); }
			return value.toString();
		}
		
		public static function formatDate(dt:Date):String {
			var o:String = "";
			var y:int = dt.fullYear;
			o += y.toString() + "-";
			var m:int = dt.month + 1;
			if(m<10) { o += "0";}
			o += m.toString() + "-";
			var d:int = dt.day;
			if(d<10) { o += "0"; }
			o += d.toString() + "T";
			var h:int = dt.hours.getHours();
			if(h<10) { o += "0"; }
			o += h.toString() + ":";
			var n:int = dt.minutes;
			if(n<10) { o += "0"; }
			o += n.toString() + ":";
			var s:int = dt.seconds;
			if(s<10) { o += "0"; }
			o += s.toString();
			return o;
		}
		
		public static function selectSingleNode(parent:XMLNode, local:String, prefix:String=null) : XMLNode {
			return this.selectNode(parent, local, prefix, 0);
		}

		public static function selectNode(parent:XMLNode, local:String, prefix:String=null, index:int=0) : XMLNode {
			if(!parent) { return null; }
			var a:Array = selectNodes(parent, local, prefix);
			if(a && a.length > index) {
				for each(var node:XMLNode in a) {
					if(node.parentNode == parent) { return node; }
				}
			}
			return null;
		}

		public static function selectNodes(parent:XMLNode, local:String, prefix:String=null) : Array {
			if(!parent) { return null; }
			var a:Array = new Array();
			var tn:String = local;
			if(prefix) { tn = prefix + ":" + local; }
			for each(var node:XMLNode in parent.childNodes) {
				if(node.nodeName == tn) {
					a.push(node);
				}
			}
			if(a.length < 1) {
				for each(var node:XMLNode in parent.childNodes) {
					if(node.nodeName == local) {
						a.push(node);
					}
				}				
			}
			return a;
		}

		public static function isAncestorOf(parent:XMLNode, child:XMLNode) : Boolean {
			var p:XMLNode = child;
			while(p=p.parentNode){
				if(p==parent) { return true; }
			}
			return false;
		}

		public static function getValue(node:XMLNode) : String {
			if(node) {
				if(node.firstChild) { node=node.firstChild; }
				return node.nodeValue;
			}
			return null;
		}
		
		public static function getBody(document:XMLDocument, tag:String) : XMLNode {
			if(!tag) { tag = "Body"; }
			var node:XMLNode = selectSingleNode(document, "Envelope", "soap");
			if(node) { node = selectSingleNode(node, tag, "soap"); }
			return node;
		}

		public static function getFault(document:XMLDocument) : XMLNode {
			var node:XMLNode = getBody(document);
			if(node) { return selectSingleNode(node, "Fault", "soap"); }
			return null;
		}

		public static function getNode(node:XMLNode=null, name:String, local:String=null) : XMLNode {
			var parent = node;
			if(!local) { parent = getBody(node); }
			if(!parent) { parent = node; }
			return selectSingleNode(parent, name);
		}
		
		public static function getArray(node:XMLNode, objType:String) : Array {
			var a:Array = new Array();
			if(node){
				for each(child:XMLNode in node.childNodes) {
					a.push(convertType(child, objType));
				}
			}
			return a;
		}


		public static function isArray(objType:String) : Boolean {
			return (objType && objType.toLowerCase().indexOf("array") >-1);
		}

		public static function hasChildElements(node:XMLNode) : Boolean {
			if(!node){ return false; }
			for each(var child:XMLNode in node.childNodes) {
				if(child.nodeType==1) { return true; }
			}
			return false;
		}
		
		public static function getTypedValue(node:XMLNode, name:String, type:String) : Object {
			return convertType(getNode(node, name), type);
		}
		
		public static function init(object:Object, node:XMLNode, params:Dictionary) {
			for each(var key:String in types) {
				object[key] = getTypedValue(node, key, types[key]);
			}
		}
	
		public static function convertType(node:XMLNode, objType:String) : Object {
			var val:Object = null;
			var str:String = null;
			if(hasChildElements(node)) {
				if(isArray(objType)) {
					return getArray(node, node.firstChild.tagName);
				} else {
					try {
						var classRef:Class = getDefinitionByName(node.nodeName) as Class;
						return new classRef(node);
					} catch() {
						return node;
					}
				}

			} else {
				str = this.getValue(node);
		
				if(objType){
					var colon:int = objType.indexOf(":");
					if(colon > -1) { objType=objType.substring(colon+1); }
					objType = objType.toLowerCase();
				}
				switch(objType) {
					case "int":
						try { val = new Number(str); } catch(ex) { } break;
					case "float":
						try { val = new Number(str); } catch(ex) { } break;
					case "date":
						try { val = createDate(str); } catch(ex) { } break;
					case "datetime":
						try { val = createDate(str); } catch(ex) { } break;
					case "boolean":
						if(str.toLowerCase()=="true"){
							val = true;
						}else{
							val = false;
						}
						break;
				}
			}
			return val;
		}
		
		public static function createDate(str:String) : Date {
			if(!str) { return null; }
			if(str.length < 10) { return null; }
			var dt:String = str.substring(5,7) + "/" + str.substring(8,10) + "/" + str.substring(0,4);
			if(str.length >= 19) {
				dt += " " + str.substring(11,13) + ":" + str.substring(14,16) + ":" + str.substring(17,19);
			}
			return new Date(dt);
		}

	}
}