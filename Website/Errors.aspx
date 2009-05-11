<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Errors.aspx.cs" Inherits="Errors" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head id="Head1" runat="server">
		<title>SudzC alpha | clean source code from your web services</title>
		<link rel="stylesheet" href="assets/styles/default.css" type="text/css" />
	</head>
	<body onload="init();">
		<div id="content">
			<a id="A1" href="~/" runat="server"><img src="assets/images/logo.png" alt="Sudzc" id="logo" /></a>
			<form action="Default.aspx" method="get" id="form">
				<div>
					<label>Problems Generating Your Code</label>
					<p>The following issues were encountered while generating your code:</p>
					<blockquote><%= this.Request["message"] %></blockquote>
					<p><input type="submit" value="Try Again" /></p>
				</div>
			</form>
		</div>
	</body>
</html>