<%@ Page Language="C#" AutoEventWireup="true" CodeFile="SignIn.aspx.cs" Inherits="SignIn" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head id="Head1" runat="server">
		<title>SudzC alpha | clean source code from your web services</title>
		<link rel="stylesheet" href="assets/styles/default.css" type="text/css" />
		<script type="text/javascript">
			$=document.getElementById;
			function init(){
				var el=$("username");
				el.focus();
			}
		</script>
	</head>
	<body onload="init();">
		<div id="content">
			<a id="A1" href="~/" runat="server"><img src="assets/images/logo.png" alt="Sudzc" id="logo" /></a>
			<form action="Convert.ashx" method="post" id="form">
				<div>
					<label for="username">Your username</label>
					<input type="text" id="username" name="username"/>
				</div>
				<div>
					<label for="password">Your password</label>
					<input type="password" id="password" name="password"/>
					<input type="submit" value="Sign In" id="submit" />
				</div>
			</form>
		</div>
	</body>
</html>