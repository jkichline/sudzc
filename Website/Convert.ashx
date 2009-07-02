<%@ WebHandler Language="C#" Class="Convert" %>
using System;
using System.Web;
using System.Xml;
using System.Xml.Xsl;
using System.IO;
using ICSharpCode.SharpZipLib.Zip;

public class Convert : IHttpHandler {

	public void ProcessRequest(HttpContext context) {
		
		/// Get the type of of transformation to perform
		string type = context.Request["type"];
		if (type == null) { type = "JavaScript"; }

		// Get the WSDL value
		string wsdl = context.Request["wsdl"];
		wsdl = this.getAbsoluteUrl(context, wsdl);

		// Get the mimetype
		string mimeType = System.Configuration.ConfigurationManager.AppSettings["OutputMimetype"];
		
		// Load up the WSDL from the URL
		XmlDocument doc = new XmlDocument();

		try {
			doc.Load(wsdl);
		} catch (Exception) {
			try {
				doc.Load(wsdl + "?WSDL");
			} catch (Exception) {
				this.displayError(context, "The file specified was not a valid WSDL");
				return; 
			}
		}
		
		MemoryStream ms;
		
		// Expand the imports
		ms = new MemoryStream();
		XslTransform expander = new XslTransform();
		expander.Load(context.Server.MapPath("ExpandImports.xslt"));
		expander.Transform(doc, null, ms);
		string input = System.Text.Encoding.ASCII.GetString(ms.ToArray());

		// See if the input is an XML document
		XmlDocument inputDoc = new XmlDocument();
		try {
			context.Response.ContentType = "text/xml";
			inputDoc.LoadXml(input);
		} catch (Exception) { }

		// If we only want to see the input then do only that
		if (mimeType == "input") {
			inputDoc.Save(context.Response.OutputStream);
		}
		
		// Transform it all to a nice memory stream
		XslTransform xfrm = new XslTransform();
		xfrm.Load(context.Server.MapPath(type + ".xslt"));
		XsltArgumentList args = new XsltArgumentList();
		foreach(string key in context.Request.Params.AllKeys) {
			try {
				args.AddParam(key, String.Empty, context.Request.Params[key]);
			} catch (Exception) { }
		}
		
		//
		ms = new MemoryStream();
		xfrm.Transform(inputDoc, args, ms);
		string output = System.Text.Encoding.ASCII.GetString(ms.ToArray());
		
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
		if (outputDoc.DocumentElement != null && outputDoc.DocumentElement.Name == "package") {

			// Create a temporary directory
			DirectoryInfo temp = new DirectoryInfo(Path.Combine(Path.GetTempPath(), Path.GetRandomFileName()));
			temp.Create();

			// Review each child node and...
			FileInfo file;
			string source, target;

			foreach (XmlNode child in outputDoc.DocumentElement.ChildNodes) {
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
						copyDirectory(sourceDirectory.FullName, Path.Combine(temp.FullName, target), true);
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
						sourceFile.CopyTo(Path.Combine(temp.FullName, target));
						break;
						
					// If a file, write the contents into the folder
					case "file":
						string filename;
						try {
							filename = child.Attributes["filename"].Value;
						} catch (Exception ex) {
							throw new Exception("Required attribute 'filename' not encountered in the 'file' element", ex);
						}
						string filePath = Path.Combine(temp.FullName, filename);
						file = new FileInfo(filePath);
						if (file.Directory.Exists == false) { file.Directory.Create(); }
						StreamWriter fs = file.CreateText();
						fs.Write(child.InnerText);
						fs.Flush();
						fs.Close();
						break;
				}
			}
			
			// Zip everything up
			string packageName;
			try {
				packageName = outputDoc.DocumentElement.Attributes["name"].Value;
			} catch (Exception ex) {
				throw new Exception("Required attribute 'name' not encountered in the 'package' element", ex);
			}
			string zipFileName = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
			FastZip zipper = new FastZip();
			zipper.CreateZip(zipFileName, temp.FullName, true, null);
			
			// Deliver the ZIP file to the browser
			context.Response.ContentType = "application/zip";
			context.Response.AddHeader("content-disposition", "attachment;filename=\""+ packageName +".zip\"");
			context.Response.WriteFile(zipFileName);
			
			// Delete the temp directory
			temp.Delete(true);
			context.Response.End();

		// Otherwise we will process this normally
		} else {

			// Get a string version of the output
			output = output.Replace("&gt;", ">").Replace("&lt;", "<").Replace("&amp;", "&");
			context.Response.ContentType = "text/plain";
			context.Response.Write(output);
			context.Response.End();
		}
	}

	public bool IsReusable {
		get {
			return false;
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