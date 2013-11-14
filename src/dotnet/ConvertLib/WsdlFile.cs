using System;
using System.Collections.Generic;
using System.Net;
using System.Web;
using System.Xml;

namespace ConvertLib {
  /// <summary>
  /// Defines a WSDL file to be processed.
  /// </summary>
  public class WsdlFile {
    /// <summary>
    /// Expand imports
    /// </summary>
    private static List<string> importedUris;

    /// <summary>
    /// The XML representation of the file.
    /// </summary>
    internal XmlDocument document;

    /// <summary>
    /// The name of the file.
    /// </summary>
    internal string name;

    /// <summary>
    /// The path to the file.
    /// </summary>
    internal string path;

    /// <summary>
    /// The path to the file.
    /// </summary>
    public string Path {
      get {
        return path;
      }
      set {
        path = value;
      }
    }

    /// <summary>
    /// The name of the file.
    /// </summary>
    public string Name {
      get {
        if (String.IsNullOrEmpty(name) && String.IsNullOrEmpty(path) == false) {
          // Create the name
          name = path;
          if (name.Contains("/")) {
            name = name.Substring(name.LastIndexOf("/", StringComparison.Ordinal) + 1);
          }
          if (name.Contains("?")) {
            name = name.Substring(0, name.LastIndexOf("?", StringComparison.Ordinal));
          }
          if (name.Contains(".")) {
            name = name.Substring(0, name.LastIndexOf(".", StringComparison.Ordinal));
          }
        }
        return name;
      }
      set {
        name = value;
      }
    }

    /// <summary>
    /// The XML representation of the file.
    /// </summary>
    public XmlDocument Document {
      get {
        return document;
      }
      set {
        document = value;
      }
    }

    /// <summary>
    /// Gets a list of WSDL files from a delimited string.
    /// </summary>
    /// <param name="value">The files to load.</param>
    /// <returns>Returns a list of WSDL files from a delimited string.</returns>
    public static List<WsdlFile> FromString(string value) {
      return FromString(value, null, null);
    }

    /// <summary>
    /// Gets a list of WSDL files from a delimited string.
    /// </summary>
    /// <param name="value">The files to load.</param>
    /// <param name="username">The username to use for authentication.</param>
    /// <param name="password">The password to use for authentication.</param>
    /// <returns>Returns a list of WSDL files from a delimited string.</returns>
    public static List<WsdlFile> FromString(string value, string username, string password) {
      return FromString(value, username, password, null);
    }

    /// <summary>
    /// Gets a list of WSDL files from a delimited string.
    /// </summary>
    /// <param name="value">The files to load.</param>
    /// <param name="username">The username to use for authentication.</param>
    /// <param name="password">The password to use for authentication.</param>
    /// <param name="domain">The domain to use for authentication.</param>
    /// <returns>Returns a list of WSDL files from a delimited string.</returns>
    public static List<WsdlFile> FromString(string value, string username, string password, string domain) {
      var list = new List<WsdlFile>();
      foreach (string item in value.Split((";\n\t,|").ToCharArray())) {
        string path = item;
        path = path.Trim((" \r\n\t").ToCharArray());
        if (String.IsNullOrEmpty(path)) {
          continue;
        }
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
          if (wsdlDocument != null) {
            var file = new WsdlFile { Path = path, Document = wsdlDocument };
            ExpandImports(file.Document);
            list.Add(file);
          }
        }
      }
      return list;
    }

    /// <summary>
    /// Loads a URL string from a path.
    /// </summary>
    /// <param name="path">The path from which to load URLs.</param>
    /// <param name="username">The username to use for authentication.</param>
    /// <param name="password">The password to use for authentication.</param>
    /// <param name="domain">The domain to use for authentication.</param>
    /// <returns>Returns a URL string from the path or NULL if not found.</returns>
    public static string GetStringFromUrl(string path, string username, string password, string domain) {
      var client = new WebClient();
      if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
        var credential = new NetworkCredential(username, password, domain);
        client.Credentials = credential;
      }
      path = GetAbsoluteUrl(path);
      return client.DownloadString(path);
    }

    /// <summary>
    /// Gets the XML document from the specified URL path.
    /// </summary>
    /// <param name="path">The path where the XML document can be found.</param>
    /// <param name="username">The username to use for authentication.</param>
    /// <param name="password">The password to use for authentication.</param>
    /// <param name="domain">The domain to use for authentication.</param>
    /// <returns>Returns the XML document from the specified URL path.</returns>
    public static XmlDocument GetXmlDocumentFromUrl(string path, string username, string password, string domain) {
      var doc = new XmlDocument();
      var resolver = new XmlUrlResolver();
      if (String.IsNullOrEmpty(username) == false || String.IsNullOrEmpty(password) == false) {
        var credential = new NetworkCredential(username, password, domain);
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

    public static void ExpandImports(XmlDocument doc) {
      importedUris = new List<string>();
      expandImports(doc);
    }

    /// <summary>
    /// Expands the imports contained in the XML document.
    /// </summary>
    /// <param name="doc">The document in which imports are to be expanded.</param>
    private static void expandImports(XmlDocument doc) {
      bool continueExpanding = false;
      var nsmgr = new XmlNamespaceManager(doc.NameTable);
      nsmgr.AddNamespace("xsd", "http://www.w3.org/2001/XMLSchema");
      nsmgr.AddNamespace("wsdl", "http://schemas.xmlsoap.org/wsdl/");
      XmlNodeList schemaImports = doc.SelectNodes("//*/xsd:import", nsmgr);
      XmlNodeList wsdlImports = doc.SelectNodes("//*/wsdl:import", nsmgr);

      // Expand the schema imports
      foreach (XmlNode importNode in schemaImports) {
        XmlAttribute a = importNode.Attributes["schemaLocation"];
        if (a == null) {
          continue;
        }
        string location = a.Value;
        if (location == null || location.StartsWith("http://schemas.xmlsoap.org/") || importedUris.Contains(location)) {
          continue;
        }

        var importedDoc = new XmlDocument();
        importedDoc.Load(location);
        foreach (XmlNode node in importedDoc.DocumentElement.ChildNodes) {
          XmlNode clonedNode = doc.ImportNode(node, true);
          importNode.ParentNode.InsertAfter(clonedNode, importNode);
          continueExpanding = true;
        }
        importNode.ParentNode.RemoveChild(importNode);
        importedUris.Add(location);
      }

      // Expand the WSDL imports
      foreach (XmlNode importNode in wsdlImports) {
        XmlAttribute a = importNode.Attributes["location"];
        if (a == null) {
          continue;
        }
        string location = a.Value;
        if (location != null && importedUris.Contains(location) == false) {
          var importedDoc = new XmlDocument();
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

    /// <summary>
    /// Returns an absolute URL from a partial one.
    /// </summary>
    /// <param name="url">The URL to resolve to an absolute URL.</param>
    /// <returns>Returns an absolute URL from a partial one.</returns>
    public static string GetAbsoluteUrl(string url) {
      HttpContext context = HttpContext.Current;
      if (url.Contains("://")) {
        return url;
      }
      string svr = context.Request.Url.Scheme + "://" + context.Request.Url.Host;
      if (!context.Request.Url.IsDefaultPort) {
        svr += ":" + context.Request.Url.Port.ToString();
      }
      return svr + url;
    }
  }
}