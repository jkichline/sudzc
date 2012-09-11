<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Converts the WSDL file to JavaScript for use in browsers.
-->
<xsl:stylesheet version="1.0" 
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" 
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" 
	xmlns:s="http://www.w3.org/2001/XMLSchema" 
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
	xmlns:tns="http://epm.aholdusa.com/webservices/" 
	xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" 
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" 
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output version="1.0" encoding="iso-8859-1" method="xml" omit-xml-declaration="no" indent="yes"/>

	<xsl:param name="ns"/>
	
  <xsl:template match="/">
		<package>
			<xsl:attribute name="class"><xsl:value-of select="/wsdl:definitions/wsdl:service/@name"/></xsl:attribute>
			<xsl:attribute name="name"><xsl:value-of select="/wsdl:definitions/wsdl:service/@name"/>.ActionScript</xsl:attribute>
			<folder copy="ActionScript/src" as="src"/>
			<xsl:apply-templates select="/wsdl:definitions"/>
		</package>
	</xsl:template>

  <xsl:template match="wsdl:definitions">
		<file>
			<xsl:attribute name="filename"><xsl:call-template name="getNsPath"/>/<xsl:value-of select="wsdl:service/@name"/>.as</xsl:attribute>
			<xsl:if test="wsdl:documentation">
/* <xsl:value-of select="wsdl:documentation"/> */
			</xsl:if>
package <xsl:call-template name="getNs"/> {
	import com.sudzc.flash.soap.SoapDelegate;
	import com.sudzc.flash.soap.SoapProxy;

	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.utils.Dictionary;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;

	<xsl:apply-templates select="wsdl:service"/>
}</file>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name]" mode="obj"/>
  </xsl:template>

	<xsl:template match="wsdl:service">
	public class <xsl:value-of select="@name"/> {
		public var service:String;
		public var password:String;
		public var password:String;
		public var ns:String;
		private var soap:SoapProxy;
			
		public function SpotobeService(service:String="<xsl:value-of select="/wsdl:definitions/wsdl:service/wsdl:port[1]/soap:address/@location"/>", ns:String="<xsl:value-of select="/wsdl:definitions/@targetNamespace"/>") {
			this.service = service;
			this.ns = ns;
			this.soap = new SoapProxy();
		}
			<xsl:apply-templates select="/wsdl:definitions/wsdl:portType[1]/wsdl:operation" mode="def"/>
			<xsl:apply-templates select="/wsdl:definitions/wsdl:portType[1]/wsdl:operation/wsdl:output" mode="results"/>
	}
  </xsl:template>
	
	<xsl:template match="wsdl:operation" mode="def">
		<xsl:variable name="name"><xsl:value-of select="@name"/></xsl:variable>
		<xsl:variable name="action"><xsl:value-of select="/wsdl:definitions/wsdl:binding/wsdl:operation[@name = $name]/soap:operation/@soapAction"/></xsl:variable>
		<xsl:variable name="service"><xsl:value-of select="//*/wsdl:service/@name"/></xsl:variable>
		<xsl:variable name="msg"><xsl:value-of select="substring-after(wsdl:input/@message, ':')"/></xsl:variable>

<xsl:if test="wsdl:documentation">
		/* <xsl:value-of select="wsdl:documentation"/> */</xsl:if>
		public function <xsl:value-of select="@name"/>(<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="params"/>) : SoapHandler {
			var params = new Dictionary();<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="dictionary"/>
			var env:XMLDocument = this.soap.createEnvelope(this.ns, "<xsl:value-of select="@name"/>", params);
			return this.soap.getXml(this.service, env, "<xsl:value-of select="$action"/>", this.<xsl:value-of select="@name"/>Handler, this.username, this.password);
		}

		private function <xsl:value-of select="@name"/>Handler(response:URLLoader) {
			var doc:XMLDocument = this.soap.createCallback(response);
			if(doc){
				var object:Object = null;
<xsl:apply-templates select="wsdl:output" mode="def"/>
				var delegate:SoapDelegate = SoapDelegate(response["delegate"]);
				delegate.onload(object);
			}
		}
	</xsl:template>
	<xsl:template match="wsdl:output" mode="def">
		<xsl:variable name="msg"><xsl:value-of select="substring-after(@message, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="def"/>
	</xsl:template>
	
	<xsl:template match="wsdl:message" mode="def">
		<xsl:choose>
			<xsl:when test="wsdl:part[@element]">
				<xsl:apply-templates select="wsdl:part" mode="def"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="typeName"><xsl:value-of select="substring-after(wsdl:part/@type, ':')"/></xsl:variable>
				<xsl:choose>
					<xsl:when test="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $typeName]">
						object = this.<xsl:value-of select="@name"/>(doc);
					</xsl:when>
					<xsl:otherwise>object = this.soap.convertType(doc, "<xsl:value-of select="$typeName"/>");</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="wsdl:part" mode="def">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="def"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="def">				object = this.<xsl:value-of select="descendant::s:element/@name"/>(doc);</xsl:template>
	
	<xsl:template match="s:complexType" mode="def">				object = this.<xsl:value-of select="@name"/>(doc);</xsl:template>

	<xsl:template match="wsdl:message" mode="params">
		<xsl:choose>
			<xsl:when test="wsdl:part[@element]"><xsl:apply-templates select="wsdl:part" mode="params"/></xsl:when>
			<xsl:otherwise><xsl:for-each select="wsdl:part"><xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if></xsl:for-each></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="wsdl:part" mode="params">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="params"/>
	</xsl:template>

	<xsl:template match="s:element" mode="params">
		<xsl:for-each select="descendant::s:element"><xsl:value-of select="@name"/>:<xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template><xsl:if test="position() != last()">, </xsl:if></xsl:for-each>
	</xsl:template>
	
	<xsl:template match="s:element" mode="dictionary">
		<xsl:for-each select="descendant::s:element">
			params["<xsl:value-of select="@name"/>"] = <xsl:value-of select="@name"/>;</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="wsdl:message" mode="dictionary">
		<xsl:choose>
			<xsl:when test="wsdl:part[@element]"><xsl:apply-templates select="wsdl:part" mode="dictionary"/></xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="wsdl:part">
					params["<xsl:value-of select="@name"/>"] = <xsl:value-of select="@name"/>;
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="wsdl:part" mode="dictionary">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="dictionary"/>
	</xsl:template>
	
	<xsl:template match="wsdl:message" mode="parameters">
		<xsl:apply-templates select="wsdl:part" mode="parameters"/>
	</xsl:template>
	
	<xsl:template match="wsdl:part" mode="parameters">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="parameters"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="parameters">
		<xsl:for-each select="descendant::s:element">s+='&lt;<xsl:value-of select="@name"/>&gt;'+<xsl:value-of select="@name"/>+'&lt;/<xsl:value-of select="@name"/>&gt;';
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="wsdl:output" mode="results">
		<xsl:variable name="msg"><xsl:value-of select="substring-after(@message, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="results"/>	
	</xsl:template>
	
	<xsl:template match="wsdl:message" mode="results">
		<xsl:choose>
			<xsl:when test="wsdl:part[@element]">
				<xsl:apply-templates select="wsdl:part" mode="results"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="typeName"><xsl:value-of select="substring-after(wsdl:part/@type, ':')"/></xsl:variable>

				<xsl:variable name="name"><xsl:value-of select="@name"/></xsl:variable>
				<xsl:variable name="type"><xsl:value-of select="substring-after(wsdl:part/@type, ':')"/></xsl:variable>
				<xsl:variable name="objType"><xsl:value-of select="substring-after(//*/s:complexType[@name = $type]/*/s:element/@type, ':')"/></xsl:variable>
				<xsl:variable name="service"><xsl:value-of select="//*/wsdl:service/@name"/></xsl:variable>

private function <xsl:value-of select="$name"/>(response:XMLDocument){
	var node:XMLNode = this.soap.getNode(response, "<xsl:value-of select="$name"/>");
	if(node){
		<xsl:choose>
			<xsl:when test="//*/s:complexType[@name = $type]/*/s:element[@maxOccurs = 'unbounded']">
		return this.soap.getArray(node, "<xsl:value-of select="$objType"/>");
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="//*/s:complexType[@name = $type]">
		return new <xsl:value-of select="$type"/>(node);
					</xsl:when>
					<xsl:otherwise>
		return this.soap.convertType(node, "<xsl:value-of select="$objType"/>");
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	}
	return null;
}
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="wsdl:part" mode="results">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="results"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="results">
		<xsl:apply-templates select="descendant::s:element[1]" mode="gen"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="gen">
		<xsl:variable name="name"><xsl:value-of select="@name"/></xsl:variable>
		<xsl:variable name="type"><xsl:value-of select="substring-after(@type, ':')"/></xsl:variable>
		<xsl:variable name="objType"><xsl:value-of select="substring-after(//*/s:complexType[@name = $type]/*/s:element/@type, ':')"/></xsl:variable>
		<xsl:variable name="service"><xsl:value-of select="//*/wsdl:service/@name"/></xsl:variable>

		private function <xsl:value-of select="$name"/>(response:XMLDocument) : Object {
			var node:XMLNode = SoapProxy.getNode(response, "<xsl:value-of select="$name"/>");
			if(node){
			<xsl:choose>
				<xsl:when test="//*/s:complexType[@name = $type]/*/s:restriction[@base = 'soapenc:Array'] | //*/s:complexType[@name = $type]/*/s:element[@maxOccurs = 'unbounded']">
					<xsl:variable name="arrayType"><xsl:value-of select="substring-before(substring-after(//*/s:complexType[@name = $type]/*//*/s:restriction[@base = 'soapenc:Array']/s:attribute[@ref = 'soapenc:arrayType']/@wsdl:arrayType, ':'), '[')"/></xsl:variable>	return SoapProxy.getArray(node,'<xsl:value-of select="$objType"/>');</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="//*/s:complexType[@name = $type]">	return new <xsl:value-of select="$type"/>(node);</xsl:when>
						<xsl:otherwise>	return SoapProxy.getValue(node);</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			}
			return null;
		}
	</xsl:template>

	<xsl:template match="s:complexType" mode="obj">
		<xsl:variable name="service"><xsl:value-of select="//*/wsdl:service/@name"/></xsl:variable>
		<xsl:if test="not(descendant::s:element[@maxOccurs = 'unbounded'] and count(descendant::s:element) = 1)">
			<file>
				<xsl:attribute name="filename"><xsl:call-template name="getNsPath"/>/<xsl:value-of select="@name"/>.as</xsl:attribute>
				<xsl:if test="wsdl:documentation">
/* <xsl:value-of select="wsdl:documentation"/> */</xsl:if>
package <xsl:call-template name="getNs"/> {
	import flash.xml.XMLNode;
	import com.sudzc.flash.soap.SoapProxy;

	public class <xsl:value-of select="@name"/> {<xsl:apply-templates select="descendant::s:element" mode="properties"/>
	
		public funciton <xsl:value-of select="@name"/>(node:XMLNode) {<xsl:apply-templates select="descendant::s:element" mode="initialization"/>
		}

		public function toXMLString() : String {
			return SoapProxy.serialize(this);
		}
	}
}</file>
		</xsl:if>
	</xsl:template>
	<xsl:template match="s:element" mode="properties">
		public var <xsl:value-of select="@name"/>:<xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template>;</xsl:template>

	<xsl:template match="s:element" mode="initialization">
			this.<xsl:value-of select="@name"/> = SoapProxy.getTypedValue(node, "<xsl:value-of select="@name"/>", "<xsl:value-of select="@type"/>") as <xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template>;</xsl:template>
	
	<xsl:template name="getType">
		<xsl:param name="value"/>
		<xsl:variable name="type" select="substring-after($value,':')"/>
		<xsl:variable name="complexType" select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $type]"/>
		<xsl:variable name="isArray" select="$complexType/s:sequence/s:element[@maxOccurs = 'unbounded']"/>
		<xsl:choose>
			<xsl:when test="$isArray">Array</xsl:when>
			<xsl:when test="$complexType"><xsl:value-of select="$type"/></xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$type = 'string'">String</xsl:when>
					<xsl:when test="$type = 'normalizedString'">String</xsl:when>
					<xsl:when test="$type = 'token'">String</xsl:when>
					<xsl:when test="$type = 'integer'">int</xsl:when>
					<xsl:when test="$type = 'int'">int</xsl:when>
					<xsl:when test="$type = 'positiveInteger'">int</xsl:when>
					<xsl:when test="$type = 'negativeInteger'">int</xsl:when>
					<xsl:when test="$type = 'nonPositiveInteger'">int</xsl:when>
					<xsl:when test="$type = 'nonNegativeInteger'">int</xsl:when>
					<xsl:when test="$type = 'long'">Number</xsl:when>
					<xsl:when test="$type = 'unsignedLong'">Number</xsl:when>
					<xsl:when test="$type = 'short'">Number</xsl:when>
					<xsl:when test="$type = 'unsignedShort'">Number</xsl:when>
					<xsl:when test="$type = 'float'">Number</xsl:when>
					<xsl:when test="$type = 'double'">Number</xsl:when>
					<xsl:when test="$type = 'byte'">int</xsl:when>
					<xsl:when test="$type = 'unsignedByte'">int</xsl:when>
					<xsl:when test="$type = 'decimal'">Number</xsl:when>
					<xsl:when test="$type = 'boolean'">Boolean</xsl:when>
					<xsl:when test="$type = 'dateTime'">Date</xsl:when>
					<xsl:when test="$type = 'date'">Date</xsl:when>
					<xsl:when test="$type = 'time'">Date</xsl:when>
					<xsl:otherwise>String</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="getNs">
		<xsl:choose>
			<xsl:when test="$ns"><xsl:value-of select="$ns"/></xsl:when>
			<xsl:otherwise>services</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
		<xsl:template name="getNsPath">
		<xsl:choose>
			<xsl:when test="$ns">src/<xsl:value-of select="translate($ns,'.','/')"/></xsl:when>
			<xsl:otherwise>src/services</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>