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

	<!--  SET UP PARAMETERS AND DEFAULTS -->
	<xsl:param name="ns"/>
	<xsl:variable name="defaultServiceName">Service</xsl:variable>
	<xsl:variable name="serviceName">
		<xsl:choose>
			<xsl:when test="/wsdl:definitions/wsdl:service/@name"><xsl:value-of select="/wsdl:definitions/wsdl:service/@name"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$defaultServiceName"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="soapPortType" select="/wsdl:definitions/wsdl:binding[soap:binding][1]/@type"/>
	<xsl:variable name="soapPortName" select="substring-after($soapPortType, ':')"/>
	<xsl:variable name="portType" select="(/wsdl:definitions/wsdl:portType[@name = $soapPortName]|/wsdl:definitions/wsdl:portType[1])[1]"/>

	<!-- CREATE THE PACKAGE -->
  <xsl:template match="/">
		<package>
			<xsl:attribute name="class"><xsl:value-of select="$serviceName"/></xsl:attribute>
			<xsl:attribute name="name"><xsl:value-of select="$serviceName"/>.Javascript</xsl:attribute>
			<folder copy="JavaScript/Source"/>
			<!-- <folder copy="JavaScript/Documentation"/> -->
			<folder copy="JavaScript/Examples"/>
			<xsl:apply-templates select="/wsdl:definitions"/>
		</package>
	</xsl:template>

  <xsl:template match="wsdl:definitions">
		<file>
			<xsl:attribute name="filename">Examples/<xsl:value-of select="$serviceName"/>.html</xsl:attribute>&lt;html&gt;
	&lt;head&gt;
		&lt;script src="../Source/Soap.js" language="Javascript" type="text/javascript">&lt;/script&gt;
		&lt;script src="../Source/<xsl:value-of select="$serviceName"/>.js" language="Javascript" type="text/javascript">&lt;/script&gt;
		&lt;script language="Javascript"&gt;
			var service=new <xsl:value-of select="$ns"/>.<xsl:value-of select="$serviceName"/>();
		&lt;/script&gt;
	&lt;/head&gt;
&lt;/html&gt;
		</file>
		<file>
			<xsl:attribute name="filename">Source/<xsl:value-of select="$serviceName"/>.js</xsl:attribute>
			<xsl:if test="wsdl:documentation">
/* <xsl:value-of select="wsdl:documentation"/> */
			</xsl:if>
/* Define web service proxy methods and callbacks */
	var $ns=soap.ns("<xsl:value-of select="$ns"/>");
  $ns.<xsl:value-of select="$serviceName"/>=function(service,namespace){
    this.service=service;this.namespace=namespace;
    if(!this.service){this.service="<xsl:value-of select="/wsdl:definitions/wsdl:service/wsdl:port[1]/soap:address/@location"/>";}
    if(!this.namespace){this.namespace="<xsl:value-of select="/wsdl:definitions/@targetNamespace"/>";}
  }

	<xsl:apply-templates select="$portType/wsdl:operation" mode="def"/>
/* Define methods for returning response objects */
	<xsl:apply-templates select="$portType/wsdl:operation/wsdl:output" mode="results"/>
/* Define complex return objects */
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name]" mode="obj"/>
    "<xsl:value-of select="$serviceName"/>";
		</file>
  </xsl:template>
	
	<xsl:template match="wsdl:operation" mode="def">
		<xsl:variable name="name"><xsl:value-of select="@name"/></xsl:variable>
		<xsl:variable name="action"><xsl:value-of select="/wsdl:definitions/wsdl:binding/wsdl:operation[@name = $name]/soap:operation/@soapAction"/></xsl:variable>
		<xsl:variable name="service"><xsl:value-of select="//*/wsdl:service/@name"/></xsl:variable>
		<xsl:variable name="msg"><xsl:value-of select="substring-after(wsdl:input/@message, ':')"/></xsl:variable>

	<xsl:if test="wsdl:documentation">
/* <xsl:value-of select="wsdl:documentation"/> */
</xsl:if>
	$ns.<xsl:value-of select="$serviceName"/>.prototype.<xsl:value-of select="@name"/>=function(<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="params"/>){
		var env=soap.createEnvelope(this.namespace,"<xsl:value-of select="@name"/>",[<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="q_params"/>],[<xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $msg]" mode="params"/>]);
		return soap.getXml(this.service,env,"<xsl:value-of select="$action"/>", this.<xsl:value-of select="@name"/>_,this);
	}
	$ns.<xsl:value-of select="$serviceName"/>.prototype.<xsl:value-of select="@name"/>_=function(response,handler,caller){
    var doc=soap.createCallback(response,handler);
    if(doc){
    	var object=null;
      <xsl:apply-templates select="wsdl:output" mode="def"/>
      handler.onload(object);
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
						object=caller.<xsl:value-of select="@name"/>(doc);
					</xsl:when>
					<xsl:otherwise>object=soap.convertType(doc,'<xsl:value-of select="$typeName"/>');</xsl:otherwise>
				</xsl:choose>				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="wsdl:part" mode="def">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="def"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="def">object=caller.<xsl:value-of select="descendant::s:element/@name"/>(doc);</xsl:template>
	
	<xsl:template match="s:complexType" mode="def">object=caller.<xsl:value-of select="@name"/>(doc);</xsl:template>

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
		<xsl:for-each select="descendant::s:element"><xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if></xsl:for-each>
	</xsl:template>
	
	<xsl:template match="wsdl:message" mode="q_params">
		<xsl:choose>
			<xsl:when test="wsdl:part[@element]"><xsl:apply-templates select="wsdl:part" mode="q_params"/></xsl:when>
			<xsl:otherwise><xsl:for-each select="wsdl:part">"<xsl:value-of select="@name"/>"<xsl:if test="position() != last()">,</xsl:if></xsl:for-each></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="wsdl:part" mode="q_params">
		<xsl:variable name="element"><xsl:value-of select="substring-after(@element, ':')"/></xsl:variable>
		<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $element]" mode="q_params"/>
	</xsl:template>
	
	<xsl:template match="s:element" mode="q_params">
		<xsl:for-each select="descendant::s:element">"<xsl:value-of select="@name"/>"<xsl:if test="position() != last()">,</xsl:if></xsl:for-each>
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

				$ns.<xsl:value-of select="$serviceName"/>.prototype.<xsl:value-of select="$name"/>=function(response){
				var node=soap.getNode(response,"<xsl:value-of select="$name"/>");
				if(node){
					<xsl:choose>
						<xsl:when test="//*/s:complexType[@name = $type]/*/s:element[@maxOccurs = 'unbounded']">
					return soap.getArray(node,'<xsl:value-of select="$objType"/>');
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="//*/s:complexType[@name = $type]">
					return new <xsl:value-of select="$type"/>(node);
								</xsl:when>
								<xsl:otherwise>
					return soap.convertType(node,'<xsl:value-of select="$objType"/>');
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

		$ns.<xsl:value-of select="$serviceName"/>.prototype.<xsl:value-of select="$name"/>=function(response){
		var node=soap.getNode(response,"<xsl:value-of select="$name"/>");
		if(node){
			<xsl:choose>
				<xsl:when test="//*/s:complexType[@name = $type]/*/s:restriction[@base = 'soapenc:Array'] | //*/s:complexType[@name = $type]/*/s:element[@maxOccurs = 'unbounded']">
					<xsl:variable name="arrayType"><xsl:value-of select="substring-before(substring-after(//*/s:complexType[@name = $type]/*//*/s:restriction[@base = 'soapenc:Array']/s:attribute[@ref = 'soapenc:arrayType']/@wsdl:arrayType, ':'), '[')"/></xsl:variable>
			return soap.getArray(node,'<xsl:value-of select="$objType"/>');
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="//*/s:complexType[@name = $type]">
			return new <xsl:value-of select="$type"/>(node);
						</xsl:when>
						<xsl:otherwise>
			if(soap.secure()){netscape.security.PrivilegeManager.enablePrivilege("UniversalBrowserRead");}
			if(node.firstChild){node=node.firstChild;}
			return node.nodeValue;
						</xsl:otherwise>
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
		<xsl:value-of select="@name"/> = function(node) {
			this.__class="<xsl:value-of select="@name"/>";
      soap.init(this,node,[<xsl:apply-templates select="descendant::s:element" mode="obj"/>],[<xsl:apply-templates select="descendant::s:element" mode="types"/>]);
		}
		$ns.<xsl:value-of select="$serviceName"/>.prototype.toString=function(){return soap.serialize(this);}
		</xsl:if>
	</xsl:template>
	<xsl:template match="s:element" mode="obj">'<xsl:value-of select="@name"/>'<xsl:if test="position() != last()">,</xsl:if></xsl:template>
	<xsl:template match="s:element" mode="types">'<xsl:value-of select="@type"/>'<xsl:if test="position() != last()">,</xsl:if></xsl:template>	
	
</xsl:stylesheet>