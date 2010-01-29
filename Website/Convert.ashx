<%@ WebHandler Language="C#" Class="Convert" %>
using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using System.Xml;
using System.Xml.Xsl;
using System.IO;
using System.Net;
using ICSharpCode.SharpZipLib.Zip;

public class Convert : IHttpHandler {

	public void ProcessRequest(HttpContext context) {

		// Setup Variables
		string packageName = context.Request["shortns"];
		if (String.IsNullOrEmpty(packageName)) { packageName = context.Request["ns"]; }
		string mimeType = System.Configuration.ConfigurationManager.AppSettings["OutputMimetype"];

		// Set up the converter object
		Converter converter = new Converter();
		converter.Username = context.Request["username"];
		converter.Password = context.Request["password"];
		converter.Domain = context.Request["domain"];
		converter.Type = (String.IsNullOrEmpty(context.Request["type"])) ? "ObjCFiles" : context.Request["type"];


		// Add the WSDLs to the converter
		if (context.Request.Files != null && context.Request.Files.Count > 0 && context.Request.Files[0] != null && context.Request.Files[0].ContentLength > 0) {
			converter.WsdlFiles = new List<WsdlFile>();

			foreach (object item in context.Request.Files) {
				HttpPostedFile postedFile = item as HttpPostedFile;
				if (postedFile == null) { postedFile = context.Request.Files[item as string]; }
				if (postedFile != null && postedFile.ContentLength > 0) {
					WsdlFile wsdlFile = new WsdlFile();
					wsdlFile.Document = new XmlDocument();
					wsdlFile.Document.Load(postedFile.InputStream);
					wsdlFile.Path = postedFile.FileName;
					XmlDocument wsdlDocument = new XmlDocument();
					converter.WsdlFiles.Add(wsdlFile);
				}
			}
		} else {
			try {
				converter.WsdlPaths = context.Request["wsdl"];
			} catch (Exception ex) {
				string error = ex.Message;
				if (converter.Errors != null) { error += ": " + String.Join(", ", converter.Errors.ToArray()); }
				this.displayError(context, error);
				return;
			}
		}
		
		// If we have no WSDL, just stop now
		if (converter.WsdlFiles == null || converter.WsdlFiles.Count == 0) {
			this.displayError(context, "No WSDL files have been specified");
		}

		// Just output the WSDL if that is what is requested
		if (mimeType == "input" && converter.WsdlFiles.Count > 0) {
			context.Response.ContentType = "text/xml";
			context.Response.AddHeader("content-disposition", "attachment;filename=\"" + converter.WsdlFiles[0].Name + ".wsdl\"");
			converter.WsdlFiles[0].Document.Save(context.Response.OutputStream);
			context.Response.End();
			return;
		}

		// If we want to see text then return that
		if (String.IsNullOrEmpty(mimeType) == false) {
			context.Response.ContentType = "text/plain";
			context.Response.AddHeader("content-disposition", "attachment;filename=\"" + converter.WsdlFiles[0].Name + ".sudzc\"");
			converter.ConvertToPackage(converter.WsdlFiles[0]).Save(context.Response.OutputStream);
			context.Response.End();
			return;
		}

		// Otherwise, save it as an archive
		try {
			converter.CreateArchive(context);
		} catch (Exception ex) {
			this.displayError(context, ex.Message);
		}
	}

	private void displayError(HttpContext context, string message) {
		context.Response.Redirect("Errors.aspx?message=" + message, true);
		return;
	}

	public bool IsReusable {
		get { return true; }
	}

}