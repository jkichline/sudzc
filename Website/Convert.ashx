<%@ WebHandler Language="C#" Class="Convert" %>
using System;
using System.Collections.Generic;
using System.Web;
using System.Xml;
using System.Xml.Xsl;
using System.IO;
using System.Net;
using ICSharpCode.SharpZipLib.Zip;

public class Convert : IHttpHandler {
	private string type = null;
	private string mimeType = null;
	private string username = null;
	private string password = null;
	private string domain = null;
	private HttpContext context;
	
	public void ProcessRequest(HttpContext context) {
		// Set up process variables
		DirectoryInfo temp = null;
		string packageName = null;
		string lastPackageName = null;
		this.context = context;
		
		// Load authentication information
		username = context.Request["username"];
		password = context.Request["password"];
		domain = context.Request["domain"];
		
		/// Get the type of of transformation to perform
		this.type = context.Request["type"];
		if (this.type == null) { this.type = "ObjCFiles"; }
		
		// Get the mimetype
		this.mimeType = System.Configuration.ConfigurationManager.AppSettings["OutputMimetype"];

		// Get the WSDL values
		string wsdls = context.Request["wsdl"];
		if(String.IsNullOrEmpty(wsdls)) { return; }
		string[] wsdlList = wsdls.Split((";\n\t,|").ToCharArray());

		// If we only have one, let's see if it's a list
		if (wsdlList.Length == 1) {
			WebClient client = new WebClient();
			if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
				NetworkCredential credential = new NetworkCredential(username, password, domain);
				client.Credentials = credential;
			}
			string imports = null;
			try {
				imports = client.DownloadString(this.getAbsoluteUrl(context, wsdls));
			} catch (WebException ex) {
				this.displayError(context, ex.Message); return;
			}
			if (imports.Contains("<") == false) {
				wsdlList = imports.Split((";,\n\t|\r").ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
			}
		}
		
		// Process each WSDL in turn		
		foreach (string item in wsdlList) {
			
			// Resolve the WSDL
			string wsdl = this.getAbsoluteUrl(context, item);

			// Converts the WSDL to output
			XmlDocument wsdlDocument;
			string output = this.ConvertWsdlToXmlString(wsdl, out wsdlDocument);
		
			// See if the output is an XML document
			XmlDocument outputDoc = new XmlDocument();
			try {
				context.Response.ContentType = "text/xml";
				outputDoc.LoadXml(output);
			} catch (Exception) { }

			// If in test mode, output the XML
			if (String.IsNullOrEmpty(mimeType) == false) {
				context.Response.ContentType = mimeType;
				outputDoc.Save(context.Response.OutputStream);
				return;
			}

			// Otherwise create the package		
			if(this.IsPackage(outputDoc)) {

			// Create a temporary directory
				string tempPath = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
				string wsdlPath = null;
				if(temp == null) {
					temp = new DirectoryInfo(tempPath);
					temp.Create();
					wsdlPath = Path.Combine(tempPath, "WSDL");
					Directory.CreateDirectory(wsdlPath);
				}

				// Outputs the files into the temp directory
				lastPackageName = this.OutputFilesToDirectory(outputDoc, temp);
				
				// Output the WSDL to the temp directory
				string wsdlFilename = wsdl.Substring(wsdl.LastIndexOf("/") + 1);
				wsdlFilename = wsdlFilename.Substring(0, wsdlFilename.LastIndexOf("?"));
				wsdlFilename = wsdlFilename.Substring(0, wsdlFilename.LastIndexOf("."));
				wsdlDocument.Save(Path.Combine(wsdlPath, wsdlFilename + ".wsdl"));

			} else {
				// Get a string version of the output
				output = output.Replace("&gt;", ">").Replace("&lt;", "<").Replace("&amp;", "&");
				context.Response.ContentType = "text/plain";
				context.Response.Write(output);
			}
		}
			
		// If we have a temp directory, zip it and ship it
		if(temp != null) {
			
			// Get a decent package name
			packageName = lastPackageName;
			if (wsdlList.Length > 1) { packageName = this.GetPackageName(wsdls); }

			// Zip everything up
			string zipFileName = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
			FastZip zipper = new FastZip();
			zipper.CreateZip(zipFileName, temp.FullName, true, null);
			
			// Deliver the ZIP file to the browser
			context.Response.ContentType = "application/zip";
			context.Response.AddHeader("content-disposition", "attachment;filename=\""+ packageName +".zip\"");
			context.Response.WriteFile(zipFileName);
			
			// Delete the temp directory
			temp.Delete(true);
		}

		// Finish up
		context.Response.End();
	}

	public string OutputFilesToDirectory(XmlDocument document, DirectoryInfo directory) {
		// Setup working variables
		FileInfo file;
		string source, target, packageName;

		// Get the package name to return
		try {
			packageName = document.DocumentElement.Attributes["name"].Value;
		} catch (Exception ex) {
			throw new Exception("Required attribute 'name' not encountered in the 'package' element", ex);
		}

		// Review each child node and...
		foreach (XmlNode child in document.DocumentElement.ChildNodes) {
			switch (child.Name.ToLower()) {

				// If a folder is to be included, copy the whole folder
				case "folder":
					try {
						source = child.Attributes["copy"].Value;
					} catch (Exception ex) {
						throw new Exception("Required 'copy' attribute not encountered in the 'folder' element", ex);
					}
					DirectoryInfo sourceDirectory = new DirectoryInfo(context.Server.MapPath(source));
					if (sourceDirectory.Exists == false) {
						throw new Exception("The source folder '" + source + "' does not exist.");
					}
					target = sourceDirectory.Name;
					if (child.Attributes["as"] != null) {
						target = child.Attributes["as"].Value;
					}
					copyDirectory(sourceDirectory.FullName, Path.Combine(directory.FullName, target), true);
					break;

				// If an include, copy the file into the folder
				case "include":
					try {
						source = child.Attributes["copy"].Value;
					} catch (Exception ex) {
						throw new Exception("Required 'copy' attribute not encountered in the 'include' element", ex);
					}
					FileInfo sourceFile = new FileInfo(context.Server.MapPath(source));
					if (sourceFile.Exists == false) {
						throw new Exception("The source file '" + sourceFile + "' does not exist.");
					}
					target = sourceFile.Name;
					if (child.Attributes["as"] != null) {
						target = child.Attributes["as"].Value;
					}
					sourceFile.CopyTo(Path.Combine(directory.FullName, target), true);
					break;

				// If a file, write the contents into the folder
				case "file":
					string filename;
					try {
						filename = child.Attributes["filename"].Value;
					} catch (Exception ex) {
						throw new Exception("Required attribute 'filename' not encountered in the 'file' element", ex);
					}
					string filePath = Path.Combine(directory.FullName, filename);
					file = new FileInfo(filePath);
					if (file.Directory.Exists == false) { file.Directory.Create(); }
					StreamWriter fs = file.CreateText();
					fs.Write(child.InnerText);
					fs.Flush();
					fs.Close();
					break;
			}
		}
		return packageName;
	}

	public bool IsPackage(XmlDocument document) {
		return (document.DocumentElement != null && document.DocumentElement.Name == "package");
	}

	public string GetPackageName(string url) {
		url = url.Substring(url.IndexOf("://") + 3) + "?";
		url = url.Substring(0, url.IndexOf("?"));
		string[] p1 = url.Split(("/\\.:;").ToCharArray());
		string[] p2 = new string[p1.Length - 1];
		Array.Copy(p1, p2, p1.Length - 1);
		return String.Join("_", p2);
	}

	public string ConvertWsdlToXmlString(string wsdl) {
		XmlDocument wsdlDocument;
		return this.ConvertWsdlToXmlString(wsdl, out wsdlDocument);
	}

	public string ConvertWsdlToXmlString(string wsdl, out XmlDocument doc) {
		// Authentication parameters
		string username = context.Request["username"];
		string password = context.Request["password"];
		string domain = context.Request["domain"];
		
		// Create the document
		doc = new XmlDocument();
		
		// Set a resolver for authentication username and/or password
		if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
			XmlUrlResolver resolver = new XmlUrlResolver();
			NetworkCredential credential = new NetworkCredential(username, password, domain);
			resolver.Credentials = credential;
			doc.XmlResolver = resolver;
		}
		
		// Load up the WSDL from the URL

		try {
			doc.Load(wsdl);
		} catch (Exception) {
			try {
				doc.Load(wsdl + "?WSDL");
			} catch (Exception) {
				this.displayError(context, "The file specified was not a valid WSDL");
				return null;
			}
		}

		this.expandImports(doc);
		
		// If we only want to see the input then do only that
		if (this.mimeType == "input") {
			doc.Save(context.Response.OutputStream);
		}

		// Transform it all to a nice memory stream
		XslTransform xfrm = new XslTransform();
		xfrm.Load(context.Server.MapPath(this.type + ".xslt"));
		XsltArgumentList args = new XsltArgumentList();
		foreach (string key in context.Request.Params.AllKeys) {
			try {
				args.AddParam(key, String.Empty, context.Request.Params[key]);
			} catch (Exception) { }
		}

		// Output as a string
		MemoryStream ms = new MemoryStream();
		xfrm.Transform(doc, args, ms);
		return System.Text.Encoding.ASCII.GetString(ms.ToArray());
	}

	public bool IsReusable {
		get {
			return false;
		}
	}

	private List<string> importedUris = null;

	/// <summary>
	/// Expand imports
	/// </summary>
	/// <param name="doc">The document to expand imports into</param>
	private void expandImports(XmlDocument doc) {
		importedUris = new List<string>();
		this._expandImports(doc);
	}

	private void _expandImports(XmlDocument doc) {
		bool continueExpanding = false;
		XmlNamespaceManager nsmgr = new XmlNamespaceManager(doc.NameTable);
		nsmgr.AddNamespace("xsd", "http://www.w3.org/2001/XMLSchema");
		nsmgr.AddNamespace("wsdl", "http://schemas.xmlsoap.org/wsdl/");
		XmlNodeList schemaImports = doc.SelectNodes("//*/xsd:import", nsmgr); 
		XmlNodeList wsdlImports = doc.SelectNodes("//*/wsdl:import", nsmgr);
		
		// Expand the schema imports
		foreach (XmlNode importNode in schemaImports) {
			string location = importNode.Attributes["schemaLocation"].Value;
			if (location != null && importedUris.Contains(location) == false) {
				XmlDocument importedDoc = new XmlDocument();
				importedDoc.Load(location);
				foreach (XmlNode node in importedDoc.DocumentElement.ChildNodes) {
					XmlNode clonedNode = doc.ImportNode(node, true);
					importNode.ParentNode.InsertAfter(clonedNode, importNode);
					continueExpanding = true;
				}
				importNode.ParentNode.RemoveChild(importNode);
				importedUris.Add(location);
			}
		}

		// Expand the WSDL imports
		foreach (XmlNode importNode in wsdlImports) {
			string location = importNode.Attributes["location"].Value;
			if (location != null && importedUris.Contains(location) == false) {
				XmlDocument importedDoc = new XmlDocument();
				importedDoc.Load(location);
				foreach (XmlNode node in importedDoc.DocumentElement.ChildNodes) {
					XmlNode clonedNode = doc.ImportNode(node, true);
					importNode.ParentNode.InsertAfter(clonedNode, importNode);
					continueExpanding = true;
				}
				importNode.ParentNode.RemoveChild(importNode);
				importedUris.Add(location);
			}
		}
		
		// Recursively add nodes
		if (continueExpanding) {
			this._expandImports(doc);
		}
	}

	private void displayError(HttpContext context, string message) {
		context.Response.Redirect("Errors.aspx?message=" + message, true);
		return;
	}

	private string getAbsoluteUrl(HttpContext context, string url) {
		if (url.Contains("://")) { return url; }
		string svr = context.Request.Url.Scheme + "://" + context.Request.Url.Host;
		if (!context.Request.Url.IsDefaultPort) { svr += ":" + context.Request.Url.Port.ToString(); }
		return svr + url;
	}

	private void copyDirectory(String source, String destination, Boolean overwrite) {
		// Hold directory information
		DirectoryInfo sourceDirectory = new DirectoryInfo(source);
		DirectoryInfo destinationDirectory = new DirectoryInfo(destination);

		// Throw an error is the source directory does not exist
		if (sourceDirectory.Exists == false) {
			throw new DirectoryNotFoundException();
		}

		// Create the destination directory
		if (destinationDirectory.Exists == false) {
			destinationDirectory.Create();
		}

		// Loop through the files and copy them
		FileInfo[] subFiles = sourceDirectory.GetFiles();
		for (int i = 0; i < subFiles.Length; i++) {
			if ((subFiles[i].Attributes & FileAttributes.Hidden) != FileAttributes.Hidden) {
				string newFile = Path.Combine(
								destinationDirectory.FullName,
								subFiles[i].Name
				);
				subFiles[i].CopyTo(newFile, overwrite);
			}
		}

		// Loop through the directories and call this function
		DirectoryInfo[] subDirectories = sourceDirectory.GetDirectories();
		for (int i = 0; i < subDirectories.Length; i++) {
			if ((subDirectories[i].Attributes & FileAttributes.Hidden) != FileAttributes.Hidden) {
				string newDirectory = Path.Combine(
								destinationDirectory.FullName,
								subDirectories[i].Name
				);
				copyDirectory(subDirectories[i].FullName, newDirectory, overwrite);
			}
		}
	}

}