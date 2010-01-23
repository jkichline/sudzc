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
	xmlns:mss="http://schemas.microsoft.com/2003/10/Serialization/"
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
#import "Soap.h";
	</xsl:template>

	<!-- DOCUMENTATION TEMPLATE -->
	<xsl:template match="wsdl:documentation">
/* <xsl:value-of select="."/> */
	</xsl:template>

	<!-- SERVICE INTERFACE -->
	<xsl:template name="createInterface">
		<xsl:param name="service"/>
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> : SoapService
		<xsl:apply-templates select="$portType/wsdl:operation" mode="interface"/>
		
	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>*) service;
	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>*) serviceWithUsername: (NSString*) username andPassword: (NSString*) password;
@end
	</xsl:template>
	
	<!-- SERVICE IMPLEMENTATION -->
	<xsl:template name="createImplementation">
		<xsl:param name="service"/>
		<xsl:variable name="url" select="$service/wsdl:port/soap:address/@location"/>
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>

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
	
	- (id) initWithUsername: (NSString*) username andPassword: (NSString*) password {
		if(self = [super initWithUsername:username andPassword:password]) {
		}
		return self;
	}
	
	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>*) service {
		return [<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> serviceWithUsername:nil andPassword:nil];
	}
	
	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>*) serviceWithUsername: (NSString*) username andPassword: (NSString*) password {
		return [[[<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> alloc] initWithUsername:username andPassword:password] autorelease];
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
		<xsl:variable name="objectType"><xsl:apply-templates select="wsdl:output" mode="object_name"/></xsl:variable>
		<xsl:variable name="deserializeTo">
			<xsl:choose>
				<xsl:when test="contains($objectType, 'alloc]')">[<xsl:value-of select="$objectType"/> autorelease]</xsl:when>
				<xsl:otherwise><xsl:value-of select="$objectType"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
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

	- (SoapRequest*) <xsl:value-of select="@name"/>: (id) _target action: (SEL) _action<xsl:apply-templates select="wsdl:input" mode="param_selectors"/>
		{
		NSMutableArray* _params = [NSMutableArray array];
		<xsl:apply-templates select="wsdl:input" mode="param_array"/>
		NSString* _envelope = [Soap createEnvelope: @"<xsl:value-of select="@name"/>" forNamespace: self.namespace withParameters: _params withHeaders: self.headers];
		SoapRequest* _request = [SoapRequest create: _target action: _action service: self soapAction: @"<xsl:value-of select="$action"/>" postData: _envelope deserializeTo: <xsl:value-of select="$deserializeTo"/>];
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
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element|/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $elementName]/s:sequence/s:element" mode="param_selectors"/></xsl:when>
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
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element|/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $elementName]/s:sequence/s:element" mode="param_names"/></xsl:when>
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
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element|/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $elementName]/s:sequence/s:element" mode="param_array"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_array"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:element|wsdl:part" mode="param_array">
		[_params addObject: [[[SoapParameter alloc] initWithValue: <xsl:apply-templates select="." mode="getValueForParameter"/> forName: @"<xsl:value-of select="@name"/>"] autorelease]];</xsl:template>
	
	
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
			<xsl:with-param name="actualName"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="serialize">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="xsdType"/>
		<xsl:param name="actualName"/>
		<xsl:variable name="serializeName">
			<xsl:choose>
				<xsl:when test="$actualName = ''"><xsl:value-of select="$xsdType"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$actualName"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type = 'NSString*'">[[<xsl:value-of select="$name"/> stringByReplacingOccurrencesOfString:@"\"" withString:@"&amp;quot;"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&amp;amp;"]</xsl:when>
			<xsl:when test="$type = 'BOOL'">(<xsl:value-of select="$name"/>)?@"true":@"false"</xsl:when>
			<xsl:when test="$type = 'int'">[NSString stringWithFormat: @"%i", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'short'">[NSString stringWithFormat: @"%i", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'char'">[NSString stringWithFormat: @"%c", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'long'">[NSString stringWithFormat: @"%ld", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'double'">[NSString stringWithFormat: @"%f", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'float'">[NSString stringWithFormat: @"%f", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSNumber*'">[NSString stringWithFormat: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSDecimalNumber*'">[NSString stringWithFormat: @"%@", <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSDate*'">[Soap getDateString: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSData*'">[Soap getBase64String: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'NSMutableArray*' or $type = 'NSMutableDictionary*'">[<xsl:value-of select="$shortns"/><xsl:value-of select="$xsdType"/> serialize: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:when test="$type = 'id' or $type = 'nil'">[Soap serialize: <xsl:value-of select="$name"/>]</xsl:when>
			<xsl:otherwise>[<xsl:value-of select="$name"/> serialize: @"<xsl:value-of select="$serializeName"/>"]</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="wsdl:output" mode="object_name">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:variable name="schemaType">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@type, ':')"/>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="$elementName != ''">
					<xsl:variable name="element" select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]"/>
					<xsl:call-template name="getType">
						<xsl:with-param name="value" select="$element/s:complexType/s:sequence/s:element/@type"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$schemaType != ''">
					<xsl:call-template name="getType">
						<xsl:with-param name="value" select="$schemaType"/>
					</xsl:call-template>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="originalType">
			<xsl:choose>
				<xsl:when test="$elementName != ''">
					<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element/@type, ':')"/>
				</xsl:when>
				<xsl:when test="$schemaType != ''">
					<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $schemaType]/s:sequence/s:element/@type, ':')"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="deserializer">
			<xsl:choose>
				<xsl:when test="$type = 'NSMutableArray*' or $type = 'NSMutableDictionary*'"><xsl:value-of select="$shortns"/><xsl:value-of select="$originalType"/></xsl:when>
				<xsl:when test="contains($type, '*')"><xsl:value-of select="substring-before($type, '*')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type = 'nil'">nil</xsl:when>
			<xsl:when test="$type != 'id' and contains($type, '*') and starts-with($deserializer, 'NS') = false">[<xsl:value-of select="$deserializer"/> alloc]</xsl:when>
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
		<xsl:variable name="schemaType">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@type, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''">
				<xsl:variable name="element" select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]"/>
				<xsl:variable name="type">
					<xsl:call-template name="getType">
						<xsl:with-param name="value" select="$element/s:complexType/s:sequence/s:element/@type"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$element/s:complexType/s:sequence/s:element/descendant-or-self::s:any">CXMLNode*</xsl:when>
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


	<!-- COMPLEX TYPES INTERFACE AND IMPLEMENTATION -->

	<xsl:template match="s:complexType" mode="class_reference"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@class <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>;</xsl:if></xsl:template>
	
	<xsl:template match="s:complexType" mode="interface">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:choose>
				<xsl:when test="s:annotation/s:appinfo[mss:IsDictionary = 'true']">
					<xsl:apply-templates select="." mode="interface_dictionary"/>
				</xsl:when>
				<xsl:when test="(count(*)=1) and (s:sequence/s:element[@maxOccurs = 'unbounded'] or s:complexContent/s:restriction/s:attribute[@wsdl:arrayType])">
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
		<xsl:if test="$type = 'NSMutableArray*' or $type = 'NSMutableDictionary*' or (contains($type, '*') and $type != 'id' and not(starts-with($type, 'NS')))">
@class <xsl:value-of select="$shortns"/><xsl:value-of select="substring-after(@type, ':')"/>;</xsl:if></xsl:template>
	
	<xsl:template match="s:element" mode="import_reference">
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="@type"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type = 'NSMutableArray*' or $type = 'NSMutableDictionary*'">
#import "<xsl:call-template name="getArrayType"><xsl:with-param name="value" select="@type"/></xsl:call-template>.h";</xsl:when>
			<xsl:otherwise>
				<xsl:if test="contains($type, '*') and $type != 'id' and not(starts-with($type, 'NS'))">
#import "<xsl:value-of select="substring-before($type, '*')"/>.h";</xsl:if>			
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="s:attribute[@arrayType!='']" mode="import_reference">
		<xsl:variable name="type">
			<xsl:call-template name="getType">
				<xsl:with-param name="value" select="@arrayType"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$type = 'NSMutableArray*' or $type = 'NSMutableDictionary*' or (contains($type, '*') and $type = 'id' and not(starts-with($type, 'NS')))">
#import "<xsl:value-of select="substring-before($type, '*')"/>.h";</xsl:if></xsl:template>
	
	<xsl:template match="s:complexType" mode="import_reference">
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h";</xsl:template>

	<xsl:template match="s:complexType" mode="implementation">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:choose>
				<xsl:when test="s:annotation/s:appinfo[mss:IsDictionary = 'true']">
					<xsl:apply-templates select="." mode="implementation_dictionary"/>
				</xsl:when>
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
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The interface definition of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> object.
	Generated by SudzC.com
*/
<xsl:call-template name="imports"/>
<xsl:apply-templates select="descendant::s:element" mode="import_reference"/>
					<xsl:apply-templates select="." mode="interface_object_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="interface_object_internals"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:complexType" mode="interface_object_internals">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="baseType">
				<xsl:choose>
					<xsl:when test="descendant::s:extension[@base]">
						<xsl:value-of select="$shortns"/><xsl:value-of select="substring-after(descendant::s:extension/@base, ':')"/>
					</xsl:when>
					<xsl:otherwise>SoapObject</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="$baseType != 'SoapObject' and $templateName = 'ObjCFiles'">
#import "<xsl:value-of select="$baseType"/>.h"
@class <xsl:value-of select="$baseType"/>;
</xsl:if>

@interface <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> : <xsl:value-of select="$baseType"/>
{
	<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="interface_variables"/>
}
		<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="interface_properties"/>

	+ (<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>*) newWithNode: (CXMLNode*) node;
	- (id) initWithNode: (CXMLNode*) node;
	- (NSMutableString*) serialize;
	- (NSMutableString*) serialize: (NSString*) nodeName;
	- (NSMutableString*) serializeAttributes;
	- (NSMutableString*) serializeElements;

@end
</xsl:if></xsl:template>

	<xsl:template match="s:complexType" mode="implementation_object">
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.m</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The implementation of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> object.
	Generated by SudzC.com
*/
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h"
<xsl:apply-templates select="descendant::s:element" mode="import_reference"/>
					<xsl:apply-templates select="." mode="implementation_object_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="implementation_object_internals"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:complexType" mode="implementation_object_internals"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
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
		return (<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>*)[[[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> alloc] initWithNode: node] autorelease];
	}

	- (id) initWithNode: (CXMLNode*) node {
		if(self = [super initWithNode: node])
		{<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="implementation"/>
		}
		return self;
	}

	- (NSMutableString*) serialize
	{
		return [self serialize: @"<xsl:value-of select="@name"/>"];
	}
  
	- (NSMutableString*) serialize: (NSString*) nodeName
	{
		NSMutableString* s = [[NSMutableString alloc] init];
		[s appendFormat: @"&lt;%@", nodeName];
		[s appendString: [self serializeAttributes]];
		[s appendString: @"&gt;"];
		[s appendString: [self serializeElements]];
		[s appendFormat: @"&lt;/%@&gt;", nodeName];
		return [s autorelease];
	}
	
	- (NSMutableString*) serializeElements
	{
		NSMutableString* s = [super serializeElements];
<xsl:apply-templates select="descendant::s:element" mode="implementation_serialize"/>
		return s;
	}
	
	- (NSMutableString*) serializeAttributes
	{
		NSMutableString* s = [super serializeAttributes];
<xsl:apply-templates select="descendant::s:attribute" mode="implementation_serialize"/>
		return s;
	}
	
	-(BOOL)isEqual:(id)object{
		if(object != nil &amp;&amp; [object isKindOfClass:[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> class]]) {
			return [[self serialize] isEqualToString:[object serialize]];
		}
		return NO;
	}
	
	-(NSUInteger)hash{
		return [Soap generateHash:self];

	}
	
	- (void) dealloc
	{<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="dealloc"/>
		[super dealloc];
	}

@end
</xsl:if></xsl:template>

	<!-- CREATES A DICTIONARY -->
	
	<xsl:template match="s:complexType" mode="interface_dictionary">
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The interface definition of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> dictionary.
	Generated by SudzC.com
*/
<xsl:call-template name="imports"/>
<xsl:apply-templates select="descendant::s:element" mode="import_reference"/>
					<xsl:apply-templates select="." mode="interface_dictionary_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="interface_dictionary_internals"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="s:complexType" mode="interface_dictionary_internals"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> : SoapDictionary
{
}

@end
</xsl:if></xsl:template>
	
	<!-- CREATES AN ARRAY -->

	<xsl:template match="s:complexType" mode="interface_array">
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The interface definition of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> array.
	Generated by SudzC.com
*/
<xsl:call-template name="imports"/>
<xsl:apply-templates select="descendant::s:element" mode="import_reference"/>
					<xsl:apply-templates select="." mode="interface_array_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="interface_array_internals"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="s:complexType" mode="interface_array_internals"><xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
@interface <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> : SoapArray
{
}

@end
</xsl:if></xsl:template>
	
	<!-- IMPLEMENTATION FOR DICTIONARIES -->
	
	<xsl:template match="s:complexType" mode="implementation_dictionary">
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.m</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The implementation of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> dictionary.
	Generated by SudzC.com
*/
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h"
<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="import_reference"/>
					<xsl:apply-templates select="." mode="implementation_dictionary_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="implementation_dictionary_internals"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="s:complexType" mode="implementation_dictionary_internals">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="keyElement" select="s:sequence/s:element/s:complexType/s:sequence/s:element[1]"/>
			<xsl:variable name="keyType">
				<xsl:call-template name="getType">
					<xsl:with-param name="value" select="$keyElement/@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="keyObjectType">
				<xsl:choose>
					<xsl:when test="$keyType = ''">id</xsl:when>
					<xsl:when test="$keyType = 'BOOL'">NSNumber*;</xsl:when>
					<xsl:when test="$keyType = 'int'">NSNumber*</xsl:when>
					<xsl:when test="$keyType = 'long'">NSNumber*</xsl:when>
					<xsl:when test="$keyType = 'double'">NSNumber*</xsl:when>
					<xsl:when test="$keyType = 'float'">NSNumber*</xsl:when>
					<xsl:when test="$keyType = 'short'">NSNumber*</xsl:when>
					<xsl:when test="$keyType = 'char'">NSNumber*</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$keyType"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:variable name="valueElement" select="s:sequence/s:element/s:complexType/s:sequence/s:element[2]"/>
			<xsl:variable name="valueType">
				<xsl:call-template name="getType">
					<xsl:with-param name="value" select="$valueElement/@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="valueObjectType">
				<xsl:choose>
					<xsl:when test="$valueType = ''">id</xsl:when>
					<xsl:when test="$valueType = 'BOOL'">NSNumber*;</xsl:when>
					<xsl:when test="$valueType = 'int'">NSNumber*</xsl:when>
					<xsl:when test="$valueType = 'long'">NSNumber*</xsl:when>
					<xsl:when test="$valueType = 'double'">NSNumber*</xsl:when>
					<xsl:when test="$valueType = 'float'">NSNumber*</xsl:when>
					<xsl:when test="$valueType = 'short'">NSNumber*</xsl:when>
					<xsl:when test="$valueType = 'char'">NSNumber*</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$valueType"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>

	+ (id) newWithNode: (CXMLNode*) node
	{
		return [[[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> alloc] initWithNode: node] autorelease];
	}

	- (id) initWithNode: (CXMLNode*) node
	{
		if(self = [self init]) {
			for(CXMLElement* child in [node children])
			{
				<xsl:value-of select="$keyObjectType"/> key = <xsl:choose>
					<xsl:when test="$keyType = 'NSString*'">[child stringValue];</xsl:when>
					<xsl:when test="$keyType = 'BOOL'">[NSNumber numberWithBool: [[child stringValue] boolValue]];</xsl:when>
					<xsl:when test="$keyType = 'int'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$keyType = 'short'">[NSNumber numberWithInt: [[child stringValue] shortValue]];</xsl:when>
					<xsl:when test="$keyType = 'char'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$keyType = 'long'">[NSNumber numberWithLong: [[child stringValue] longLongValue]];</xsl:when>
					<xsl:when test="$keyType = 'double'">[NSNumber numberWithDouble: [[child stringValue] doubleValue]];</xsl:when>
					<xsl:when test="$keyType = 'float'">[NSNumber numberWithFloat: [[child stringValue] floatValue]];</xsl:when>
					<xsl:when test="$keyType = 'NSDecimalNumber*'">[NSDecimalNumber decimalNumberWithString: [child stringValue]];</xsl:when>
					<xsl:when test="$keyType = 'NSDate*'">[Soap dateFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$keyType = 'NSData*'">[Soap dataFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$keyType = '' or $keyType = 'id'">[Soap objectFromNode: child];</xsl:when>
					<xsl:otherwise>[<xsl:value-of select="substring-before($keyObjectType, '*')"/> newWithNode: child];</xsl:otherwise>
				</xsl:choose>
				
				<xsl:value-of select="$valueObjectType"/> value = <xsl:choose>
					<xsl:when test="$valueType = 'NSString*'">[child stringValue];</xsl:when>
					<xsl:when test="$valueType = 'BOOL'">[NSNumber numberWithBool: [[child stringValue] boolValue]];</xsl:when>
					<xsl:when test="$valueType = 'int'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$valueType = 'short'">[NSNumber numberWithInt: [[child stringValue] shortValue]];</xsl:when>
					<xsl:when test="$valueType = 'char'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$valueType = 'long'">[NSNumber numberWithLong: [[child stringValue] longLongValue]];</xsl:when>
					<xsl:when test="$valueType = 'double'">[NSNumber numberWithDouble: [[child stringValue] doubleValue]];</xsl:when>
					<xsl:when test="$valueType = 'float'">[NSNumber numberWithFloat: [[child stringValue] floatValue]];</xsl:when>
					<xsl:when test="$valueType = 'NSDecimalNumber*'">[NSDecimalNumber decimalNumberWithString: [child stringValue]];</xsl:when>
					<xsl:when test="$valueType = 'NSDate*'">[Soap dateFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$valueType = 'NSData*'">[Soap dataFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$valueType = '' or $valueType = 'id'">[Soap objectFromNode: child];</xsl:when>
					<xsl:otherwise>[<xsl:value-of select="substring-before($valueObjectType, '*')"/> newWithNode: child];</xsl:otherwise>
				</xsl:choose>
				if(value != nil) {
					[self setObject: value forKey: key];
				}
			}
		}
		return self;
	}
	
	+ (NSMutableString*) serialize: (NSDictionary*) dictionary
	{
		NSMutableString* s = [NSMutableString string];
		for(id key in dictionary) {
			[s appendString: <xsl:call-template name="serialize">
				<xsl:with-param name="name">key</xsl:with-param>
				<xsl:with-param name="type"><xsl:value-of select="$keyType"/></xsl:with-param>
				<xsl:with-param name="xsdType"><xsl:value-of select="$keyElement/@type"/></xsl:with-param>
			</xsl:call-template>];
			[s appendString: <xsl:call-template name="serialize">
				<xsl:with-param name="name">[dictionary objectForKey:key]</xsl:with-param>
				<xsl:with-param name="type"><xsl:value-of select="$valueType"/></xsl:with-param>
				<xsl:with-param name="xsdType"><xsl:value-of select="$valueElement/@type"/></xsl:with-param>
			</xsl:call-template>];
		}
		return s;
	}
@end
</xsl:if></xsl:template>
	
	
	<!-- IMPLEMENTATION FOR ARRAYS -->

	<xsl:template match="s:complexType" mode="implementation_array">
		<xsl:choose>
			<xsl:when test="$templateName = 'ObjCFiles'">
				<file>
					<xsl:attribute name="filename">Proxy Classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.m</xsl:attribute>/*
	<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h
	The implementation of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> array.
	Generated by SudzC.com
*/
#import "<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.h"
<xsl:apply-templates select="descendant::s:element|descendant::s:attribute" mode="import_reference"/>
					<xsl:apply-templates select="." mode="implementation_array_internals"/>
				</file>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="implementation_array_internals"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:complexType" mode="implementation_array_internals">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="actualType">
				<xsl:choose>
					<xsl:when test="descendant::s:element/@type != ''">
						<xsl:value-of select="substring-after(descendant::s:element/@type, ':')"/>
					</xsl:when>
					<xsl:when test="descendant::*/@wsdl:arrayType != ''">
						<xsl:value-of select="translate(substring-after(descendant::*/@wsdl:arrayType, ':'), '[]','')"/>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="declaredType">
				<xsl:choose>
					<xsl:when test="descendant::s:element/@type != ''">
						<xsl:call-template name="getType">
							<xsl:with-param name="value" select="descendant::s:element/@type"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="descendant::*/@wsdl:arrayType != ''">
						<xsl:call-template name="getType">
							<xsl:with-param name="value" select="translate(descendant::*/@wsdl:arrayType, '[]', '')"/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="arrayType">
				<xsl:choose>
					<xsl:when test="$declaredType = ''">id</xsl:when>
					<xsl:when test="$declaredType = 'BOOL'">NSNumber*;</xsl:when>
					<xsl:when test="$declaredType = 'int'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'long'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'double'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'float'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'short'">NSNumber*</xsl:when>
					<xsl:when test="$declaredType = 'char'">NSNumber*</xsl:when>
					<xsl:otherwise><xsl:value-of select="$declaredType"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
@implementation <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>

	+ (id) newWithNode: (CXMLNode*) node
	{
		return [[[<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> alloc] initWithNode: node] autorelease];
	}

	- (id) initWithNode: (CXMLNode*) node
	{
		if(self = [self init]) {
			for(CXMLElement* child in [node children])
			{
				<xsl:value-of select="$arrayType"/> value = <xsl:choose>
					<xsl:when test="$declaredType = 'NSString*'">[child stringValue];</xsl:when>
					<xsl:when test="$declaredType = 'BOOL'">[NSNumber numberWithBool: [[child stringValue] boolValue]];</xsl:when>
					<xsl:when test="$declaredType = 'int'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$declaredType = 'short'">[NSNumber numberWithInt: [[child stringValue] shortValue]];</xsl:when>
					<xsl:when test="$declaredType = 'char'">[NSNumber numberWithInt: [[child stringValue] intValue]];</xsl:when>
					<xsl:when test="$declaredType = 'long'">[NSNumber numberWithLong: [[child stringValue] longLongValue]];</xsl:when>
					<xsl:when test="$declaredType = 'double'">[NSNumber numberWithDouble: [[child stringValue] doubleValue]];</xsl:when>
					<xsl:when test="$declaredType = 'float'">[NSNumber numberWithFloat: [[child stringValue] floatValue]];</xsl:when>
					<xsl:when test="$declaredType = 'NSDecimalNumber*'">[NSDecimalNumber decimalNumberWithString: [child stringValue]];</xsl:when>
					<xsl:when test="$declaredType = 'NSDate*'">[Soap dateFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$declaredType = 'NSData*'">[Soap dataFromString: [child stringValue]];</xsl:when>
					<xsl:when test="$declaredType = '' or $declaredType = 'id'">[Soap objectFromNode: child];</xsl:when>
					<xsl:otherwise>[<xsl:value-of select="substring-before($declaredType, '*')"/> newWithNode: child];</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$declaredType != 'id' and contains($declaredType, '*') and not(starts-with($declaredType, 'NS'))">
				if(value != nil) {
					[self addObject: value];
				}</xsl:when>
					<xsl:otherwise>
				[self addObject: value];</xsl:otherwise></xsl:choose>
			}
		}
		return self;
	}
	
	+ (NSMutableString*) serialize: (NSArray*) array
	{
		NSMutableString* s = [NSMutableString string];
		for(id item in array) {
			[s appendString: <xsl:call-template name="serialize">
				<xsl:with-param name="name">item</xsl:with-param>
				<xsl:with-param name="type"><xsl:value-of select="$arrayType"/></xsl:with-param>
				<xsl:with-param name="xsdType"><xsl:value-of select="$actualType"/></xsl:with-param>
			</xsl:call-template>];
		}
		return s;
	}
@end
</xsl:if></xsl:template>

	<xsl:template match="s:element|s:attribute" mode="interface_variables"><xsl:if test="@name">
	<xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/><xsl:with-param name="defaultType">id</xsl:with-param></xsl:call-template> _<xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>;
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
	@synthesize <xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template> = _<xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template>;</xsl:if></xsl:template>

	<xsl:template match="s:element|s:attribute" mode="implementation_alloc">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>
			<xsl:if test="contains($type,'*')">
				<xsl:choose>
					<xsl:when test="$type = 'NSMutableArray*'">			self.<xsl:value-of select="$name"/> = [[[<xsl:value-of select="translate($type,'*','')"/> alloc] init] autorelease];
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
	<xsl:template match="s:element" mode="implementation_serialize">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>
			<xsl:variable name="serialized"><xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates></xsl:variable>

			<xsl:choose>
				<xsl:when test="$type = 'NSMutableArray*'">		if (self.<xsl:value-of select="$name"/> != nil &amp;&amp; self.<xsl:value-of select="$name"/>.count &gt; 0) [s appendFormat: @"&lt;<xsl:value-of select="@name"/>&gt;%@&lt;/<xsl:value-of select="@name"/>&gt;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
</xsl:when>
				<xsl:when test="contains($type, '*') or $type = 'id'">
					<xsl:choose>
						<xsl:when test="contains($serialized, 'serialize:')">		if (self.<xsl:value-of select="$name"/> != nil) [s appendString: <xsl:value-of select="$serialized"/>];
</xsl:when>
						<xsl:otherwise>		if (self.<xsl:value-of select="$name"/> != nil) [s appendFormat: @"&lt;<xsl:value-of select="@name"/>&gt;%@&lt;/<xsl:value-of select="@name"/>&gt;", <xsl:value-of select="$serialized"/>];
</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($serialized, 'serialize:')">		[s appendString: <xsl:value-of select="$serialized"/>];
</xsl:when>
						<xsl:otherwise>		[s appendFormat: @"&lt;<xsl:value-of select="@name"/>&gt;%@&lt;/<xsl:value-of select="@name"/>&gt;", <xsl:value-of select="$serialized"/>];
</xsl:otherwise>
					</xsl:choose>

</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
  
	<xsl:template match="s:attribute" mode="implementation_serialize">
		<xsl:if test="@name">
			<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
			<xsl:variable name="name"><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></xsl:variable>

			<xsl:choose>
				<xsl:when test="contains($type, '*') or $type = 'id'">		if (self.<xsl:value-of select="$name"/> != nil) [s appendFormat: @" <xsl:value-of select="@name"/>=\&quot;%@\&quot;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
</xsl:when>
				<xsl:otherwise>		[s appendFormat: @" <xsl:value-of select="@name"/>=\&quot;%@\&quot;", <xsl:apply-templates select="." mode="serialize"><xsl:with-param name="prefix">self.</xsl:with-param></xsl:apply-templates>];
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
			<xsl:if test="contains($type,'*') or $type = 'id'">
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
			<xsl:when test="$declaredType = 'char'">[[NSNumber numberWithInt: [[Soap getNodeValue: node withName: @"<xsl:value-of select="$name"/>"] intValue]] charValue]</xsl:when>
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
		<xsl:value-of select="$value"/>
	</xsl:template>

	<!-- TEMPLATE TO RETURN A TYPE -->
	<xsl:template name="getArrayType">
		<xsl:param name="value"/>
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="contains($value, ':')"><xsl:value-of select="substring-after($value,':')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$shortns"/><xsl:value-of select="$type"/>
	</xsl:template>

	<!-- TEMPLATE TO RETURN A TYPE -->
	<xsl:template name="getType">
		<xsl:param name="value"/>
		<xsl:param name="defaultType"/>
		<xsl:choose>
			<xsl:when test="$value = ''">id</xsl:when>
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
					<xsl:when test="$isDictionary">NSMutableDictionary*</xsl:when>
					<xsl:when test="$isArray">NSMutableArray*</xsl:when>
					<xsl:when test="$simpleType"><xsl:call-template name="getType"><xsl:with-param name="value" select="$simpleType/descendant::s:restriction/@base"/></xsl:call-template></xsl:when>
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
							<xsl:when test="$type = 'byte'">char</xsl:when>
							<xsl:when test="$type = 'unsignedByte'">char</xsl:when>
							<xsl:when test="$type = 'decimal'">NSDecimalNumber*</xsl:when>
							<xsl:when test="$type = 'boolean'">BOOL</xsl:when>
							<xsl:when test="$type = 'dateTime'">NSDate*</xsl:when>
							<xsl:when test="$type = 'date'">NSDate*</xsl:when>
							<xsl:when test="$type = 'time'">NSDate*</xsl:when>
							<xsl:when test="$type = 'base64Binary'">NSData*</xsl:when>
							<xsl:when test="$type = 'anyType'">id</xsl:when>
							<xsl:when test="$type = 'anyURI'">id</xsl:when>
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
	
	<!-- CREATE DOCUMENTATION -->
	<xsl:template name="createDocumentation">
		<xsl:param name="service"/>
		<file>
			<xsl:attribute name="filename">Documentation/classes/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute><html>
	<head>
		<title><xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/></title>
		<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js"></script>
		<script type="text/javascript" src="../assets/scripts/base.js"></script>
	</head>
	<body id="content">
		<h1><xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> Class Reference</h1>
		<p>The implementation classes and methods for the <xsl:value-of select="$serviceName"/> web service.</p>
		<p>Inherits from <a href="../framework/SoapService.html">SoapService</a>.</p>
		<h2>Properties</h2>
		
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
		<xsl:variable name="link">
			<xsl:choose>
				<xsl:when test="starts-with($return, $shortns) and contains($return, '*')"><a><xsl:attribute name="href"><xsl:value-of select="substring-before($return, '*')"/>.html</xsl:attribute><xsl:value-of select="$return"/></a></xsl:when>
				<xsl:otherwise><xsl:value-of select="$return"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="signature"><xsl:value-of select="@name"/>:<xsl:apply-templates select="wsdl:input" mode="param_signature"/></xsl:variable>
		<h3 id="{$signature}"><xsl:value-of select="$signature"/></h3>
		<p>
			<xsl:value-of select="wsdl:documentation"/>
			Returns <xsl:copy-of select="$link"/> to the designated <a href="../framework/SoapDelegate.html">SoapDelegate</a>.
		</p>
		<code>- (<a href="../framework/SoapRequest.html">SoapRequest*</a>) <xsl:value-of select="@name"/>: (id &lt;<a href="../framework/SoapDelegate.html">SoapDelegate</a>&gt;) handler<xsl:apply-templates select="wsdl:input" mode="param_documentation"/></code>
		
		<xsl:variable name="signature2"><xsl:value-of select="@name"/>:action:<xsl:apply-templates select="wsdl:input" mode="param_signature"/></xsl:variable>
		<h3 id="{$signature2}"><xsl:value-of select="$signature2"/></h3>
		<p>
			<xsl:value-of select="wsdl:documentation"/>
			Returns <xsl:copy-of select="$link"/> to the specified target/action receiver.
		</p>
		<code>- (<a href="../framework/SoapRequest.html">SoapRequest*</a>) <xsl:value-of select="@name"/>: (id) target action: (SEL) action<xsl:apply-templates select="wsdl:input" mode="param_documentation"/>;</code>
		
	</xsl:template>
	
	
	<!-- DOCUMENT CLASSES -->
	<xsl:template match="s:complexType" mode="documentation">
		<xsl:if test="generate-id(.) = generate-id(key('className', @name)[1])">
			<xsl:variable name="baseClass">
				<xsl:choose>
					<xsl:when test="s:annotation/s:appinfo[mss:IsDictionary = 'true']">SoapDictionary</xsl:when>
					<xsl:when test="(count(*)=1) and (s:sequence/s:element[@maxOccurs = 'unbounded'] or s:complexContent/s:restriction/s:attribute[@wsdl:arrayType])">SoapArray</xsl:when>
					<xsl:otherwise>SoapObject</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<file>
				<xsl:attribute name="filename">Documentation/classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.html</xsl:attribute>
				<html>
					<head>
						<title><xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> Class Reference</title>
						<link rel="stylesheet" type="text/css" href="../assets/styles/default.css"/>
						<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js"></script>
						<script type="text/javascript" src="../assets/scripts/base.js"></script>
					</head>
					<body id="content">
						<h1><xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> Class Reference</h1>
						<p>
							The definition of properties and methods for the <xsl:value-of select="$shortns"/><xsl:value-of select="@name"/> object.
							<xsl:value-of select="wsdl:documentation"/>
						</p>
						<p>
							Inherits from the <a href="../framework/{$baseClass}.html"><xsl:value-of select="$baseClass"/></a> base class.
						</p>

						<h2>Properties</h2>
						<p>For more about Objective-C properties, see <span class="content_text"><a href="http://developer.apple.com/iphone/library/documentation/Cocoa/Conceptual/ObjectiveC/Articles/ocProperties.html#//apple_ref/doc/uid/TP30001163-CH17" target="_top">&#8220;Properties&#8221;</a></span> in <em><a href="http://developer.apple.com/iphone/library/documentation/Cocoa/Conceptual/ObjectiveC/index.html#//apple_ref/doc/uid/TP30001163" target="_top">The Objective-C Programming Language</a></em>.</p>
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
					<xsl:with-param name="defaultType">id</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="link">
				<xsl:choose>
					<xsl:when test="starts-with($type, $shortns) and contains($type, '*')"><a><xsl:attribute name="href"><xsl:value-of select="substring-before($type, '*')"/>.html</xsl:attribute><xsl:value-of select="$type"/></a><xsl:value-of select="concat('', ' ')"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="concat($type, ' ')"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<h3 id="{@name}"><xsl:value-of select="@name"/></h3>
			<xsl:if test="wsdl:documentation">
				<p><xsl:value-of select="wsdl:documentation"/></p>
			</xsl:if>
			<code>@property <xsl:if test="contains($type, '*') or $type = 'id'">(retain, nonatomic) </xsl:if><xsl:copy-of select="$link"/><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></code>
		</xsl:if>
	</xsl:template>
	
	
	<!-- DOCUMENT SELECTORS -->
	
		<xsl:template match="wsdl:input|wsdl:output|wsdl:fault" mode="param_signature">
		<xsl:variable name="messageName">
			<xsl:value-of select="substring-after(@message, ':')"/>
		</xsl:variable>
		<xsl:variable name="elementName">
			<xsl:value-of select="substring-after(/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part/@element, ':')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$elementName != ''"><xsl:apply-templates select="/wsdl:definitions/wsdl:types/s:schema/s:element[@name = $elementName]/s:complexType/s:sequence/s:element|/wsdl:definitions/wsdl:types/s:schema/s:complexType[@name = $elementName]/s:sequence/s:element" mode="param_signature"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="/wsdl:definitions/wsdl:message[@name = $messageName]/wsdl:part" mode="param_signature"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="s:element|wsdl:part" mode="param_signature">
		<xsl:value-of select="@name"/>:
	</xsl:template>
	
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
		<xsl:variable name="type"><xsl:call-template name="getType"><xsl:with-param name="value" select="@type"/></xsl:call-template></xsl:variable>
		<xsl:variable name="link">
			<xsl:choose>
				<xsl:when test="starts-with($type, $shortns) and contains($type, '*')"><a><xsl:attribute name="href">classes/<xsl:value-of select="substring-before($type, '*')"/>.html</xsl:attribute><xsl:value-of select="$type"/></a><xsl:value-of select="concat('', ' ')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="concat(' ', @name)"/>: (<xsl:copy-of select="$link"/>) <em><xsl:call-template name="getName"><xsl:with-param name="value" select="@name"/></xsl:call-template></em>
	</xsl:template>

	<!-- CREATE TABLE OF CONTENTS -->
	<xsl:template name="createIndex">
		<file>
			<xsl:attribute name="filename">Documentation/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute>
			<html>
				<head>
					<title><xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/> Documentation</title>
				</head>
				<frameset cols="25%,75%">
					<frame name="toc"><xsl:attribute name="src">toc/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute></frame>
					<frame name="content"><xsl:attribute name="src">classes/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute></frame>
				</frameset>
			</html>
		</file>
		<file>
			<xsl:attribute name="filename">Documentation/toc/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute>
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
								<li><a target="content"><xsl:attribute name="href">../classes/<xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/>.html</xsl:attribute><xsl:value-of select="$shortns"/><xsl:value-of select="$serviceName"/></a></li>
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
								<li><a target="content" href="../framework/SoapArray.html">SoapArray</a></li>
								<li><a target="content" href="../framework/SoapDelegate.html">SoapDelegate</a></li>
								<li><a target="content" href="../framework/SoapDictionary.html">SoapDictionary</a></li>
								<li><a target="content" href="../framework/SoapFault.html">SoapFault</a></li>
								<li><a target="content" href="../framework/SoapHandler.html">SoapHandler</a></li>
								<li><a target="content" href="../framework/SoapNil.html">SoapNil</a></li>
								<li><a target="content" href="../framework/SoapObject.html">SoapObject</a></li>
								<li><a target="content" href="../framework/SoapParameter.html">SoapParameter</a></li>
								<li><a target="content" href="../framework/SoapReachability.html">SoapReachability</a></li>
								<li><a target="content" href="../framework/SoapRequest.html">SoapRequest</a></li>
								<li><a target="content" href="../framework/SoapService.html">SoapService</a></li>
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
				<xsl:attribute name="href">../classes/<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>.html</xsl:attribute>
				<xsl:attribute name="title"><xsl:value-of select="wsdl:documentation"/></xsl:attribute>
				<xsl:value-of select="$shortns"/><xsl:value-of select="@name"/>
			</a>
		</li>
	</xsl:template>

</xsl:stylesheet>