<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:s="http://www.w3.org/2001/XMLSchema"
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
	xmlns:tns="http://epm.aholdusa.com/webservices/"
	xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
	<xsl:output version="1.0" encoding="iso-8859-1" method="xml" omit-xml-declaration="no" indent="yes"/>

	<xsl:template match="s:import">
		<xsl:apply-templates select="document(@schemaLocation)/s:schema/*"/>
	</xsl:template>

	<xsl:template match="wsdl:import">
		<xsl:apply-templates select="document(@location)/wsdl:definitions/*"/>
	</xsl:template>

	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>