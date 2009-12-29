using System;
using System.Collections;
using System.IO;
using System.Text;
using System.Drawing;
using System.Web;
using System.Web.Services;
using System.Web.Services.Protocols;
using System.Collections.Generic;

/// <summary>
/// Summary description for Test
/// </summary>
[WebService(Namespace = "http://sudcz.com/webservice/test")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
// To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
// [System.Web.Script.Services.ScriptService]
public class TestService : System.Web.Services.WebService {

	public TestService() {
	}

	[WebMethod(Description="Creates a test object.")]
	public TestResult Create(int count, string name, string description) {
		TestResult result = new TestResult();
		result.Number = count;
		result.Name = name;
		result.Description = description;
		if(count > 0) {
			result.Headers = new List<string>();
			for(int i=0;i<count;i++) {
				result.Headers.Add("This is header "+ (i + 1).ToString());
			}
		}
		return result;
	}

	[WebMethod(Description = "Tests receiving byte arrays")]
	public byte[] GetData() {
		Image image = new Bitmap(this.Context.Server.MapPath("~/assets/images/icon.png"));
		MemoryStream ms = new MemoryStream();
		image.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
		return ms.ToArray();
	}

	[WebMethod(Description="Determines if the result was sent correctly.")]
	public bool Validate(TestResult result, int headerCount) {
		if (result == null) { return false; }
		if (result.Headers == null) { return false; }
		return (result.Headers.Count == headerCount);
	}

	[WebMethod(Description="Produces a list of test results.")]
	public List<TestResult> List(int numberOfItems) {
		List<TestResult> list = new List<TestResult>();
		for (int i = 1; i <= numberOfItems; i++) {
			list.Add(new TestResult(i));
		}
		return list;
	}

	[WebMethod(Description="Returns the list of strings back.")]
	public List<String> OutputList(List<String> list) {
		return list;
	}

	[WebMethod(Description="Outputs a byte value.")]
	public byte OutputByte() {
		return Convert.ToByte(true);
	}

	public class TestResult : TestResultBase {
		private int _number = 0;
		private string _name = null;
		private string _description = "";

		public TestResult() { }
		public TestResult(int headers) {
			this.Number = headers;
			this.Name = "Item #" + headers.ToString();
			if (headers > 0) {
				this.Headers = new List<string>();
				StringBuilder sb = new StringBuilder();
				sb.Append("Test ");
				for (int i = 1; i <= headers; i++) {
					this.Headers.Add("This is header " + i.ToString());
				}
				this.Description = sb.ToString();
			}
		}

		public int Number {
			get { return _number; }
			set { _number = value; }
		}

		public string Name {
			get { return _name; }
			set { _name = value; }
		}

		public string Description {
			get { return _description; }
			set { _description = value; }
		}
	}

	public class TestResultBase {
		private List<string> _headers = null;

		public List<string> Headers {
			get { return _headers; }
			set { _headers = value; }
		}
	}

}

