<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"	
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns="http://hul.harvard.edu/ois/xml/ns/jhove"
	xmlns:jhove="http://hul.harvard.edu/ois/xml/ns/jhove" 
	xmlns:mix="http://www.loc.gov/mix/v10" 
	xmlns:textmd="info:lc/xmlns/textMD-v3" 
	exclude-result-prefixes="#all" version="2.0">
	<xsl:output encoding="UTF-8" indent="yes" method="xml"/>
	<xsl:strip-space elements="*"/>

	<!-- default behavior is to tidy up indentation while copying the element and its children -->
	<xsl:template match="*">
		<xsl:element name="{name(.)}" namespace="{namespace-uri(.)}">
			<xsl:apply-templates select="@*|node()"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="@*|text()">
		<xsl:copy>
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:copy>
	</xsl:template>


	<xsl:template match="jhove:jhove">
		<xsl:element name="{name(.)}" namespace="{namespace-uri(.)}">
			<xsl:namespace name="mix" select="'http://www.loc.gov/mix/v10'"/>
			<xsl:namespace name="textmd" select="'info:lc/xmlns/textMD-v3'"/>
			<xsl:for-each select="@*">
				<xsl:copy/>
			</xsl:for-each>
			<xsl:attribute name="schemaLocation" namespace="http://www.w3.org/2001/XMLSchema-instance">http://hul.harvard.edu/ois/xml/ns/jhove http://cosimo.stanford.edu/standards/jhove/v1/jhove.xsd</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="jhove:repInfo">
		<xsl:variable name="jhove-format">
			<xsl:value-of select="jhove:format"/>
		</xsl:variable>
		<xsl:variable name="filenameExtension">
			<xsl:value-of select="lower-case(tokenize(@uri,'\.')[last()])"/>
		</xsl:variable>
		<xsl:variable name="includeExtension" as="xs:boolean">
			<xsl:choose>
				<xsl:when test="$filenameExtension='jp2'">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="$filenameExtension='tif' or $filenameExtension='tiff'">
						<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="$filenameExtension='txt'">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:when test="$filenameExtension='htm' or $filenameExtension='html'">
					<xsl:value-of select="true()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
			</xsl:choose>			
		</xsl:variable>
		<xsl:copy exclude-result-prefixes="#all">
			<xsl:for-each select="@*">
				<xsl:copy/>
			</xsl:for-each>
			<xsl:apply-templates/>
			<xsl:if test="$includeExtension">
				<xsl:call-template name="objectCharacteristicsExtension">
					<xsl:with-param name="format" select="$jhove-format"/>
					<xsl:with-param name="properties" select="jhove:properties"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:call-template name="checksums">
				<xsl:with-param name="checksums" select="jhove:checksums"/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>

	<!-- Do not copy the existing properties, checksums, or note structure -->
	<xsl:template match="jhove:properties"/>
	<xsl:template match="jhove:checksums"/>
	<xsl:template match="jhove:messages"/>
	<!-- Instead, create a custom structure -->
	<xsl:template name="objectCharacteristicsExtension">
		<xsl:param name="format"/>
		<xsl:param name="properties"/>
		
		<properties>
			<property>
				<name>objectCharacteristicsExtension</name>
				<values arity="Scalar" type="Object">
					<value>
						<xsl:choose>
							<xsl:when test="$format='JPEG 2000'">
								<xsl:apply-templates select="$properties//mix:mix"/>
							</xsl:when>
							<xsl:when test="$format='TIFF'">
								<xsl:apply-templates select="$properties//mix:mix"/>
							</xsl:when>
							<xsl:when test="$format='HTML' or $format='ASCII' or $format='UTF-8'">
								<xsl:variable name="jhove-LineEndings" select="$properties//jhove:name[text()='LineEndings']/../jhove:values[1]/jhove:value[1]"/>
								<xsl:call-template name="textmd">
									<xsl:with-param name="jhove-LineEndings">
										<xsl:value-of select="$jhove-LineEndings"/>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
						</xsl:choose>
					</value>
				</values>
			</property>
		</properties>
	</xsl:template>



	<xsl:template match="mix:mix" exclude-result-prefixes="#all">
		<mix:mix>
			<xsl:apply-templates/>
		</mix:mix>
	</xsl:template>

	<xsl:template name="textmd" exclude-result-prefixes="#all">
		<xsl:param name="jhove-LineEndings"/>
		<xsl:variable name="linebreak">
			<xsl:choose>
				<xsl:when test="string($jhove-LineEndings)">
					<xsl:choose>
						<xsl:when test="$jhove-LineEndings='CRLF'">
							<xsl:text>CR/LF</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$jhove-LineEndings"/>							
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'LF'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<textmd:textMD>
			<textmd:character_info>
				<textmd:byte_order>big</textmd:byte_order>
				<textmd:byte_size>8</textmd:byte_size>
				<textmd:character_size>1</textmd:character_size>
				<textmd:linebreak>
					<xsl:value-of select="$linebreak"/>
				</textmd:linebreak>
			</textmd:character_info>
			<textmd:pageOrder>left-to-right</textmd:pageOrder>
			<textmd:pageSequence>reading-order</textmd:pageSequence>
		</textmd:textMD>
	</xsl:template>

	<xsl:template name="checksums" exclude-result-prefixes="#all">
		<xsl:param name="checksums"/>
		<checksums>
			<xsl:for-each select="$checksums//jhove:checksum">
				<checksum>
					<xsl:attribute name='type'>
						<xsl:value-of select="@type"/>
					</xsl:attribute>
				<xsl:value-of select="."/>
				</checksum>
			</xsl:for-each>
		</checksums>
		</xsl:template>
			



</xsl:stylesheet>
