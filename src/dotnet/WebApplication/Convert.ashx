<%@ WebHandler Language="C#" Class="Convert" %>

using System;
using System.Collections.Generic;
using System.Web;
using System.Xml;

using ConvertLib;

public class Convert : IHttpHandler {
  public void ProcessRequest(HttpContext context) {
    // Setup Variables
    string mimeType = System.Configuration.ConfigurationManager.AppSettings["OutputMimetype"];

    // Set up the converter object
    Converter converter = new Converter {
      Username = context.Request["username"], 
      Password = context.Request["password"], 
      Domain = context.Request["domain"],
      Type = (String.IsNullOrEmpty(context.Request["type"])) ? "ObjCARCFiles" : context.Request["type"]
    };

    // Add the WSDLs to the converter
    if (String.IsNullOrEmpty(context.Request["wsdl"]) == false && context.Request["wsdl"] != "http://") {
      try {
        converter.WsdlPaths = context.Request["wsdl"];
      } catch (Exception ex) {
        string error = ex.Message;
        if (converter.Errors != null) {
          error += ": " + String.Join(", ", converter.Errors.ToArray());
        }
        _DisplayError(context, error);
        return;
      }
    } else {
      if (context.Request.Files.Count > 0 && context.Request.Files[0].ContentLength > 0) {
        converter.WsdlFiles = new List<WsdlFile>();

        foreach (object item in context.Request.Files) {
          HttpPostedFile postedFile = item as HttpPostedFile ?? context.Request.Files[item as string];
          if (postedFile == null || postedFile.ContentLength <= 0) {
            continue;
          }
            
          WsdlFile wsdlFile = new WsdlFile { Document = new XmlDocument() };
          wsdlFile.Document.Load(postedFile.InputStream);
          wsdlFile.Path = postedFile.FileName;

          converter.WsdlFiles.Add(wsdlFile);
        }
      }
    }

    // If we have no WSDL, just stop now
    if (converter.WsdlFiles == null || converter.WsdlFiles.Count == 0) {
      string error = "No WSDL files have been specified";
      if (converter.Errors != null && converter.Errors.Count > 0) {
        error += ": " + String.Join(", ", converter.Errors.ToArray());
      }
      _DisplayError(context, error);
    }

    // Just output the WSDL if that is what is requested
    if (converter.WsdlFiles != null && (mimeType == "input" && converter.WsdlFiles.Count > 0)) {
      context.Response.ContentType = "text/xml";
      context.Response.AddHeader("content-disposition", "attachment;filename=\"" + converter.WsdlFiles[0].Name + ".wsdl\"");
      converter.WsdlFiles[0].Document.Save(context.Response.OutputStream);
      context.Response.End();
      return;
    }

    // If we want to see text then return that
    if (String.IsNullOrEmpty(mimeType) == false) {
      context.Response.ContentType = mimeType;
      if (converter.WsdlFiles != null) {
        context.Response.AddHeader("content-disposition", "attachment;filename=\"" + converter.WsdlFiles[0].Name + ".sudzc\"");
        converter.ConvertToPackage(converter.WsdlFiles[0]).Save(context.Response.OutputStream);
      }
      context.Response.End();
      return;
    }

    // Otherwise, save it as an archive
    try {
      converter.CreateArchive(context);
    } catch (Exception ex) {
      _DisplayError(context, ex.Message);
    }

    // Remove old ZIP files
    converter.RemoveArchives(new TimeSpan(1, 0, 0));
  }

  private static void _DisplayError(HttpContext context, string message) {
    context.Response.Redirect("Errors.aspx?message=" + message.Replace("\n", " "), true);
  }

  public bool IsReusable {
    get {
      return true;
    }
  }
}