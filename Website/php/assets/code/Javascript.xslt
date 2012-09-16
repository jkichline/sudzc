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
	xmlns:mss="http://schemas.microsoft.com/2003/10/Serialization/"
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

	<!-- SETUP KEYS -->
	<xsl:key name="className" match="/wsdl:definitions/wsdl:types/s:schema/s:complexType" use="@name"/>
	<xsl:key name="elementType" match="/wsdl:definitions/wsdl:types/s:schema/s:complexType/s:element" use="@type"/>

	<!-- CREATE THE PACKAGE -->
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

  <xsl:template match="wsdl:definitions">
		<package>
			<xsl:attribute name="class"><xsl:value-of select="$serviceName"/></xsl:attribute>
			<xsl:attribute name="name"><xsl:value-of select="$serviceName"/>.Javascript</xsl:attribute>
			<folder copy="Javascript/Source"/>
			<folder copy="Javascript/Documentation"/>
			<folder copy="Javascript/Examples"/>

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

			<!-- Create Documentation -->
			<xsl:call-template name="createDocumentation"><xsl:with-param name="service" select="wsdl:service"/></xsl:call-template>
			<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name]" mode="documentation">
				<xsl:sort select="position()" order="descending"/>
			</xsl:apply-templates>
			<xsl:call-template name="createIndex"/>

		</package>
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


	<!-- TEMPLATE TO RETURN A TYPE -->
	<xsl:template name="getType">
		<xsl:param name="value"/>
		<xsl:param name="defaultType"/>
		<xsl:choose>
			<xsl:when test="$value = ''">var</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="type">
					<xsl:choose>
						<xsl:when test="contains($value, ':')"><xsl:value-of select="substring-after($value,':')"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="complexType" select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $type]"/>
				<xsl:variable name="simpleType" select="/wsdl:definitions/wsdl:types/s:schema/s:simpleType[@name = $type]"/>
				<xsl:variable name="isDictionary" select="$complexType/s:annotation/s:appinfo[mss:IsDictionary = 'true']"/>
				<xsl:variable name="isArray" select="$complexType/s:sequence/s:element[@maxOccurs = 'unbounded'] or $complexType/s:restriction/s:attribute[@wsdl:arrayType]"/>
				<xsl:choose>
					<xsl:when test="$isDictionary">dictionary</xsl:when>
					<xsl:when test="$isArray">array</xsl:when>
					<xsl:when test="$simpleType"><xsl:call-template name="getType"><xsl:with-param name="value" select="$simpleType/descendant::s:restriction/@base"/></xsl:call-template></xsl:when>
					<xsl:when test="$complexType"><xsl:value-of select="$type"/></xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$type = 'string'">string</xsl:when>
							<xsl:when test="$type = 'normalizedString'">string</xsl:when>
							<xsl:when test="$type = 'token'">string</xsl:when>
							<xsl:when test="$type = 'integer'">number</xsl:when>
							<xsl:when test="$type = 'int'">number</xsl:when>
							<xsl:when test="$type = 'positiveInteger'">number</xsl:when>
							<xsl:when test="$type = 'negativeInteger'">number</xsl:when>
							<xsl:when test="$type = 'nonPositiveInteger'">number</xsl:when>
							<xsl:when test="$type = 'nonNegativeInteger'">number</xsl:when>
							<xsl:when test="$type = 'long'">number</xsl:when>
							<xsl:when test="$type = 'unsignedLong'">number</xsl:when>
							<xsl:when test="$type = 'short'">number</xsl:when>
							<xsl:when test="$type = 'unsignedShort'">number</xsl:when>
							<xsl:when test="$type = 'float'">number</xsl:when>
							<xsl:when test="$type = 'double'">number</xsl:when>
							<xsl:when test="$type = 'byte'">number</xsl:when>
							<xsl:when test="$type = 'unsignedByte'">number</xsl:when>
							<xsl:when test="$type = 'decimal'">number</xsl:when>
							<xsl:when test="$type = 'boolean'">boolean</xsl:when>
							<xsl:when test="$type = 'dateTime'">date</xsl:when>
							<xsl:when test="$type = 'date'">date</xsl:when>
							<xsl:when test="$type = 'time'">date</xsl:when>
							<xsl:when test="$type = 'base64Binary'">string</xsl:when>
							<xsl:when test="$type = 'anyType'">var</xsl:when>
							<xsl:when test="$type = 'anyURI'">var</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$type = ''">
										<xsl:choose>
											<xsl:when test="$defaultType = ''">null</xsl:when>
											<xsl:otherwise><xsl:value-of select="$defaultType"/></xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- CREATE DOCUMENTATION -->
	<xsl:template name="createDocumentation">
		<xsl:param name="service"/>
		<file>
			<xsl:attribute name="filename">Documentation/classes/<xsl:value-of select="$serviceName"/>.html</xsl:attribute><html>
	<head>
		<title><xsl:value-of select="$serviceName"/></title>
		<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js"></script>
		<script type="text/javascript" src="../assets/scripts/base.js"></script>
	</head>
	<body id="content">
		<h1><xsl:value-of select="$serviceName"/> Class Reference</h1>
		<p>The implementation classes and methods for the <xsl:value-of select="$serviceName"/> web service.</p>

		<h2>Properties</h2>
		<h3>service</h3>
		<p>The URL that points to the web service to call.</p>
		<h3>namespace</h3>
		<p>The namespace of the web service call.</p>
		
		<h2>Instance Methods</h2>
		<xsl:apply-templates select="$portType/wsdl:operation" mode="documentation">
			<xsl:sort select="@name" order="ascending"/>
		</xsl:apply-templates>
		<div id="footer">Documentation generated by <a href="http://sudzc.com" target="_blank">SudzC</a>.</div>
	</body>
</html></file>
	</xsl:template>

	<xsl:template match="wsdl:operation" mode="documentation">
		<xsl:variable name="return"><xsl:apply-templates select="wsdl:output" mode="object_type"/></xsl:variable>
		<xsl:variable name="signature"><xsl:value-of select="@name"/>(<xsl:apply-templates select="wsdl:input" mode="param_documentation"/>)</xsl:variable>
		<h3 id="{@name}"><xsl:value-of select="$signature"/></h3>
		<xsl:if test="wsdl:documentation">
  		<p><xsl:value-of select="wsdl:documentation"/></p>
    </xsl:if>
		<p>Returns a value of type <a href="{$return}.html"><xsl:value-of select="$return"/></a> to the returned <a href="SoapHandler.html">SoapHandler</a>.</p>
		<code>var handler = service.<xsl:value-of select="$signature"/>;</code>		
	</xsl:template>
	
	
	<!-- DOCUMENT CLASSES -->
	<xsl:template match="s:complexType" mode="documentation">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="baseClass">
				<xsl:choose>
					<xsl:when test="descendant::s:extension[@base]">
						<xsl:value-of select="substring-after(descendant::s:extension/@base, ':')"/>
					</xsl:when>
					<xsl:otherwise></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<file>
				<xsl:attribute name="filename">Documentation/classes/<xsl:value-of select="@name"/>.html</xsl:attribute>
				<html>
					<head>
						<title><xsl:value-of select="@name"/> Class Reference</title>
						<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
						<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js"></script>
						<script type="text/javascript" src="../assets/scripts/base.js"></script>
					</head>
					<body id="content">
						<h1><xsl:value-of select="@name"/> Class Reference</h1>
						<p>
							The definition of properties and methods for the <xsl:value-of select="@name"/> object.
							<xsl:value-of select="wsdl:documentation"/>
						</p>
						<xsl:if test="$baseClass != ''">
  						<p>
  							Inherits from the <a href="{$baseClass}.html"><xsl:value-of select="$baseClass"/>*</a> base class.
  						</p>
    				</xsl:if>

						<h2>Properties</h2>
						<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="documentation_properties"/>

						<div id="footer">Documentation generated by <a href="http://sudzc.com" target="_blank">SudzC</a>.</div>
					</body>
				</html>
			</file>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="s:element|s:attribute" mode="documentation_properties">
		<xsl:if test="@name">
			<xsl:variable name="type">
				<xsl:call-template name="getType">
					<xsl:with-param name="value" select="@type"/>
					<xsl:with-param name="defaultType">var</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<h3 id="{@name}"><xsl:value-of select="@name"/></h3>
			<xsl:if test="wsdl:documentation">
				<p><xsl:value-of select="wsdl:documentation"/></p>
			</xsl:if>
			<p>Returns a value of type <a href="{$type}.html"><xsl:value-of select="$type"/></a>.</p>
			
		</xsl:if>
	</xsl:template>
	
	
	<!-- DOCUMENT SELECTORS -->
	
	<xsl:template match="wsdl:input|wsdl:output|wsdl:fault" mode="param_documentation">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element|/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $elementName]/s:sequence/s:element" mode="param_documentation"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_documentation"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:element|wsdl:part" mode="param_documentation">
		<em><xsl:value-of select="@name"/></em><xsl:if test="position() != last()">, </xsl:if>
	</xsl:template>

	<!-- CREATE TABLE OF CONTENTS -->
	<xsl:template name="createIndex">
		<file>
			<xsl:attribute name="filename">Documentation/<xsl:value-of select="$serviceName"/>.html</xsl:attribute>
			<html>
				<head>
					<title><xsl:value-of select="$serviceName"/> Documentation</title>
				</head>
				<frameset cols="25%,75%">
					<frame name="toc"><xsl:attribute name="src">toc/<xsl:value-of select="$serviceName"/>.html</xsl:attribute></frame>
					<frame name="content"><xsl:attribute name="src">classes/<xsl:value-of select="$serviceName"/>.html</xsl:attribute></frame>
				</frameset>
			</html>
		</file>
		<file>
			<xsl:attribute name="filename">Documentation/toc/<xsl:value-of select="$serviceName"/>.html</xsl:attribute>
			<html>
				<head>
					<title>Table of Contents</title>
					<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
				</head>
				<body id="toc">
					<dl>
						<dt>Services</dt>
						<dd>
							<ul>
								<li><a href="index.html">All Packages</a></li>
								<li><a target="content"><xsl:attribute name="href">../classes/<xsl:value-of select="$serviceName"/>.html</xsl:attribute><xsl:value-of select="$serviceName"/></a></li>
							</ul>
						</dd>
						<dt>Classes</dt>
						<dd>
							<ul>
								<xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name]" mode="documentation_index">
									<xsl:sort select="@name" order="ascending"/>
								</xsl:apply-templates>
							</ul>
						</dd>
						<dt>Framework</dt>
						<dd>
							<ul>
								<li><a target="content" href="../framework/Soap.html">Soap</a></li>
								<li><a target="content" href="../framework/SoapFault.html">SoapFault</a></li>
								<li><a target="content" href="../framework/SoapHandler.html">SoapHandler</a></li>
							</ul>
						</dd>
					</dl>
				</body>
			</html>
		</file>
	</xsl:template>

	<xsl:template match="s:complexType" mode="documentation_index">
		<li>
			<a target="content">
				<xsl:attribute name="href">../classes/<xsl:value-of select="@name"/>.html</xsl:attribute>
				<xsl:attribute name="title"><xsl:value-of select="wsdl:documentation"/></xsl:attribute>
				<xsl:value-of select="@name"/>
			</a>
		</li>
	</xsl:template>

	<xsl:template match="index">
		<package name="index">
			<file filename="Documentation/toc/index.html">
<html>
	<head>
		<title>Table of Contents</title>
		<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
	</head>
	<body id="toc">
		<dl>
			<dt>Tutorial</dt>
			<dd>
				<ul>
					<li><a target="content" href="../tutorial/index.html">Getting Started</a></li>
				</ul>
			</dd>
			<dt>Packages</dt>
			<dd>
				<ul>
					<xsl:for-each select="class">
						<xsl:sort select="." order="ascending"/>
						<li><a href="{.}.html"><xsl:value-of select="."/></a></li>
					</xsl:for-each>
				</ul>
			</dd>
		</dl>
	</body>
</html>
			</file>
		</package>
	</xsl:template>
	
	<xsl:template match="wsdl:output" mode="object_type">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:variable name="schemaType">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@type, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''">
				<xsl:variable name="element" select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]"/>
				<xsl:variable name="rawType">
					<xsl:choose>
						<xsl:when test="$element/s:complexType">
							<xsl:value-of select="$element/s:complexType/s:sequence/s:element/@type"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = substring-after($element/@type, ':')]/s:sequence/s:element/@type"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="type">
					<xsl:call-template name="getType">
						<xsl:with-param name="value" select="$rawType"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$element/s:complexType/s:sequence/s:element/descendant-or-self::s:any">var1</xsl:when>
					<xsl:when test="$type = ''">void</xsl:when>
					<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$schemaType != ''">
				<xsl:variable name="type">
					<xsl:call-template name="getType">
						<xsl:with-param name="value" select="$schemaType"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$type = ''">void</xsl:when>
					<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>