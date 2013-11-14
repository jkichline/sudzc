using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Xml;
using System.Xml.Xsl;

using ICSharpCode.SharpZipLib.Zip;

namespace ConvertLib {
  /// <summary>
  /// Class used to convert WSDL files into generated Objective-C code.
  /// </summary>
  public class Converter {
    private string domain;
    private List<String> errors;
    private DirectoryInfo outputDirectory;
    private string password;
    private string username;
    private List<WsdlFile> wsdlFiles;
    private string wsdlPaths;

    /// <summary>
    /// The type of code to generate.
    /// </summary>
    public string Type { get; set; }

    /// <summary>
    /// The paths to the WSDL files.
    /// </summary>
    public string WsdlPaths {
      get {
        return wsdlPaths;
      }
      set {
        wsdlPaths = value;
        if (wsdlPaths == null || wsdlPaths.Contains("://")) {
          wsdlFiles = null;
        }
      }
    }

    /// <summary>
    /// The username used to authenticate the retrieval of WSDL files.
    /// </summary>
    public string Username {
      get {
        return username;
      }
      set {
        username = value;
      }
    }

    /// <summary>
    /// The password used to authenticate the retrieval of WSDL files.
    /// </summary>
    public string Password {
      get {
        return password;
      }
      set {
        password = value;
      }
    }

    /// <summary>
    /// The domain used to authenticate the retrieval of WSDL files.
    /// </summary>
    public string Domain {
      get {
        return domain;
      }
      set {
        domain = value;
      }
    }

    /// <summary>
    /// Returns a collection of errors encountered;
    /// </summary>
    public List<String> Errors {
      get {
        return errors;
      }
    }

    /// <summary>
    /// The output directory of the conversion process.
    /// </summary>
    public DirectoryInfo OutputDirectory {
      get {
        // Create the output directory if needed.
        if (outputDirectory == null) {
          string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".sudzd");
          outputDirectory = new DirectoryInfo(path);
          outputDirectory.Create();
        }
        return outputDirectory;
      }
      set {
        outputDirectory = value;
      }
    }

    /// <summary>
    /// The WSDL files to process.
    /// </summary>
    public List<WsdlFile> WsdlFiles {
      get {
        if (wsdlFiles == null && String.IsNullOrEmpty(wsdlPaths) == false) {
          try {
            wsdlFiles = WsdlFile.FromString(wsdlPaths, username, password, domain);
          } catch (Exception ex) {
            if (errors == null) {
              errors = new List<string>();
            }
            errors.Add(ex.Message);
          }
        }
        return wsdlFiles;
      }
      set {
        wsdlFiles = value;
      }
    }

    /// <summary>
    /// Creates and archive of the generated code.
    /// </summary>
    /// <returns>
    /// The <see cref="FileInfo" /> pointing to the created ZIP file.
    /// </returns>
    public FileInfo CreateArchive() {
      return CreateArchive(null);
    }

    /// <summary>
    /// Creates and archive of the generated code.
    /// </summary>
    /// <param name="context">
    /// The <see cref="HttpContext" /> used to pass the ZIP file to the response.
    /// </param>
    /// <returns>
    /// The <see cref="FileInfo" /> pointing to the created ZIP file.
    /// </returns>
    public FileInfo CreateArchive(HttpContext context) {
      return CreateArchive(context, null);
    }

    /// <summary>
    /// Creates and archive of the generated code.
    /// </summary>
    /// <param name="context">
    /// The <see cref="HttpContext" /> used to pass the ZIP file to the response.
    /// </param>
    /// <param name="packageName">The name of the package.</param>
    /// <returns>
    /// The <see cref="FileInfo" /> pointing to the created ZIP file.
    /// </returns>
    public FileInfo CreateArchive(HttpContext context, string packageName) {
      // Convert the WSDLs
      List<string> packages = Convert();
      if (String.IsNullOrEmpty(packageName) && packages != null && packages.Count > 0) {
        packageName = packages[0];
      }

      // Zip everything up
      string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".sudzc");
      var zipper = new FastZip();
      zipper.CreateZip(path, OutputDirectory.FullName, true, null);

      // Deliver the ZIP file to the browser
      if (context != null) {
        context.Response.ContentType = "application/zip";
        context.Response.AddHeader("content-disposition", "attachment;filename=\"" + packageName + ".zip\"");
        context.Response.WriteFile(path);
      }

      // Delete the output directory
      OutputDirectory.Delete(true);

      // Return the ZIP file
      return new FileInfo(path);
    }

    /// <summary>
    /// Removes old archives.
    /// </summary>
    /// <param name="olderThan">The time span used to determine which archives to be removed.</param>
    /// <returns>Returns the number of archives removed.</returns>
    public int RemoveArchives(TimeSpan olderThan) {
      int removed = 0;
      if (OutputDirectory.Parent != null) {
        foreach (FileInfo file in OutputDirectory.Parent.GetFiles("*.sudzc")) {
          if (DateTime.Now.Subtract(file.LastWriteTime).TotalMilliseconds > olderThan.TotalMilliseconds) {
            file.Delete();
            removed++;
          }
        }
        foreach (DirectoryInfo dir in OutputDirectory.Parent.GetDirectories("*.sudzd")) {
          dir.Delete(true);
        }
      }
      return removed;
    }

    /// <summary>
    /// Converts the WSDL files to generated code in the output directory.
    /// </summary>
    /// <returns>Returns a list of package names that were converted.</returns>
    public List<string> Convert() {
      List<string> packages;
      Convert(out packages);
      return packages;
    }

    /// <summary>
    /// Converts the WSDL files to generated code in the output directory.
    /// </summary>
    /// <param name="packages">Outputs the list of packages.</param>
    /// <returns>
    /// Returns the <see cref="DirectoryInfo" /> where the generated code is to be saved..
    /// </returns>
    public DirectoryInfo Convert(out List<string> packages) {
      List<string> classes;
      return Convert(out packages, out classes);
    }

    /// <summary>
    /// Converts the WSDL files to generated code in the output directory.
    /// </summary>
    /// <param name="packages">Outputs the list of packages.</param>
    /// <param name="classes">Outputs the list of classes.</param>
    /// <returns>
    /// Returns the <see cref="DirectoryInfo" /> where the generated code is to be saved..
    /// </returns>
    public DirectoryInfo Convert(out List<string> packages, out List<string> classes) {
      // Declare the packages array
      packages = new List<string>();
      classes = new List<string>();

      // Instantiate the WSDL directory
      var wsdlDirectory = new DirectoryInfo(Path.Combine(OutputDirectory.FullName, "WSDL"));
      if (wsdlDirectory.Exists == false) {
        wsdlDirectory.Create();
      }

      // Save each WSDL file
      foreach (WsdlFile wsdlFile in WsdlFiles) {
        wsdlFile.Document.Save(Path.Combine(wsdlDirectory.FullName, wsdlFile.Name + ".wsdl"));
      }

      // Save each package files
      foreach (XmlDocument package in ConvertToPackages()) {
        string packageName = SavePackageToDirectory(package, OutputDirectory);
        packages.Add(packageName);

        XmlNode classNode = package.SelectSingleNode("/package/@class");
        if (classNode != null) {
          classes.Add(classNode.Value);
        }
      }

      // Create the index XML document
      var indexDocument = new XmlDocument();
      XmlNode indexRoot = indexDocument.AppendChild(indexDocument.CreateElement("index"));
      foreach (string className in classes) {
        XmlNode classNode = indexRoot.AppendChild(indexDocument.CreateElement("class"));
        classNode.AppendChild(indexDocument.CreateTextNode(className));
      }

      // Process the index to the output directory.
      SaveIndexToDirectory(indexDocument, OutputDirectory);

      // Update the Xcode project file
      if (Type.StartsWith("ObjC")) {
        UpdateProjectFile(OutputDirectory);
      }

      // Return the output directory
      return OutputDirectory;
    }

    /// <summary>
    /// Converts all WSDL files to package XML documents.
    /// </summary>
    /// <returns>Returns a list of package XML documents.</returns>
    public List<XmlDocument> ConvertToPackages() {
      return WsdlFiles.Select(ConvertToPackage).ToList();
    }

    /// <summary>
    /// Converts the WSDL file to a package XML document.
    /// </summary>
    /// <param name="file">
    /// The <see cref="WsdlFile" /> to be converted.
    /// </param>
    /// <returns>Returns the package XML file.</returns>
    public XmlDocument ConvertToPackage(WsdlFile file) {
      errors = new List<string>();
      return Transform(file.Document);
    }

    /// <summary>
    /// Saves the index XML file to the directory.
    /// </summary>
    /// <param name="document">
    /// The index <see cref="XmlDocument" /> to be saved.
    /// </param>
    /// <param name="directory">
    /// The <see cref="DirectoryInfo" /> where the generated code is saved.
    /// </param>
    public void SaveIndexToDirectory(XmlDocument document, DirectoryInfo directory) {
      SavePackageToDirectory(Transform(document), directory);
    }

    /// <summary>
    /// Transforms the <see cref="XmlDocument" />.
    /// </summary>
    /// <param name="document">The document to be transformed.</param>
    /// <returns>
    /// Returns the resulting <see cref="XmlDocument" />.
    /// </returns>
    public XmlDocument Transform(XmlDocument document) {
      var xslt = new XslCompiledTransform();
      xslt.Load(HttpContext.Current.Server.MapPath(Type + ".xslt"));
      var args = new XsltArgumentList();
      foreach (string key in HttpContext.Current.Request.Params.AllKeys) {
        args.AddParam(key, String.Empty, HttpContext.Current.Request.Params[key]);
      }

      var ms = new MemoryStream();
      xslt.Transform(document, args, ms);
      var output = new XmlDocument();
      output.LoadXml(Encoding.ASCII.GetString(ms.ToArray()));
      return output;
    }

    /// <summary>
    /// Creates a UUID for generating PBX files.
    /// </summary>
    /// <param name="id">The ID to convert.</param>
    /// <returns>Returns the 24 character UUID.</returns>
    public static string MakeUUID(long id) {
      long code = DateTime.Now.Ticks;
      string uuid = id.ToString("X") + code.ToString("X");
      uuid = uuid.PadRight(24, '0');
      return uuid.Substring(0, 24);
    }

    /// <summary>
    /// Updates the project file with the new code files.
    /// </summary>
    /// <param name="directory">The directory containing the project files to update.</param>
    public void UpdateProjectFile(DirectoryInfo directory) {
      // Setup the string builders
      var pbxBuildFile = new StringBuilder();
      var pbxFileReference = new StringBuilder();
      var pbxGroupExamples = new StringBuilder();
      var pbxGroupGenerated = new StringBuilder();
      var pbxSourcesBuildPhase = new StringBuilder();
      var lookup = new Dictionary<string, string>();

      // Set up the ID
      var date1970 = new DateTime(1970, 1, 1);
      TimeSpan timeSpan = DateTime.Now.Subtract(date1970);
      var id = (long)timeSpan.TotalMilliseconds;

      // Create pointers to the directory
      var sourceDirectory = new DirectoryInfo(Path.Combine(directory.FullName, "Source"));
      var examplesDirectory = new DirectoryInfo(Path.Combine(sourceDirectory.FullName, "Examples"));
      var generatedDirectory = new DirectoryInfo(Path.Combine(sourceDirectory.FullName, "Generated"));

      // Add examples files
      foreach (FileInfo file in examplesDirectory.GetFiles()) {
        string uuid = MakeUUID(id);
        string type = "objc";
        if (file.Name.EndsWith(".h")) {
          type = "h";
        }
        pbxFileReference.AppendFormat(
          "        {0} /* {1} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.{2}; path = \"{1}\"; sourceTree = \"<group>\"; }};",
          uuid,
          file.Name,
          type);
        pbxFileReference.AppendLine();
        pbxGroupExamples.AppendFormat("                {0} /* {1} */,", uuid, file.Name);
        pbxGroupExamples.AppendLine();
        lookup.Add(file.Name, uuid);
        id++;
      }

      // Add generated files
      foreach (FileInfo file in generatedDirectory.GetFiles()) {
        string uuid = MakeUUID(id);
        string type = "objc";
        if (file.Name.EndsWith(".h")) {
          type = "h";
        }
        pbxFileReference.AppendFormat(
          "        {0} /* {1} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.{2}; path = \"{1}\"; sourceTree = \"<group>\"; }};",
          uuid,
          file.Name,
          type);
        pbxFileReference.AppendLine();
        pbxGroupGenerated.AppendFormat("                {0} /* {1} */,", uuid, file.Name);
        pbxGroupGenerated.AppendLine();
        lookup.Add(file.Name, uuid);
        id++;
      }

      // Add the build files
      foreach (string filename in lookup.Keys) {
        string uuid = MakeUUID(id);
        pbxBuildFile.AppendFormat("        {0} /* {1} in Sources */ = {{isa = PBXBuildFile; fileRef = {2} /* {1} */; }};", uuid, filename, lookup[filename]);
        pbxBuildFile.AppendLine();
        if (filename.EndsWith(".m")) {
          pbxSourcesBuildPhase.AppendFormat("                {0} /* {1} in Sources */,", uuid, filename);
          pbxSourcesBuildPhase.AppendLine();
        }
        id++;
      }

      // Update the variables in the file.
      var projectFile = new FileInfo(Path.Combine(directory.FullName, "Examples/SudzCExamples.xcodeproj/project.pbxproj"));
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
      var writer = new StreamWriter(projectFile.FullName, false);
      writer.Write(contents);
      writer.Flush();
      writer.Close();
    }

    /// <summary>
    /// Saves the package XML file to the directory.
    /// </summary>
    /// <param name="document">The <see cref="XmlDocument" /> to be saved.</param>
    /// <param name="directory">The <see cref="DirectoryInfo" /> where the generated code is saved.</param>
    /// <returns>Returns the name of the package that was generated.</returns>
    public string SavePackageToDirectory(XmlDocument document, DirectoryInfo directory) {
      // Get the package name to return
      string packageName;
      try {
        packageName = document.DocumentElement.Attributes["name"].Value;
      } catch (Exception ex) {
        throw new Exception("Required attribute 'name' not encountered in the 'package' element", ex);
      }

      if (document.DocumentElement == null) {
        return null;
      }

      // Review each child node and...
      foreach (XmlNode child in document.DocumentElement.ChildNodes) {
        string source;
        string target;
        switch (child.Name.ToLower()) {
            // If a folder is to be included, copy the whole folder
          case "folder":
            try {
              source = child.Attributes["copy"].Value;
            } catch (Exception ex) {
              throw new Exception("Required 'copy' attribute not encountered in the 'folder' element", ex);
            }
            var sourceDirectory = new DirectoryInfo(HttpContext.Current.Server.MapPath(source));
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
            var sourceFile = new FileInfo(HttpContext.Current.Server.MapPath(source));
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
            FileInfo file = new FileInfo(filePath);
            if (file.Directory != null && file.Directory.Exists == false) {
              file.Directory.Create();
            }

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
      var sourceDirectory = new DirectoryInfo(source);
      var destinationDirectory = new DirectoryInfo(destination);

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
          string newFile = Path.Combine(destinationDirectory.FullName, subFiles[i].Name);
          subFiles[i].CopyTo(newFile, overwrite);
        }
      }

      // Loop through the directories and call this function
      DirectoryInfo[] subDirectories = sourceDirectory.GetDirectories();
      for (int i = 0; i < subDirectories.Length; i++) {
        if ((subDirectories[i].Attributes & FileAttributes.Hidden) != FileAttributes.Hidden) {
          string newDirectory = Path.Combine(destinationDirectory.FullName, subDirectories[i].Name);
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
      if (String.IsNullOrEmpty(namespaceUri)) {
        return null;
      }
      if (namespaceUri.Contains("://")) {
        namespaceUri = namespaceUri.Substring(namespaceUri.IndexOf("://", StringComparison.Ordinal) + 3) + "?";
      }
      if (namespaceUri.Contains("?")) {
        namespaceUri = namespaceUri.Substring(0, namespaceUri.IndexOf("?", StringComparison.Ordinal));
      }

      var p1 = namespaceUri.Split(("/\\.:;").ToCharArray());
      var p2 = new string[p1.Length - 1];
      if (p2.Length > 0) {
        Array.Copy(p1, p2, p1.Length - 1);
        return String.Join("_", p2);
      }
      return String.Join("_", p1);
    }
  }
}