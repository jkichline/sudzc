# Introduction

SudzC is a tool for generating proxy code from SOAP-based web service definition
files (WSDL). While it supports generating code in multiple languages, it's
focus is on Objective-C.

The original project (of which this repository is a fork of) has a website running their code, and can be used to generate source code: [http://sudzc.com](http://sudzc.com).

## Code Generation

### OS X

To generate code under OS X, use the PHP implementation of the XSLT converters. To use a web interface, point your local webserver to the `src/php` directory and open the `index.php` site.

You can also start the code generation from the command-line, calling `convert.php` directly.

```sh
$ php ./src/php/convert.php --help
You can use script with following switches:
 --help                  Displays this help.
 --debug                 show debug output
 --namespace  [param]    The namespace (prefix) to be used.
 --outputFile [param]    The name of the output zip file.
 --type       [param]    Code to generate: ObjCARCFiles, JavaScript, ActionScript
 --wsdl       [param]    List of WSDL files or WSDL URL.
 ```

### Windows

Use the Visual Studio solution located in `src/dotnet` to start a local webserver to trigger code generation.
   
---

You might find the
[`flatten-wsdl.py`](https://github.com/amaechler/FlatWSDL) script useful to
prepare your WSDL files. Documentation on how to use the generated code further
can then be found in the `Documentation/` directory which comes along with the
code.
