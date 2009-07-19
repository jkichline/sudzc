<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
	xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
	xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
	xmlns:wsap="http://schemas.xmlsoap.org/ws/2004/08/addressing/policy"
	xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"
	xmlns:msc="http://schemas.microsoft.com/ws/2005/12/wsdl/contract"
	xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl"
	xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/"
	xmlns:wsa10="http://www.w3.org/2005/08/addressing"
	xmlns:wsam="http://www.w3.org/2007/05/addressing/metadata"
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:s="http://www.w3.org/2001/XMLSchema"
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
	xmlns:tns="http://epm.aholdusa.com/webservices/"
	xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	
	<!-- PULL IN PARAMETERS AND DEFAULTS -->
	<xsl:param name="shortns"/>
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
	
	<!-- TEMPLATE TO INCLUDE FOR IMPORTS -->
	<xsl:template name="imports">
#import "TouchXML.h"
#import "Soap.h";
#import "SoapFault.h";
#import "SoapObject.h";
#import "SoapArray.h";
#import "SoapDelegate.h";
#import "SoapHandler.h";
#import "SoapRequest.h";
#import "SoapNil.h"
	</xsl:template>

	<!-- DOCUMENTATION TEMPLATE -->
	<xsl:template match="wsdl:documentation">
/* <xsl:value-of select="."/> */
	</xsl:template>

	<!-- SERVICE INTERFACE -->
	<xsl:template name="createInterface">
		<xsl:param name="service"/>
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> : NSObject
{
	NSString* serviceUrl;
	NSString* namespace;
	NSDictionary* headers;
	BOOL logging;
}

	@property (retain) NSString* serviceUrl;
	@property (retain) NSString* namespace;
	@property (retain) NSDictionary* headers;
	@property BOOL logging;
	
	- (id) initWithUrl: (NSString*) url;

		<xsl:apply-templates select="$portType/wsdl:operation" mode="interface"/>

@end
	</xsl:template>
	
	<!-- SERVICE IMPLEMENTATION -->
	<xsl:template name="createImplementation">
		<xsl:param name="service"/>
		<xsl:variable name="url" select="$service/wsdl:port/soap:address/@location"/>
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>

	@synthesize serviceUrl, namespace, logging, headers;

	- (id) init
	{
		if(self = [super init])
		{
			self.serviceUrl = @"<xsl:value-of select="$url"/>";
			self.namespace = @"<xsl:value-of select="/wsdl:definitions/@targetNamespace"/>";
			self.headers = nil;
			self.logging = NO;
		}
		return self;
	}
	
	- (id) initWithUrl: (NSString*) url
	{
		if(self = [self init])
		{
			self.serviceUrl = url;
		}
		return self;
	}

		<xsl:apply-templates select="$portType/wsdl:operation" mode="implementation"/>

@end
	</xsl:template>

<xsl:template match="wsdl:operation" mode="interface">
	/* Returns <xsl:apply-templates select="wsdl:output" mode="object_type"/>. <xsl:value-of select="wsdl:documentation"/> */
	- (SoapRequest*) <xsl:value-of select="@name"/>: (id &lt;SoapDelegate&gt;) handler<xsl:apply-templates select="wsdl:input" mode="param_selectors"/>;
	- (SoapRequest*) <xsl:value-of select="@name"/>: (id) target action: (SEL) action<xsl:apply-templates select="wsdl:input" mode="param_selectors"/>;
</xsl:template>

	<xsl:template match="wsdl:operation" mode="implementation">
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="action">
			<xsl:choose>
				<xsl:when test="wsdl:input/@wsaw:Action"><xsl:value-of select="wsdl:input/@wsaw:Action"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="/wsdl:definitions/wsdl:binding/wsdl:operation[@name = $name]/soap:operation/@soapAction"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	/* Returns <xsl:apply-templates select="wsdl:output" mode="object_type"/>. <xsl:value-of select="wsdl:documentation"/> */
	- (SoapRequest*) <xsl:value-of select="@name"/>: (id &lt;SoapDelegate&gt;) handler<xsl:apply-templates select="wsdl:input" mode="param_selectors"/>
	{
		return [self <xsl:value-of select="@name"/>: handler action: nil<xsl:apply-templates select="wsdl:input" mode="param_names"/>];
	}

	- (SoapRequest*) <xsl:value-of select="@name"/>: (id) target action: (SEL) action<xsl:apply-templates select="wsdl:input" mode="param_selectors"/>
		{
		NSMutableArray* _params = [NSMutableArray array];
		<xsl:apply-templates select="wsdl:input" mode="param_array"/>
		NSString* _envelope = [Soap createEnvelope: @"<xsl:value-of select="@name"/>" forNamespace: self.namespace withParameters: _params withHeaders: headers];
		SoapRequest* _request = [SoapRequest create: target action: action urlString: self.serviceUrl soapAction: @"<xsl:value-of select="$action"/>" postData: _envelope deserializeTo: <xsl:apply-templates select="wsdl:output" mode="object_name"/>];
		_request.logging = self.logging;
		[_request send];
		return _request;
	}
</xsl:template>

	
	<!-- PARAMETER SELECTORS -->
	<xsl:template match="wsdl:input|wsdl:output|wsdl:fault" mode="param_selectors">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element" mode="param_selectors"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_selectors"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:element|wsdl:part" mode="param_selectors">
		<xsl:value-of select="concat(' ', @name)"/>: (<xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template>) <xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>
	</xsl:template>


	<!-- PARAMETER NAMES -->
	<xsl:template match="wsdl:input|wsdl:output|wsdl:fault" mode="param_names">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element" mode="param_names"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_names"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="s:element|wsdl:part" mode="param_names">
		<xsl:value-of select="concat(' ', @name)"/>: <xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>
	</xsl:template>


	<!-- PARAMETERS AS DICTIONARY -->
	<xsl:template match="wsdl:input|wsdl:output|wsdl:fault" mode="param_array">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element" mode="param_array"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_array"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:element|wsdl:part" mode="param_array">
		[_params addObject: [[SoapParameter alloc] initWithValue: <xsl:apply-templates select="." mode="getValueForParameter"/> forName: @"<xsl:value-of select="@name"/>"]];</xsl:template>
	
	
	<!-- DICTIONARY ADDITION TEMPLATE -->
	<xsl:template match="s:element|s:attribute|wsdl:part" mode="getValueForParameter">
		<xsl:param name="prefix"/>
		<xsl:call-template name="getValueForParameter">
			<xsl:with-param name="name"><xsl:value-of select="$prefix"/><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:with-param>
			<xsl:with-param name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:with-param>
			<xsl:with-param name="xsdType"><xsl:value-of select="substring-after(@type, ':')"/></xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="getValueForParameter">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="xsdType"/>
		<xsl:choose>
			<xsl:when test="$type = 'BOOL'">[NSNumber numberWithBool: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'int'">[NSNumber numberWithInt: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'long'">[NSNumber numberWithLong: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'double'">[NSNumber numberWithDouble: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'float'">[NSNumber numberWithFloat: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:otherwise><xsl:value-of select="$name"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
		
	<!-- SERIALIZER TEMPLATE -->
	<xsl:template match="s:element|s:attribute|wsdl:part" mode="serialize">
		<xsl:param name="prefix"/>
		<xsl:call-template name="serialize">
			<xsl:with-param name="name"><xsl:value-of select="$prefix"/><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:with-param>
			<xsl:with-param name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:with-param>
			<xsl:with-param name="xsdType"><xsl:value-of select="substring-after(@type, ':')"/></xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="serialize">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="xsdType"/>
		<xsl:choose>
			<xsl:when test="$type = 'NSString*'"><xsl:value-of select="$name"/></xsl:when>
			<xsl:when test="$type = 'BOOL'">(<xsl:value-of select="$name"/>)?@"true":@"false"</xsl:when>
			<xsl:when test="$type = 'int'">[NSString stringWithFormat: @"%i", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'short'">[NSString stringWithFormat: @"%i", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'long'">[NSString stringWithFormat: @"%ld", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'double'">[NSString stringWithFormat: @"%d", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'float'">[NSString stringWithFormat: @"%f", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSNumber*'">[NSString stringWithFormat: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSDecimalNumber*'">[NSString stringWithFormat: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSDate*'">[NSString stringWithFormat: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSData*'">[Soap getBase64String: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSMutableArray*'">[<xsl:value-of select="$shortns"/><xsl:value-of select="$xsdType"/> serialize: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'id' or $type = 'nil'">[Soap serialize: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:otherwise>[<xsl:value-of select="$name"/> serialize]</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="wsdl:output" mode="object_name">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:variable name="element" select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]"/>
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="$element/s:complexType/s:sequence/s:element/@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="deserializer">
			<xsl:choose>
				<xsl:when test="$type = 'NSMutableArray*'"><xsl:value-of select="$shortns"/><xsl:value-of select="substring-after($element/s:complexType/s:sequence/s:element/@type, ':')"/></xsl:when>
				<xsl:when test="contains($type, '*')"><xsl:value-of select="substring-before($type, '*')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type = 'nil'">nil</xsl:when>
			<xsl:when test="contains($type, '*') and starts-with($deserializer, 'NS') = false">[<xsl:value-of select="$deserializer"/> alloc]</xsl:when>
			<xsl:otherwise>@"<xsl:value-of select="$deserializer"/>"</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="wsdl:output" mode="object_type">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:variable name="element" select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]"/>
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="$element/s:complexType/s:sequence/s:element/@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type = ''">void</xsl:when>
			<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- COMPLEX TYPES INTERFACE AND IMPLEMENTATION -->

	<xsl:template match="s:complexType" mode="class_reference"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@class <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>;</xsl:if></xsl:template>
	
	<xsl:template match="s:complexType" mode="interface">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:choose>
				<xsl:when test="s:sequence/s:element[@maxOccurs = 'unbounded'] or s:complexContent/s:restriction/s:attribute[@wsdl:arrayType]">
					<xsl:apply-templates select="." mode="interface_array"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="interface_object"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="s:element" mode="class_reference">
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$type = 'NSMutableArray*' or (contains($type, '*') and not(starts-with($type, 'NS')))">
@class <xsl:value-of select="$shortns"/><xsl:value-of select="substring-after(@type, ':')"/>;</xsl:if></xsl:template>
	
	<xsl:template match="s:element" mode="import_reference">
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$type = 'NSMutableArray*' or (contains($type, '*') and not(starts-with($type, 'NS')))">
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="substring-after(@type, ':')"/>.h";</xsl:if></xsl:template>
	
	<xsl:template match="s:complexType" mode="import_reference">
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h";</xsl:template>

	<xsl:template match="s:complexType" mode="implementation">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:choose>
				<xsl:when test="s:sequence/s:element[@maxOccurs = 'unbounded'] or s:complexContent/s:restriction/s:attribute[@wsdl:arrayType]">
					<xsl:apply-templates select="." mode="implementation_array"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="implementation_object"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="s:complexType" mode="interface_object">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="baseType">
				<xsl:choose>
					<xsl:when test="descendant::s:extension[@base]">
						<xsl:value-of select="$shortns"/><xsl:value-of select="substring-after(descendant::s:extension/@base, ':')"/>
					</xsl:when>
					<xsl:otherwise>SoapObject</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:if test="$baseType != 'SoapObject' and $templateName = 'ObjCFiles'">#import "<xsl:value-of select="$baseType"/>.h"</xsl:if>
			
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> : <xsl:value-of select="$baseType"/>
{
	<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="interface_variables"/>
}
		<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="interface_properties"/>

	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>*) newWithNode: (CXMLNode*) node;
	- (id) initWithNode: (CXMLNode*) node;
	- (NSMutableString*) serialize;

@end
</xsl:if></xsl:template>

	<xsl:template match="s:complexType" mode="implementation_object"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>
		<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="implementation_synthesize"/>

	- (id) init
	{
		if(self = [super init])
		{
<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="implementation_alloc"/>
		}
		return self;
	}

	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>*) newWithNode: (CXMLNode*) node
	{
		if(node == nil) { return nil; }
		return (<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>*)[[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> alloc] initWithNode: node];
	}

	- (id) initWithNode: (CXMLNode*) node {
		if(self = [super initWithNode: node])
		{<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="implementation"/>
		}
		return self;
	}
	
	- (NSMutableString*) serialize
	{
		NSMutableString* s = [super serialize];
<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="implementation_serialize"/>
		return s;
	}
	
	- (void) dealloc
	{<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="dealloc"/>
		[super dealloc];
	}

@end
</xsl:if></xsl:template>
	
	
	
	<!-- CREATES AN ARRAY -->
	<xsl:template match="s:complexType" mode="interface_array"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> : SoapArray
{
	NSMutableArray *items;
}
	@property (retain, nonatomic) NSMutableArray *items;
	+ (NSMutableArray*) newWithNode: (CXMLNode*) node;
	- (NSMutableArray*) initWithNode: (CXMLNode*) node;
	+ (NSMutableString*) serialize: (NSArray*) array;

@end
</xsl:if></xsl:template>

	<xsl:template match="s:complexType" mode="implementation_array">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="actualType"><xsl:value-of select="substring-after(descendant::s:element/@type, ':')"/></xsl:variable>
			<xsl:variable name="declaredType"><xsl:call-template name="getType"><xsl:with-param name="value" select="descendant::s:element/@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="arrayType">
				<xsl:choose>
					<xsl:when test="$declaredType = 'BOOL'">NSNumber*;</xsl:when>
					<xsl:when test="$declaredType = 'int'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'long'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'double'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'float'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'short'">NSNumber*</xsl:when>
					<xsl:otherwise><xsl:value-of select="$declaredType"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>

	@synthesize items;

	+ (NSMutableArray*) newWithNode: (CXMLNode*) node
	{
		if(node == nil) { return nil; }
		return (NSMutableArray*)[[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> alloc] initWithNode: node];
	}

	- (NSMutableArray*) initWithNode: (CXMLNode*) node
	{
		[super initWithNode: node];
		items = [[NSMutableArray alloc] init];
		if(node == nil) { return items; }
		for(CXMLElement* child in [node children])
		{
			<xsl:value-of select="$arrayType"/> value = <xsl:choose>
				<xsl:when test="$declaredType = 'NSString*'">[child stringValue];</xsl:when>
				<xsl:when test="$declaredType = 'BOOL'">[NSNumber numberWithBool: [[child stringValue] boolValue]];</xsl:when>
				<xsl:when test="$declaredType = 'int'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
				<xsl:when test="$declaredType = 'short'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
				<xsl:when test="$declaredType = 'long'">[NSNumber numberWithLong: [[child stringValue] longLongValue]];</xsl:when>
				<xsl:when test="$declaredType = 'double'">[NSNumber numberWithDouble: [[child stringValue] doubleValue]];</xsl:when>
				<xsl:when test="$declaredType = 'float'">[NSNumber numberWithFloat: [[child stringValue] floatValue]];</xsl:when>
				<xsl:when test="$declaredType = 'NSDecimalNumber*'">[NSDecimalNumber decimalNumberWithString: [child stringValue]];</xsl:when>
				<xsl:when test="$declaredType = 'NSDate*'">[Soap dateFromString: [child stringValue]];</xsl:when>
				<xsl:when test="$declaredType = 'NSData*'">[Soap dataFromString: [child stringValue]];</xsl:when>
				<xsl:otherwise>[<xsl:value-of select="substring-before($declaredType, '*')"/> newWithNode: child];</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="contains($declaredType, '*') and not(starts-with($declaredType, 'NS'))">
			if(value != nil) {
				[items addObject: value];
			}
			[value release];</xsl:when>
				<xsl:otherwise>
			[items addObject: value];</xsl:otherwise></xsl:choose>		
		}
		return items;
	}
	
	+ (NSMutableString*) serialize: (NSArray*) array
	{
		NSMutableString* s = [NSMutableString string];
		for(id item in array) {
			[s appendFormat: @"&lt;<xsl:value-of select="$actualType"/>&gt;%@&lt;/<xsl:value-of select="$actualType"/>&gt;", <xsl:call-template name="serialize">
				<xsl:with-param name="name">item</xsl:with-param>
				<xsl:with-param name="type"><xsl:value-of select="$arrayType"/></xsl:with-param>
				<xsl:with-param name="xsdType"><xsl:value-of select="$actualType"/></xsl:with-param>
			</xsl:call-template>];
		}
		return s;
	}

	- (void) dealloc
	{
		[super dealloc];
	}
@end
</xsl:if></xsl:template>

	<xsl:template match="s:element|s:attribute" mode="interface_variables"><xsl:if test="@name">
	<xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/><xsl:with-param name="defaultType">id</xsl:with-param></xsl:call-template><xsl:value-of select="' '"/><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>;
	</xsl:if></xsl:template>		

	<xsl:template match="s:element|s:attribute" mode="interface_properties">
		<xsl:if test="@name">
			<xsl:variable name="type">
				<xsl:call-template name="getType">
					<xsl:with-param name="value" select="@type"/>
					<xsl:with-param name="defaultType">id</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
	@property <xsl:if test="contains($type, '*') or $type = 'id'">(retain, nonatomic) </xsl:if><xsl:value-of select="concat($type, ' ')"/><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>;</xsl:if></xsl:template>

	<xsl:template match="s:element|s:attribute" mode="implementation_synthesize"><xsl:if test="@name">
	@synthesize <xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>;</xsl:if></xsl:template>

	<xsl:template match="s:element|s:attribute" mode="implementation_alloc">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>
			<xsl:if test="contains($type,'*')">
				<xsl:choose>
					<xsl:when test="$type = 'NSMutableArray*'">			self.<xsl:value-of select="$name"/> = [[<xsl:value-of select="translate($type,'*','')"/> alloc] init];
</xsl:when>
					<xsl:when test="starts-with($type,'NS')">			self.<xsl:value-of select="$name"/> = nil;
</xsl:when>
					<xsl:otherwise>			self.<xsl:value-of select="$name"/> = nil; // [[<xsl:value-of select="translate($type,'*','')"/> alloc] init];
</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:if>
	</xsl:template>

<!-- addition to create serialize methods for each sub class -->
	<xsl:template match="s:element|s:attribute" mode="implementation_serialize">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>

			<xsl:choose>
				<xsl:when test="$type = 'NSMutableArray*'">		if (self.<xsl:value-of select="$name"/> != nil &amp;&amp; self.<xsl:value-of select="$name"/>.count &gt; 0) [s appendFormat: @"&lt;<xsl:value-of select="$name"/>&gt;%@&lt;/<xsl:value-of select="$name"/>&gt;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
</xsl:when>
				<xsl:when test="contains($type, '*') or $type = 'id'">		if (self.<xsl:value-of select="$name"/> != nil) [s appendFormat: @"&lt;<xsl:value-of select="$name"/>&gt;%@&lt;/<xsl:value-of select="$name"/>&gt;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
</xsl:when>
				<xsl:otherwise>		[s appendFormat: @"&lt;<xsl:value-of select="$name"/>&gt;%@&lt;/<xsl:value-of select="$name"/>&gt;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="s:element|s:attribute" mode="implementation">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			self.<xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template> = <xsl:call-template name="getNodeValue"><xsl:with-param name="declaredType" select="$type"/><xsl:with-param name="actualType" select="@type"/><xsl:with-param name="name" select="@name"/></xsl:call-template>;</xsl:if></xsl:template>
	
	<xsl:template match="s:element|s:attribute" mode="dealloc">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>
			<xsl:if test="contains($type,'*')">
		if(self.<xsl:value-of select="$name"/> != nil) { [self.<xsl:value-of select="$name"/> release]; }</xsl:if></xsl:if>
	</xsl:template>

	
	<!-- TEMPLATE TO RETURN A NODE VALUE -->
	<xsl:template name="getNodeValue">
		<xsl:param name="name"/>
		<xsl:param name="declaredType"/>
		<xsl:param name="actualType"/>
		<xsl:choose>
			<xsl:when test="$declaredType = 'NSString*'">[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"]</xsl:when>
			<xsl:when test="$declaredType = 'BOOL'">[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] boolValue]</xsl:when>
			<xsl:when test="$declaredType = 'int'">[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] intValue]</xsl:when>
			<xsl:when test="$declaredType = 'short'">(short)[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] intValue]</xsl:when>
			<xsl:when test="$declaredType = 'long'">[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] longLongValue]</xsl:when>
			<xsl:when test="$declaredType = 'double'">[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] doubleValue]</xsl:when>
			<xsl:when test="$declaredType = 'float'">[[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] floatValue]</xsl:when>
			<xsl:when test="$declaredType = 'NSDecimalNumber*'">[NSDecimalNumber decimalNumberWithString: [Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"]]</xsl:when>
			<xsl:when test="$declaredType = 'NSDate*'">[Soap dateFromString: [Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"]]</xsl:when>
			<xsl:when test="$declaredType = 'NSData*'">[Soap dataFromString: [Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"]]</xsl:when>
			<xsl:when test="$declaredType = 'nil' or $declaredType = 'id'">[Soap deserialize: [Soap getNode: node withName: @"<xsl:value-of select="$name"/>"]]</xsl:when>
			<xsl:otherwise>[<xsl:value-of select="$shortns"/><xsl:value-of select="substring-after($actualType, ':')"/> newWithNode: [Soap getNode: node withName: @"<xsl:value-of select="$name"/>"]]</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- TEMPLATE TO RETURN A NAME -->
	<xsl:template name="getName">
		<xsl:param name="value"/>
		<xsl:variable name="property" select="translate($value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
		<xsl:choose>
			<xsl:when test="$property = 'comment'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'id'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'entertainment'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'location'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'category'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'action'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'collection'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'size'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:when test="$property = 'point'"><xsl:value-of select="$value"/>Value</xsl:when>
			<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- TEMPLATE TO RETURN A TYPE -->
	<xsl:template name="getType">
		<xsl:param name="value"/>
		<xsl:param name="defaultType"/>
		<xsl:choose>
			<xsl:when test="$value = ''">id</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="type" select="substring-after($value,':')"/>
				<xsl:variable name="complexType" select="/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $type]"/>
				<xsl:variable name="simpleType" select="/wsdl:definitions/wsdl:types/s:schema/s:simpleType[@name = $type]"/>
				<xsl:variable name="isArray" select="$complexType/s:sequence/s:element[@maxOccurs = 'unbounded'] or $complexType/s:restriction/s:attribute[@wsdl:arrayType]"/>
				<xsl:choose>
					<xsl:when test="$isArray">NSMutableArray*</xsl:when>
					<xsl:when test="$simpleType"><xsl:call-template name="getType"><xsl:with-param name="value" select="$simpleType//*/s:restriction/@base"/></xsl:call-template></xsl:when>
					<xsl:when test="$complexType"><xsl:value-of select="$shortns"/><xsl:value-of select="$type"/>*</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$type = 'string'">NSString*</xsl:when>
							<xsl:when test="$type = 'normalizedString'">NSString*</xsl:when>
							<xsl:when test="$type = 'token'">NSString*</xsl:when>
							<xsl:when test="$type = 'integer'">int</xsl:when>
							<xsl:when test="$type = 'int'">int</xsl:when>
							<xsl:when test="$type = 'positiveInteger'">int</xsl:when>
							<xsl:when test="$type = 'negativeInteger'">int</xsl:when>
							<xsl:when test="$type = 'nonPositiveInteger'">int</xsl:when>
							<xsl:when test="$type = 'nonNegativeInteger'">int</xsl:when>
							<xsl:when test="$type = 'long'">long</xsl:when>
							<xsl:when test="$type = 'unsignedLong'">long</xsl:when>
							<xsl:when test="$type = 'short'">short</xsl:when>
							<xsl:when test="$type = 'unsignedShort'">short</xsl:when>
							<xsl:when test="$type = 'float'">float</xsl:when>
							<xsl:when test="$type = 'double'">double</xsl:when>
							<xsl:when test="$type = 'byte'">byte</xsl:when>
							<xsl:when test="$type = 'unsignedByte'">byte</xsl:when>
							<xsl:when test="$type = 'decimal'">NSDecimalNumber*</xsl:when>
							<xsl:when test="$type = 'boolean'">BOOL</xsl:when>
							<xsl:when test="$type = 'dateTime'">NSDate*</xsl:when>
							<xsl:when test="$type = 'date'">NSDate*</xsl:when>
							<xsl:when test="$type = 'time'">NSDate*</xsl:when>
							<xsl:when test="$type = 'base64Binary'">NSData*</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$type = ''">
										<xsl:choose>
											<xsl:when test="$defaultType = ''">nil</xsl:when>
											<xsl:otherwise><xsl:value-of select="$defaultType"/></xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise><xsl:value-of select="$shortns"/><xsl:value-of select="$type"/>*</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
