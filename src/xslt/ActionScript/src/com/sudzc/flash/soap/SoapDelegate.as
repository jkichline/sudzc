package com.sudzc.flash.soap {
	public class SoapDelegate {
		public var data:Object = null;
		public var status:int = 0;
		public var onload:Function = function(object) { }
		public var onfault:Function = function(fault) { }
		public var onerror:Function = function(response:Object, exception:Error) {
			if(exception) { throw exception; }
		}
		public function SoapDelegate(data:Object=null) {
			this.data = data;
		}
	}
}