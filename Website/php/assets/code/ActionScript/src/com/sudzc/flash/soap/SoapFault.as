package com.sudzc.flash.soap {
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	public class SoapFault {
		public var faultCode:String = null;
		public var faultString:String = null;
		public var faultActor:String = null;
		public var detail:String = null;
		public var hasFault:Boolean = false;
		private var doc:XMLDocument = null;
		
		public function SoapFault(XMLDocument:document) {
			if(!document) { return; }
			var fault:XMLNode = SoapProxy.getFault(document);
			if(fault) {
				this.faultCode = SoapProxy.getValue(SoapProxy.getNode(fault, "faultcode"));
				this.FaultString = SoapProxy.getValue(SoapProxy.getNode(fault, "faultstring"));
				this.faultActor = SoapProxy.getValue(SoapProxy.getNode(fault, "faultactor"));
				this.detail = SoapProxy.getValue(SoapProxy.getNode(fault, "detail"));
				this.hasFault = true;
			}
		}
	}
}