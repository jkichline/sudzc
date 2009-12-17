<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head runat="server">
		<title>SudzC (alpha) | clean source code from your web services</title>
		<link rel="stylesheet" href="assets/styles/default.css" type="text/css" />
		<script type="text/javascript">
			var customNamespace=false;
			function $(id){
				return document.getElementById(id);
			}
			function init(){
				adjustNS($("type"));
				var el=$("wsdl");
				el.focus();
			}
			function adjustNS(el){
				var opt=el.options[el.selectedIndex];
				var useShort=(opt.value.substring(0,4)=="ObjC");
				$("ns").style.display=useShort?"none":"block";
				$("objcns").style.display=useShort?"block":"none";
			}
			function makeNs(){
				if(customNamespace){return;}
				var url=$("wsdl").value;
				var at=url.indexOf("://");
				if(at<1){return;}
				url=url.substring(at+3);
				var a=url.split("/");
				if(a.length<1){return;}
				var ns="";
				var b=a[0].split(".");
				for(var i=b.length-1;i>=0;i--){
					if(b[i]=="www"){continue;}
					if(ns!=""){ns+=".";}
					ns+=b[i];
				}
				for(var i=1;i<a.length-1;i++){
					ns+="."+a[i];
				}
				$("ns").value=ns;
			}
			function doAuthentication(){
				var a=$("authentication");
				if(a.style.display=="block") {
					$("username").value="";
					$("password").value="";
					$("authIcon").src=$("authIcon").src.replace("locked","unlocked");
					a.style.display="none";
				} else {
					$("authIcon").src=$("authIcon").src.replace("unlocked","locked");
					a.style.display="block";
					$("username").focus();
				}
			}
		</script>
	</head>
	<body onload="init();">
		<div id="content">
			<a href="~/" runat="server"><img src="assets/images/logo.png" alt="Sudzc" id="logo" /></a>
			<form action="Convert.ashx" method="post" id="form">
				<div>
					<label for="wsdl">Type the web address of the WSDL to convert</label>
					<input type="text" id="wsdl" name="wsdl" value="http://" onblur="makeNs();" />
					<img id="authIcon" src="assets/images/unlocked.png" width="26" height="26" border="0" onclick="doAuthentication();" title="Click to provide authentication information" />
				</div>
				<div id="authentication">
					<div>
						<label for="username">Username</label>
						<input type="text" id="username" name="username" />
					</div>
					<div>
						<label for="password">Password</label>
						<input type="password" id="password" name="password" />
					</div>
				</div>
				<div>
					<label for="ns">Pick a namespace for the generated code</label>
					<div id="objcns"><input type="text" id="shortns" name="shortns" value="SDZ"/>ensures unique class definitions (recommended)</div>
					<input type="text" id="ns" name="ns" value="" onfocus="customNamespace=true;" />
				</div>
				<div>
					<label for="type">Choose the type of code bundle to create</label>
					<select id="type" name="type" onchange="adjustNS(this);">
						<option value="ObjCFiles">Objective-C for iPhone - Multiple Files (alpha)</option>
						<option value="ObjC">Objective-C for iPhone - Single File (alpha)</option>
						<option value="Javascript">Javascript for web development (alpha)</option>
						<option value="ActionScript">ActionScript for Flash/Flex (alpha)</option>
					</select>
					<input type="image" src="assets/images/generate-button.png" value="Generate" id="submit" />
				</div>
			</form>
		</div>
	</body>
</html>