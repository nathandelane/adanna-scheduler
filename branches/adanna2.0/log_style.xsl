<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html xmlns:ev="http://www.w3.org/2001/xml-events">
			<head>
				<link rel="stylesheet" href="log_style.css" type="text/css"/>
			</head>
			<body>
				<div style="position:absolute;top:0px;left:0px;width:100%;height:150px;">
					<xsl:for-each select="Log/Header">
						<h2><xsl:value-of select="Title"/></h2>
						<h5><xsl:value-of select="Timestamp"/></h5><br />
					</xsl:for-each>
					<table border="0">
						<tr>
							<td><b>Statistics:</b></td>
							<td></td>
							<td></td>
						</tr>
						<tr class="passTitleStyle">
							<td></td>
							<td class="titleStyle">
								Pass:
							</td>
							<td>
								<xsl:value-of select="count(Log/LogItem[MessageType='Pass' or MessageType='pass'])"/>
							</td>
						</tr>
						<tr class="failTitleStyle">
							<td></td>
							<td class="titleStyle">
								Fail:
							</td>
							<td>
								<xsl:value-of select="count(Log/LogItem[MessageType='Fail'])"/>
							</td>
						</tr>
						<tr class="doneTitleStyle">
							<td></td>
							<td class="titleStyle">
								Done:
							</td>
							<td>
								<xsl:value-of select="count(Log/LogItem[MessageType='Done'])"/>
							</td>
						</tr>
					</table>
					<hr />
					<table border="0">
						<tr>
							<th style="text-align:left;width:2em;text-decoration:underline;">State</th>
							<th style="text-align:left;width:8em;text-decoration:underline;">Timestamp</th>
							<th style="text-align:left;width:8em;text-decoration:underline;">Message</th>
						</tr>
					</table>
					<br />
				</div>
				<div style="position:absolute;top:230px;left:0px;width:100%;height:50%;overflow:scroll;float:left;">
					<table border="0">
						<xsl:for-each select="Log/LogItem">
						<tr>
							<xsl:choose>
								<xsl:when test="MessageType = 'Pass' or MessageType = 'pass'">
									<td class="passTitleStyle"><b><xsl:value-of select="MessageType"/>,</b></td>
									<td class="passStyle"><xsl:value-of select="Timestamp"/>,</td>
									<td class="passStyle"><xsl:value-of select="Message"/>,</td>
								</xsl:when>
								<xsl:when test="MessageType = 'Fail'">
									<td class="failTitleStyle"><b><xsl:value-of select="MessageType"/>,</b></td>
									<td class="failStyle"><xsl:value-of select="Timestamp"/>,</td>
									<td class="failStyle"><xsl:value-of select="Message"/>,</td>
								</xsl:when>
								<xsl:when test="MessageType = 'Done'">
									<td class="doneTitleStyle"><b><xsl:value-of select="MessageType"/>,</b></td>
									<td class="doneStyle"><xsl:value-of select="Timestamp"/>,</td>
									<td class="doneStyle"><xsl:value-of select="Message"/>,</td>
								</xsl:when>
								<xsl:otherwise>
									<td><xsl:value-of select="MessageType"/></td>
								</xsl:otherwise>
							</xsl:choose>
						</tr>
						</xsl:for-each>
					</table>
				</div>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>