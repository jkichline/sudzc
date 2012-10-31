$(function() {
	$("#content").each(function(content){
		this.innerHTML=this.innerHTML.replace(/((NS(\w+))\s*\*)/g, "<a target=\"_blank\" href=\"http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/$2_Class/index.html\">$1</a>");
		this.innerHTML=this.innerHTML.replace(/((CXML(\w+))\s*\*)/g, "<a href=\"../framework/$2.html\">$1</a>");
	});
});