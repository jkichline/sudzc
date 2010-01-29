using System;
using System.Data;
using System.Configuration;
using System.Collections.Generic;
using System.Web;
using System.Web.Security;
using System.Xml;
using System.Xml.Xsl;
using System.IO;
using System.Net;
using System.Text;
using ICSharpCode.SharpZipLib.Zip;

/// <summary>
/// Summary description for Converter
/// </summary>
public class Converter {
	private string type;
	private string wsdlPaths;
	private string username;
	private string password;
	private string domain;
	private List<String> errors;
	private DirectoryInfo outputDirectory;
	private List<WsdlFile> wsdlFiles;

	/// <summary>
	/// The type of code to generate.
	/// </summary>
	public string Type {
		get { return type; }
		set { type = value; }
	}

	/// <summary>
	/// The paths to the WSDL files.
	/// </summary>
	public string WsdlPaths {
		get { return wsdlPaths; }
		set {
			wsdlPaths = value;
			if (wsdlPaths == null || wsdlPaths.Contains("://")) {
				wsdlFiles = null;
			}
		}
	}

	/// <summary>
	/// The username used to authenticate the retrival of WSDL files.
	/// </summary>
	public string Username {
		get { return username; }
		set { username = value; }
	}

	/// <summary>
	/// The password used to authenticate the retrival of WSDL files.
	/// </summary>
	public string Password {
		get { return password; }
		set { password = value; }
	}

	/// <summary>
	/// The domain used to authenticate the retrival of WSDL files.
	/// </summary>
	public string Domain {
		get { return domain; }
		set { domain = value; }
	}

	/// <summary>
	/// Returns a collection of errors encountered;
	/// </summary>
	public List<String> Errors {
		get { return errors; }
	}

	/// <summary>
	/// The output directory of the conversion process.
	/// </summary>
	public DirectoryInfo OutputDirectory {
		get {
			// Create the output directory if needed.
			if (outputDirectory == null) {
				string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
				outputDirectory = new DirectoryInfo(path);
				outputDirectory.Create();
			}
			return outputDirectory; 
		}
		set { outputDirectory = value; }
	}

	/// <summary>
	/// The WSDL files to process.
	/// </summary>
	public List<WsdlFile> WsdlFiles {
		get {
			if (wsdlFiles == null && String.IsNullOrEmpty(wsdlPaths) == false) {
//				try {
					wsdlFiles = WsdlFile.FromString(this.wsdlPaths, this.username, this.password, this.domain);
//				} catch (Exception ex) {
//					if (errors == null) { errors = new List<string>(); }
//					errors.Add(ex.Message);
//				}
			}
			return wsdlFiles;
		}
		set { wsdlFiles = value; }
	}

	public Converter() {
		
	}

	/// <summary>
	/// Creates and archive of the generated code.
	/// </summary>
	/// <returns>The <see cref="FileInfo"/> pointing to the created ZIP file.</returns>
	public FileInfo CreateArchive() {
		return this.CreateArchive(null);
	}

	/// <summary>
	/// Creates and archive of the generated code.
	/// </summary>
	/// <param name="context">The <see cref="HttpContext"/> used to pass the ZIP file to the response.</param>
	/// <returns>The <see cref="FileInfo"/> pointing to the created ZIP file.</returns>
	public FileInfo CreateArchive(HttpContext context) {
		return this.CreateArchive(context, null);
	}

	/// <summary>
	/// Creates and archive of the generated code.
	/// </summary>
	/// <param name="context">The <see cref="HttpContext"/> used to pass the ZIP file to the response.</param>
	/// <param name="packageName">The name of the package.</param>
	/// <returns>The <see cref="FileInfo"/> pointing to the created ZIP file.</returns>
	public FileInfo CreateArchive(HttpContext context, string packageName) {

		// Convert the WSDLs
		List<string> packages = this.Convert();
		if (String.IsNullOrEmpty(packageName) && packages != null && packages.Count > 0) {
			packageName = packages[0];
		}

		// Zip everything up
		string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
		FastZip zipper = new FastZip();
		zipper.CreateZip(path, this.OutputDirectory.FullName, true, null);

		// Deliver the ZIP file to the browser
		if(context != null) {
			context.Response.ContentType = "application/zip";
			context.Response.AddHeader("content-disposition", "attachment;filename=\"" + packageName + ".zip\"");
			context.Response.WriteFile(path);
		}

		// Delete the output directory
		this.OutputDirectory.Delete(true);

		// Return the ZIP file
		return new FileInfo(path);
	}

	/// <summary>
	/// Converts the WSDL files to generated code in the output directory.
	/// </summary>
	/// <returns>Returns a list of package names that were converted.</returns>
	public List<string> Convert() {
		List<string> packages = null;
		this.Convert(out packages);
		return packages;
	}

	/// <summary>
	/// Converts the WSDL files to generated code in the output directory.
	/// </summary>
	/// <param name="packages">Outputs the list of packages.</param>
	/// <returns>Returns the <see cref="DirectoryInfo"/> where the generated code is to be saved..</returns>
	public DirectoryInfo Convert(out List<string> packages) {
		List<string> classes = null;
		return this.Convert(out packages, out classes);
	}

	/// <summary>
	/// Converts the WSDL files to generated code in the output directory.
	/// </summary>
	/// <param name="packages">Outputs the list of packages.</param>
	/// <param name="classes">Outputs the list of classes.</param>
	/// <returns>Returns the <see cref="DirectoryInfo"/> where the generated code is to be saved..</returns>
	public DirectoryInfo Convert(out List<string> packages, out List<string> classes) {

		// Declare the packages array
		packages = new List<string>();
		classes = new List<string>();

		// Instantiate the WSDL directory
		DirectoryInfo wsdlDirectory = new DirectoryInfo(Path.Combine(this.OutputDirectory.FullName, "WSDL"));
		if (wsdlDirectory.Exists == false) {
			wsdlDirectory.Create();
		}

		// Save each WSDL file
		foreach (WsdlFile wsdlFile in this.WsdlFiles) {
			wsdlFile.Document.Save(Path.Combine(wsdlDirectory.FullName, wsdlFile.Name + ".wsdl"));
		}

		// Save each package files
		foreach (XmlDocument package in this.ConvertToPackages()) {
			string packageName = this.SavePackageToDirectory(package, this.OutputDirectory);
			packages.Add(packageName);

			XmlNode classNode = package.SelectSingleNode("/package/@class");
			if (classNode != null) {
				classes.Add(classNode.Value);
			}
		}

		// Create the index XML document
		XmlDocument indexDocument = new XmlDocument();
		XmlNode indexRoot = indexDocument.AppendChild(indexDocument.CreateElement("index"));
		foreach (string className in classes) {
			XmlNode classNode = indexRoot.AppendChild(indexDocument.CreateElement("class"));
			classNode.AppendChild(indexDocument.CreateTextNode(className));
		}

		// Process the index to the output directory.
		this.SaveIndexToDirectory(indexDocument, this.OutputDirectory);

		// Update the Xcode project file
		this.UpdateProjectFile(this.OutputDirectory);

		// Return the output directory
		return this.OutputDirectory;
	}

	/// <summary>
	/// Converts all WSDL files to package XML documents.
	/// </summary>
	/// <returns>Returns a list of package XML documents.</returns>
	public List<XmlDocument> ConvertToPackages() {
		List<XmlDocument> list = new List<XmlDocument>();
		foreach (WsdlFile file in this.WsdlFiles) {
			list.Add(this.ConvertToPackage(file));
		}
		return list;
	}

	/// <summary>
	/// Converts the WSDL file to a package XML document.
	/// </summary>
	/// <param name="file">The <see cref="WsdlFile"/> to be converted.</param>
	/// <returns>Returns the package XML file.</returns>
	public XmlDocument ConvertToPackage(WsdlFile file) {
		errors = new List<string>();
		return this.Transform(file.Document);
	}

	/// <summary>
	/// Saves the index XML file to the directory.
	/// </summary>
	/// <param name="document">The index <see cref="XmlDocument"/> to be saved.</param>
	/// <param name="directory">The <see cref="DirectoryInfo"/> where the generated code is saved.</param>
	public void SaveIndexToDirectory(XmlDocument document, DirectoryInfo directory) {
		this.SavePackageToDirectory(this.Transform(document), directory);
	}

	/// <summary>
	/// Transforms the <see cref="XmlDocument"/>.
	/// </summary>
	/// <param name="document">The document to be transformed.</param>
	/// <returns>Returns the resulting <see cref="XmlDocument"/>.</returns>
	public XmlDocument Transform(XmlDocument document) {
		XslTransform xslt = new XslTransform();
		xslt.Load(HttpContext.Current.Server.MapPath(this.Type + ".xslt"));
		XsltArgumentList args = new XsltArgumentList();
		foreach (string key in HttpContext.Current.Request.Params.AllKeys) {
			try {
				args.AddParam(key, String.Empty, HttpContext.Current.Request.Params[key]);
			} catch (Exception ex) { }
		}

		MemoryStream ms = new MemoryStream();
		xslt.Transform(document, args, ms);
		XmlDocument output = new XmlDocument();
		output.LoadXml(System.Text.Encoding.ASCII.GetString(ms.ToArray()));
		return output;
	}

	public static string MakeUUID(long id) {
		long code = DateTime.Now.Ticks;
		string uuid = id.ToString("X") + code.ToString("X");
		uuid = uuid.PadRight(24, '0');
		return uuid.Substring(0, 24);
	}

	public void UpdateProjectFile(DirectoryInfo directory) {

		// Setup the string builders
		StringBuilder pbxBuildFile = new StringBuilder();
		StringBuilder pbxFileReference = new StringBuilder();
		StringBuilder pbxGroupExamples = new StringBuilder();
		StringBuilder pbxGroupGenerated = new StringBuilder();
		StringBuilder pbxSourcesBuildPhase = new StringBuilder();
		Dictionary<string, string> lookup = new Dictionary<string, string>();

		// Set up the ID
		DateTime date1970 = new DateTime(1970, 1, 1);
		TimeSpan timeSpan = DateTime.Now.Subtract(date1970);
		long id = (long)timeSpan.TotalMilliseconds;

		// Create pointers to the directory
		DirectoryInfo sourceDirectory = new DirectoryInfo(Path.Combine(directory.FullName, "Source"));
		DirectoryInfo examplesDirectory = new DirectoryInfo(Path.Combine(sourceDirectory.FullName, "Examples"));
		DirectoryInfo generatedDirectory = new DirectoryInfo(Path.Combine(sourceDirectory.FullName, "Generated"));
		
		// Add examples files
		foreach (FileInfo file in examplesDirectory.GetFiles()) {
			string uuid = MakeUUID(id);
			string type = "objc";
			if (file.Name.EndsWith(".h")) { type = "h"; }
			pbxFileReference.AppendFormat("		{0} /* {1} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.{2}; path = \"{1}\"; sourceTree = \"<group>\"; }};", uuid, file.Name, type);
			pbxFileReference.AppendLine();
			pbxGroupExamples.AppendFormat("				{0} /* {1} */,", uuid, file.Name);
			pbxGroupExamples.AppendLine();
			lookup.Add(file.Name, uuid);
			id++;
		}

		// Add generated files
		foreach (FileInfo file in generatedDirectory.GetFiles()) {
			string uuid = MakeUUID(id);
			string type = "objc";
			if (file.Name.EndsWith(".h")) { type = "h"; }
			pbxFileReference.AppendFormat("		{0} /* {1} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.{2}; path = \"{1}\"; sourceTree = \"<group>\"; }};", uuid, file.Name, type);
			pbxFileReference.AppendLine();
			pbxGroupGenerated.AppendFormat("				{0} /* {1} */,", uuid, file.Name);
			pbxGroupGenerated.AppendLine();
			lookup.Add(file.Name, uuid);
			id++;
		}

		// Add the build files
		foreach (string filename in lookup.Keys) {
			string uuid = MakeUUID(id);
			pbxBuildFile.AppendFormat("		{0} /* {1} in Sources */ = {{isa = PBXBuildFile; fileRef = {2} /* {1} */; }};", uuid, filename, lookup[filename]);
			pbxBuildFile.AppendLine();
			if (filename.EndsWith(".m")) {
				pbxSourcesBuildPhase.AppendFormat("				{0} /* {1} in Sources */,", uuid, filename);
				pbxSourcesBuildPhase.AppendLine();
			}
			id++;
		}

		// Update the variables in the file.
		FileInfo projectFile = new FileInfo(Path.Combine(directory.FullName, "Examples/SudzCExamples.xcodeproj/project.pbxproj"));
		StreamReader reader = projectFile.OpenText();
		string contents = reader.ReadToEnd();
		reader.Close();

		// Do the replacing
		contents = contents.Replace("/***PBXBuildFile***/", pbxBuildFile.ToString());
		contents = contents.Replace("/***PBXFileReference***/", pbxFileReference.ToString());
		contents = contents.Replace("/***PBXGroupExamples***/", pbxGroupExamples.ToString());
		contents = contents.Replace("/***PBXGroupGenerated***/", pbxGroupGenerated.ToString());
		contents = contents.Replace("/***PBXSourcesBuildPhase***/", pbxSourcesBuildPhase.ToString());
		
		// Save the file
		StreamWriter writer = new StreamWriter(projectFile.FullName, false);
		writer.Write(contents);
		writer.Flush();
		writer.Close();
	}

	/// <summary>
	/// Saves the package XML file to the directory.
	/// </summary>
	/// <param name="document">The <see cref="XmlDocument"/> to be saved.</param>
	/// <param name="directory">The <see cref="DirectoryInfo"/> where the generated code is saved.</param>
	/// <returns>Returns the name of the package that was generated.</returns>
	public string SavePackageToDirectory(XmlDocument document, DirectoryInfo directory) {

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
					DirectoryInfo sourceDirectory = new DirectoryInfo(HttpContext.Current.Server.MapPath(source));
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
					FileInfo sourceFile = new FileInfo(HttpContext.Current.Server.MapPath(source));
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

					if (child.FirstChild != null && child.FirstChild.NodeType == XmlNodeType.Element) {
						fs.Write(child.InnerXml);
					} else {
						fs.Write(child.InnerText);
					}
					fs.Flush();
					fs.Close();
					break;
			}
		}
		return packageName;
	}

	/// <summary>
	/// Copies one directory to another.
	/// </summary>
	/// <param name="source">The source directory.</param>
	/// <param name="destination">The destination directory.</param>
	/// <param name="overwrite">Determines if the destination directory is overwritten.</param>
	private static void copyDirectory(String source, String destination, Boolean overwrite) {
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

	/// <summary>
	/// Generates a package name.
	/// </summary>
	/// <param name="packages">The list of packages used to generate the name.</param>
	/// <returns>Returns a package name.</returns>
	public static string GetPackageName(List<string> packages) {
		return String.Join("_", packages.ToArray());
	}

	/// <summary>
	/// Generates a package name.
	/// </summary>
	/// <param name="namespaceUri">The URI of the namespace used to generate the name.</param>
	/// <returns>Returns a package name.</returns>
	public static string GetPackageName(string namespaceUri) {
		if (String.IsNullOrEmpty(namespaceUri)) { return null; }
		if (namespaceUri.Contains("://")) {
			namespaceUri = namespaceUri.Substring(namespaceUri.IndexOf("://") + 3) + "?";
		}
		if (namespaceUri.Contains("?")) {
			namespaceUri = namespaceUri.Substring(0, namespaceUri.IndexOf("?"));
		}
		string[] p1 = namespaceUri.Split(("/\\.:;").ToCharArray());
		string[] p2 = new string[p1.Length - 1];
		if (p2.Length > 0) {
			Array.Copy(p1, p2, p1.Length - 1);
			return String.Join("_", p2);
		} else {
			return String.Join("_", p1);
		}
	}

}

public class WsdlFile {
	internal string path;
	internal string name;
	internal XmlDocument document;

	public string Path {
		get { return path; }
		set { path = value; }
	}

	public string Name {
		get {
			if (String.IsNullOrEmpty(name) && String.IsNullOrEmpty(path) == false) {
				// Create the name
				name = path;
				if (name.Contains("/")) {
					name = name.Substring(name.LastIndexOf("/") + 1);
				}
				if (name.Contains("?")) {
					name = name.Substring(0, name.LastIndexOf("?"));
				}
				if (name.Contains(".")) {
					name = name.Substring(0, name.LastIndexOf("."));
				}
			}
			return name;
		}
		set { name = value; }
	}

	public XmlDocument Document {
		get { return document; }
		set { document = value; }
	}

	public static List<WsdlFile> FromString(string value) {
		return FromString(value, null, null);
	}

	public static List<WsdlFile> FromString(string value, string username, string password) {
		return FromString(value, username, password, null);
	}

	public static List<WsdlFile> FromString(string value, string username, string password, string domain) {
		List<WsdlFile> list = new List<WsdlFile>();
		foreach (string item in value.Split((";\n\t,|").ToCharArray())) {
			string path = item;
			path = path.Trim((" \r\n\t").ToCharArray());
			if (String.IsNullOrEmpty(path)) { continue; }
			XmlDocument wsdlDocument = GetXmlDocumentFromUrl(path, username, password, domain);
			if (wsdlDocument == null || wsdlDocument.DocumentElement.Name.Contains("definitions") == false) {
				path = path + "?WSDL";
				wsdlDocument = GetXmlDocumentFromUrl(path, username, password, domain);
			}
			string imports = null;
			if (wsdlDocument == null || wsdlDocument.DocumentElement.Name.Contains("definitions") == false) {
				wsdlDocument = null;
				imports = GetStringFromUrl(item, username, password, domain);
			}
			if (String.IsNullOrEmpty(imports) == false) {
				foreach (WsdlFile file in FromString(imports, username, password, domain)) {
					list.Add(file);
				}
			} else {
				if(wsdlDocument != null) {
					WsdlFile file = new WsdlFile();
					file.Path = path;
					file.Document = wsdlDocument;
					ExpandImports(file.Document);
					list.Add(file);
				}
			}
		}
		return list;
	}

	public static string GetStringFromUrl(string path, string username, string password, string domain) {
		WebClient client = new WebClient();
		if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
			NetworkCredential credential = new NetworkCredential(username, password, domain);
			client.Credentials = credential;
		}
		path = GetAbsoluteUrl(path);
		string data = null;
		try {
			data = client.DownloadString(path);
		} catch (WebException ex) {
			throw ex;
		}
		return data;
	}

	public static XmlDocument GetXmlDocumentFromUrl(string path, string username, string password, string domain) {
		XmlDocument doc = new XmlDocument();
		XmlUrlResolver resolver = new XmlUrlResolver();
		if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
			NetworkCredential credential = new NetworkCredential(username, password, domain);
			resolver.Credentials = credential;
		}
		doc.XmlResolver = resolver;
		try {
			doc.Load(GetAbsoluteUrl(path));
		} catch (Exception ex) {
			return null;
		}
		return doc;
	}

	/// <summary>
	/// Expand imports
	/// </summary>
	/// <param name="doc">The document to expand imports into</param>
	private static List<string> importedUris = null;
	public static void ExpandImports(XmlDocument doc) {
		importedUris = new List<string>();
		expandImports(doc);
	}

	private static void expandImports(XmlDocument doc) {
		bool continueExpanding = false;
		XmlNamespaceManager nsmgr = new XmlNamespaceManager(doc.NameTable);
		nsmgr.AddNamespace("xsd", "http://www.w3.org/2001/XMLSchema");
		nsmgr.AddNamespace("wsdl", "http://schemas.xmlsoap.org/wsdl/");
		XmlNodeList schemaImports = doc.SelectNodes("//*/xsd:import", nsmgr);
		XmlNodeList wsdlImports = doc.SelectNodes("//*/wsdl:import", nsmgr);

		// Expand the schema imports
		foreach (XmlNode importNode in schemaImports) {
			XmlAttribute a = importNode.Attributes["schemaLocation"];
			if (a == null) { continue; }
			string location = a.Value;
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
			XmlAttribute a = importNode.Attributes["location"];
			if (a == null) { continue; }
			string location = a.Value;
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
			expandImports(doc);
		}
	}

	public static string GetAbsoluteUrl(string url) {
		HttpContext context = HttpContext.Current;
		if (url.Contains("://")) { return url; }
		string svr = context.Request.Url.Scheme + "://" + context.Request.Url.Host;
		if (!context.Request.Url.IsDefaultPort) { svr += ":" + context.Request.Url.Port.ToString(); }
		return svr + url;
	}
}