<?php
// error_reporting(-1);
    /**
    * Class used to convert WSDL files into generated Objective-C code.
     * @property mixed OutputDirectory
     * @property mixed Type
     */

    class Converter {
		private $type = null;
		private $wsdlPaths = null;
		private $username = null;
		private $password = null;
		private $domain = null;
		private $errors = null;
		private $outputDirectory = null;
		private $wsdlFiles = null;

		// The type of code to generate.
		public function Type($value = "") {
			if(empty($value)) {
				return $this->type;
			} else {
				$this->type = $value;
			}
            return true;
		}


		// The paths to the WSDL files.
		public function WsdlPaths($value = "") {
			if(empty($value)) {
				return $this->wsdlPaths;
			} else {
				$this->wsdlPaths = $value;
			}
            return true;
		}

		// The username used to authenticate the retrieval of WSDL files.
		public function Username($value = "") {
			if(empty($value)) {
				return $this->username;
			} else {
				$this->username = $value;
			}
            return true;
		}

		// The password used to authenticate the retrieval of WSDL files.
		public function Password($value = "") {
			if(empty($value)) {
				return $this->password;
			} else {
				$this->password = $value;
			}
            return true;
		}

		// The domain used to authenticate the retrieval of WSDL files.
		public function Domain($value = "") {
			if(empty($value)) {
				return $this->domain;
			} else {
				$this->domain = $value;
			}
            return true;
		}

		// Returns a collection of errors encountered;
		public function Errors() {
			return $this->errors;
		}

		// The output directory of the conversion process.
		public function OutputDirectory($value = "") {
			if(empty($value)) {
				// Create the output directory if needed.
				if ($this->outputDirectory == null) {
					$this->outputDirectory = sys_get_temp_dir() ."/". uniqid() . ".sudzd";
					if(!file_exists($this->outputDirectory)) {
						mkdir($this->outputDirectory);
					}
				}
				return $this->outputDirectory;
			} else {
				$this->outputDirectory = $value;
			}
            return true;
		}

		/**
		* The WSDL files to process.
		*/
		public function WsdlFiles($value = "") {
			if(empty($value)) {
				if ($this->wsdlFiles == null && strlen($this->wsdlPaths) > 0) {
					$this->wsdlFiles = WsdlFile::FromString($this->wsdlPaths, $this->username, $this->password, $this->domain);
					if($this->wsdlFiles == null || $this->wsdlFiles == false) {
						if($this->errors == null) { $this->errors = array(); }
						array_push($this->errors, "Could not create WSDL");
					}
				}
				return $this->wsdlFiles;
			} else {
				$this->wsdlFiles = $value;
			}
            return true;
		}

		/**
		* Creates and archive of the generated code.
		* @param string $packageName The name of the package.
		* @return string The filepath pointing to the created ZIP file.
		*/
		public function CreateArchive($packageName = null) {
	
			// Convert the WSDLs
			$packages = $this->Convert();
			if (empty($packageName) && $packages != null && count($packages) > 0) {
				$packageName = $packages[0];
			}
	
			// Zip everything up
			$path =  $this->OutputDirectory() .".sudzc";
			createZip($this->OutputDirectory(), $path, true, $this->OutputDirectory());
	
			// Deliver the ZIP file to the browser
			header("Content-Type: application/zip");
			header("Content-Disposition: attachment;filename=\"". $packageName .".zip\"");
			echo file_get_contents($path);
	
			// Delete the output directory
//			system("rm -rf ". escapeshellarg($this->OutputDirectory()));
//			rmdir($this->OutputDirectory());
	
			// Return the ZIP file
			return $path;
		}

		/**
		* Removes old archives.
		* @param int $olderThan The time span in seconds used to determine which archives to be removed.
        * @return int Returns the number of archives removed.
		*/
		public function RemoveArchives($olderThan) {
			$removed = 0;
			$handle = opendir(dirname($this->OutputDirectory()));
			while($file = readdir($handle)) {
				if($file != "." && $file != "..") {
	                $path = $this->outputDirectory . "/" . $file;
	                $ext = substr($file, -6);
					if($ext == ".sudzc") {
	                    if ((time() - filemtime($path)) > $olderThan) {
	                        unlink($path);
	                        $removed++;
	                    }
	                } else if($ext == ".sudzd") {
	                	system("rm -rf ". escapeshellarg($path), $retval);
//                    rmdir($path);
	                }
	            }
			}
			return $removed;
		}

		/**
		* Converts the WSDL files to generated code in the output directory.
		* @param array $packages Outputs the list of packages.
		* @param array $classes Outputs the list of classes.
		* @return string Returns the path where the generated code is to be saved.
		*/
		public function Convert(&$packages = array(), &$classes = array()) {
	
			// Instantiate the WSDL directory
            $wsdlDirectory = $this->outputDirectory . "/WSDL";
            if(file_exists($wsdlDirectory) == false) {
                mkdir($wsdlDirectory, 0777, true);
            }
	
			// Save each WSDL file
            foreach($this->wsdlFiles as $wsdlFile) {
                $wsdlFile->Document()->save($wsdlDirectory . "/" . $wsdlFile->Name() . ".wsdl");
            }
	
			// Save each package files
			foreach ($this->ConvertToPackages() as $package) {
//				if($package) {
					$packageName = $this->SavePackageToDirectory($package, $this->OutputDirectory());
	                array_push($packages, $packageName);
	                $xpath = new DOMXPath($package);
		            $list = $xpath->query("/package/@class"); // TODO: Make sure we are using XPATH correctly
		            if($list->length > 0) {
	                    array_push($classes, $list->item(0)->nodeValue);
		            }
//		        }
			}
	
			// Create the index XML document
            $indexDocument = new DOMDocument();
            $indexRoot = $indexDocument->appendChild($indexDocument->createElement("index"));
			foreach ($classes as $className) {
                $classNode = $indexRoot->appendChild($indexDocument->createElement("class"));
                $classNode->appendChild($indexDocument->createTextNode($className));
            }
	
			// Process the index to the output directory.
			$this->SaveIndexToDirectory($indexDocument, $this->OutputDirectory());
	
			// Update the Xcode project file
			if (substr($this->Type(), 0, 4) == "ObjC") {
				$this->UpdateProjectFile($this->OutputDirectory());
			}
	
			// Return the output directory
			return $this->OutputDirectory();
		}

		/**
		* Converts all WSDL files to package XML documents.
		* @return mixed Returns a list of package XML documents.
		*/
		public function ConvertToPackages() {
            $list = array();
            foreach($this->WsdlFiles() as $file) {
                array_push($list, $this->ConvertToPackage($file));
            }
            return $list;
        }

        /**
         * Converts the WSDL file to package XML documents.
         * @param WsdlFile $file The file to convert into a package
         * @return mixed Returns a list of package XML documents.
         */
        public function ConvertToPackage($file) {
            $this->errors = array();
            $o = $this->Transform($file->Document());
            return $o;
		}

		/** Saves the index XML file to the directory.
		* @param DOMDocument $document The index XmlDocument to be saved.
		* @param string $directory The path where the generated code is saved.
		*/
		public function SaveIndexToDirectory($document, $directory) {
			$this->SavePackageToDirectory($this->Transform($document), $directory);
		}

		/** Transforms the XML document
		* @param DOMDocument $document the document to be transformed
		* @return DOMDocument Returns the resulting XmlDocument
		*/
		public function Transform($document) {
			global $_REQUEST;

			// Create the XSLT
			$xsl = $_SERVER['DOCUMENT_ROOT'] . '/assets/code/' . $this->Type() . '.xslt';
			$xslFile = new DOMDocument();
			$xslFile->load($xsl);
			$xslt = new XSLTProcessor();
			$xslt->importStylesheet($xslFile);

			// Loop through all params and add as arguments
			foreach($_REQUEST as $key => $value) {
				$xslt->setParameter('', $key, $value);
            }
            $result = $xslt->transformToDoc($document);
			return $result;
		}

		/** Creates a UUID for generating PBX files.
		* @param int $id The ID to convert.
		* @return string Returns the 24 character UUID.
		*/
		public function MakeUUID($id) {
			$code = intval(microtime(true) * 1000);
			$uuid = dechex($id) . dechex($code);
			$uuid = str_pad($uuid, 24, "0");
			return substr($uuid, 0, 24);
		}

		/**
		* Updates the project file with the new code files.
		* @param string $directory The directory containing the project files to update.
		*/
		public function UpdateProjectFile($directory) {
	
			// Setup the string builders
			$pbxBuildFile = "";
			$pbxFileReference = "";	
			$pbxGroupExamples = "";
			$pbxGroupGenerated = "";
			$pbxSourcesBuildPhase = "";
			$lookup = array();
	
			// Set up the ID
			$id = intval(microtime(true));
	
			// Create pointers to the directory
            $sourceDirectory = $directory . '/Source/';
			$examplesDirectory = $directory . '/Source/Examples/';
			$generatedDirectory = $directory . '/Source/Generated/';
			
			$handle = opendir($examplesDirectory); 
			if($handle) {
				while (false !== ($file = readdir($handle))){ 
					if(substr($file, 0, 1) != "." && $file != "SudzCExamples.xcodeproj") {
						$uuid = $this->MakeUUID($id);
						$type = "objc";
						if(substr($file, -2) === ".h") {
							$type = "h";
						}
						$pbxFileReference .= sprintf("		%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.%s; path = \"%s\"; sourceTree = \"<group>\"; };", $uuid, $file, $type, $file);
						$pbxFileReference .= "\n";
						$pbxGroupExamples .= sprintf("				%s /* %s */,", $uuid, $file);
						$pbxGroupExamples .= "\n";
						$lookup[$file] = $uuid;
						$id++;
					}
				}
			}
			closedir($handle);
	
			// Add generated files
			$handle = opendir($generatedDirectory); 
			if($handle) {
				while (false !== ($file = readdir($handle))){ 
					if($file != "." && $file != "..") {
						$uuid = $this->MakeUUID($id);
						$type = "objc";
						if (substr($file, -2) === ".h") { $type = "h"; }
						$pbxFileReference .= sprintf("		%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.%s; path = \"%s\"; sourceTree = \"<group>\"; };", $uuid, $file, $type, $file);
						$pbxFileReference .= "\n";
						$pbxGroupGenerated .= sprintf("				%s /* %s */,", $uuid, $file);
						$pbxGroupGenerated .= "\n";
						$lookup[$file] = $uuid;
						$id++;
					}
				}
				closedir($handle);
			}
	
			// Add the build files
			foreach ($lookup as $filename => $value) {
				$uuid = $this->MakeUUID($id);
				$pbxBuildFile .= sprintf("		%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };", $uuid, $filename, $value, $filename);
				$pbxBuildFile .= "\n";
				if (substr($filename, -2) === ".m") {
					$pbxSourcesBuildPhase .= sprintf("				%s /* %s in Sources */,", $uuid, $filename);
					$pbxSourcesBuildPhase .= "\n";
				}
				$id++;
			}
	
			// Update the variables in the file.
			$filename = $directory . "/Examples/SudzCExamples.xcodeproj/project.pbxproj";
			$contents = file_get_contents($filename);
	
			// Do the replacing
			$contents = str_replace("/***PBXBuildFile***/", $pbxBuildFile, $contents);
			$contents = str_replace("/***PBXFileReference***/", $pbxFileReference, $contents);
			$contents = str_replace("/***PBXGroupExamples***/", $pbxGroupExamples, $contents);
			$contents = str_replace("/***PBXGroupGenerated***/", $pbxGroupGenerated, $contents);
			$contents = str_replace("/***PBXSourcesBuildPhase***/", $pbxSourcesBuildPhase, $contents);

			// Save the file
			file_put_contents($filename, $contents);
		}
		
		public function MapPath($path) {
			return $_SERVER['DOCUMENT_ROOT'] . '/assets/code/' . $path;
		}

        /**
         * Saves the package XML file to the directory.
         * @param DOMDocument $document The DOMDocument to be saved.
         * @param string $directory The directory where the generated code is saved.
         * @throws Exception
         * @return string Returns the name of the package that was generated.
         */

		public function SavePackageToDirectory($document, $directory) {
	
			// Setup working variables
			$file = null;
			$source = null;
			$target = null;
			$packageName = null;
	
			// Get the package name to return
			try {
				$packageName = $document->documentElement->getAttribute("name");
			} catch (Exception $ex) {
				throw new Exception("Required attribute 'name' not encountered in the 'package' element");
			}
	
			// Review each child node and…
			foreach($document->documentElement->childNodes as $child) {
				switch (strtolower($child->localName)) {
	
					// If a folder is to be included, copy the whole folder
					case "folder":
						try {
							$source = $child->getAttribute("copy");
						} catch (Exception $ex) {
							throw new Exception("Required 'copy' attribute not encountered in the 'folder' element");
						}
						$sourceDirectory = $this->MapPath($source);
						if (file_exists($sourceDirectory) == false) {
							throw new Exception("The source folder '" . $source . "' does not exist.");
						}
						$target = basename($sourceDirectory);
						if ($child->getAttribute("as") != null) {
							$target = $child.getAttribute("as");
						}
						$this->copyDirectory($sourceDirectory, $directory . '/' . $target, true);
						break;
	
					// If an include, copy the file into the folder
					case "include":
						try {
							$source = $child.getAttribute("copy");
						} catch (Exception $ex) {
							throw new Exception("Required 'copy' attribute not encountered in the 'include' element");
						}
						$sourceFile = $this->MapPath($source);
						if (file_exists($sourceFile)) {
							throw new Exception("The source file '" . $sourceFile . "' does not exist.");
						}
						$target = basename($sourceFile);
						if ($child->getAttribute("as") != null) {
							$target = $child-getAttribute("as");
						}
						copy($sourceFile, $directory . "/" . $target);
						break;
	
					// If a file, write the contents into the folder
					case "file":
						$filename = null;
						try {
							$filename = $child->getAttribute("filename");
						} catch (Exception $ex) {
							throw new Exception("Required attribute 'filename' not encountered in the 'file' element");
						}
	
						$filePath = $directory . "/" . $filename;
						$dir = substr($filePath, 0, strlen($filePath) - strlen(basename($filePath)));
						if (file_exists($dir) == false) {
							mkdir($dir, 0777, true);
						}
						if($child->firstChild != null && $child->firstChild->nodeType == 1) {
							file_put_contents($filePath, $child->ownerDocument->saveXml($child->firstChild, LIBXML_NOEMPTYTAG));
						} else {
							file_put_contents($filePath, $child->textContent);
						}
						break;
				}
			}
			return $packageName;
		}

        /**
         * @static
         * @param $source string The source directory.
         * @param $destination string The destination directory.
         * @param $overwrite boolean Determines if the destination directory is overwritten.
         */
    	public function copyDirectory($source, $destination, $overwrite) {

            // Throw an error is the source directory does not exist
            if (file_exists($source) == false) {
                throw new Exception("Directory not found");
            }

            // Create the destination directory
            if (file_exists($destination) == false) {
                mkdir($destination, 0777, true);
            }

            if ($handle = opendir($source)) {
                while (false !== ($entry = readdir($handle))) {
                	if($entry != "." && $entry != "..") {
	                    $path = $source . '/' . $entry;
	                    if(is_dir($path)) {
	                        $newDirectory = $destination . '/' . $entry;
	                        $this->copyDirectory($path, $newDirectory, $overwrite);
	                    } else {
	                        $newPath = $destination . "/" . $entry;
	                        copy($path, $newPath);
	                    }
	                }
                }
            }
        }

        /**
         * @static Generates a package name.
         * @param $namespaceUri The URI of the namespace used to generate the name.
         * @return null|string Returns a package name.
         */
        public static function GetPackageName($namespaceUri) {
            if(is_array($namespaceUri)) {
                return implode("_", $namespaceUri);
            }

            if(strlen($namespaceUri) == 0) { return null; }
            $at = strpos($namespaceUri, "://");
            if($at > 0) {
                $namespaceUri = substr($namespaceUri, $at + 3) . "?";
            }
            $at = strpos($namespaceUri, "?");
            if ($at > 0) {
                $namespaceUri = substr($namespaceUri, $at);
            }

            // Replace special characters with a period
            $s = $namespaceUri;
            $s = str_replace("/", ".", $s);
            $s = str_replace("\\", ".", $s);
            $s = str_replace(":", ".", $s);
            $s = str_replace(";", ".", $s);

            // Split on period
            $p1 = explode(".", $s);
            return implode("_", $p1);
        }

    }

    /**
     * Defines a WSDL file to be processed.
     */
    class WsdlFile {

        /// <summary>
        /// The path to the file.
        /// </summary>
        private $path = null;

        /// <summary>
        /// The name of the file.
        /// </summary>
        private $name = null;

        /// <summary>
        /// The XML representation of the file.
        /// </summary>
        private $document = null;

        /**
         * @param null $value The value of the path
         * @return mixed The path to the file.
         */
        public function Path($value = null) {
            if($value == null) {
                return $this->path;
            } else {
                $this->path = $value;
            }
            return true;
        }

        /**
         * The name of the file.
         * @param string|null $value
         * @return bool|string The name of the file.
         */
        public function Name($value = null) {
            if($value == null) {
                if (strlen($this->name) == 0 && strlen($this->path) > 0) {
                    // Create the name
                    $this->name = $this->path;
                    if (contains($this->name, "/")) {
                        $this->name = substr($this->name, lastIndexOf($this->name, "/") + 1);
                    }
                    if (contains($this->name, "?")) {
                        $this->name = substr($this->name, 0, lastIndexOf($this->name, "?"));
                    }
                    if (contains($this->name, ".")) {
                        $this->name = substr($this->name, 0, lastIndexOf($this->name, "."));
                    }
                }
                return $this->name;
            } else {
                $this->name = $value;
            }
            return true;
        }

        /**
         * The XML representation of the file.
         * @param DOMDocument|null $value The XML representation of the file.
         * @return bool|DOMDocument The XML representation of the file.
         */
        public function Document($value = null) {
            if($value == null) {
                return $this->document;
            } else {
                $this->document = $value;
            }
            return true;
        }

        /**
         * @static Gets a list of WSDL files from a delimited string.
         * @param $value The files to load.
         * @param $username The username to use for authentication.
         * @param $password The password to use for authentication.
         * @param $domain The domain to use for authentication.
         * @return mixed Returns a list of WSDL files from a delimited string.
         */
        public static function FromString($value, $username = null, $password = null, $domain = null) {
            $list = array();

            foreach (preg_split("/[;\n\t,|]/", $value, -1, PREG_SPLIT_NO_EMPTY) as $item) {
                $path = $item;
                $path = trim($path, " \r\n\t");
                
                // If we have no path, just continue
                if (strlen($path) == 0) { continue; }

                // Load from the local file system
                if(strpos($path, "://") === false) {
		            $wsdlDocument = DOMDocument::load($path);
		            if(!$wsdlDocument) {
			            $wsdlDocument = null;
		            }
	            }
	            
	            // Otherwise, load from the web
	            else {
	                $wsdlDocument = WsdlFile::GetXmlDocumentFromUrl($path, $username, $password, $domain);
	                if ($wsdlDocument == null || contains($wsdlDocument->documentElement->nodeName, "definitions") == false) {
	                    $path .= "?WSDL";
	                    $wsdlDocument = WsdlFile::GetXmlDocumentFromUrl($path, $username, $password, $domain);
	                }
	            }

	            // Process import statements
                $imports = null;
                if ($wsdlDocument == null || contains($wsdlDocument->documentElement->nodeName, "definitions") == false) {
                    $wsdlDocument = null;
                    $imports = WsdlFile::GetStringFromUrl($item, $username, $password, $domain);
                }
                
                // If this is an import file, then process each in turn
                if (strlen($imports) > 0) {
                    foreach(WsdlFile::FromString($imports, $username, $password, $domain) as $file) {
                        array_push($list, $file);
                    }
                }
                
                // Otherwise, import the XML WSDL document
                else {
                    if($wsdlDocument != null) {
                        $file = new WsdlFile();
                        $file->Path($path);
                        $file->Document($wsdlDocument);
                        WsdlFile::ExpandImports($file->Document());
                        array_push($list, $file);
                    }
                }
            }
            return $list;
        }

        /**
         * @static Loads a URL string from a path.
         * @param $path The path from which to load URLs.
         * @param $username The username to use for authentication.
         * @param $password The password to use for authentication.
         * @param $domain The domain to use for authentication.
         * @return mixed Returns a URL string from the path or NULL if not found.
         */
        public static function GetStringFromUrl($path, $username = null, $password = null, $domain = null) {
        	$url = GetAbsoluteUrl($path);
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            if(strlen($username) > 0) {
                $up = $username . ":";
                if($password != null) {
                    $up .= $password;
                }
                curl_setopt($ch, CURLOPT_USERPWD, $up);
                curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
            }
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
            curl_setopt($ch, CURLOPT_VERBOSE, 1);
            $response = curl_exec($ch);
            curl_close($ch);
            return $response;
        }

        /**
         * @static Gets the XML document from the specified URL path.
         * @param $path The path where the XML document can be found.
         * @param $username The username to use for authentication.
         * @param $password The password to use for authentication.
         * @param $domain The domain to use for authentication.
         * @return DOMDocument Returns the XML document from the specified URL path.
         */
        public static function GetXmlDocumentFromUrl($path, $username = null, $password = null, $domain = null) {
            $doc = new DOMDocument();
            try {
	            $doc->loadXML(WsdlFile::GetStringFromUrl($path, $username, $password, $domain));
	        } catch(Exception $ex) {
		        $doc = null;
	        }
            return $doc;
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="doc">The document to expand imports into</param>

        static $importedUris = null;

        /**
         * @static Expand imports
         * @param $doc DOMDocument The XML document of the expanded imports
         */
        public static function ExpandImports($doc) {
            $importedUris = array();
            WsdlFile::_expandImports($doc);
        }

        /**
         * @static Expands the imports contained in the XML document.
         * @param $doc The document in which imports are to be expanded.
         */
        private static function _expandImports($doc) {
            global $importedUris;
            $continueExpanding = false;

            $xpath = new DOMXPath($doc);
            $xpath->registerNamespace("xsd", "http://www.w3.org/2001/XMLSchema");
            $xpath->registerNamespace("wsdl", "http://schemas.xmlsoap.org/wsdl/");

            $schemaImports = $xpath->query("//*/xsd:import");
            $wsdlImports = $xpath->query("//*/wsdl:import");
            if($importedUris == null) {
	            $importedUris = array();
            }

            // Expand the schema imports
            foreach ($schemaImports as $importNode) {
                $a = $importNode->attributes->getNamedItem("schemaLocation");
                if ($a != null) {
                    $location = $a->textContent;
                    if (startsWith($location, "http://schemas.xmlsoap.org/")) {
                        continue;
                    }
                    if ($location != null && in_array($location, $importedUris) == false) {
                        $importedDoc = WsdlFile::GetXmlDocumentFromUrl($location);
                        foreach($importedDoc->documentElement->childNodes as $node) {
                            $cloneNode = $doc->importNode($node, true);
                            $importNode->parentNode->insertBefore($cloneNode, $importNode);
                            $continueExpanding = true;
                        }
                        $importNode->parentNode->removeChild($importNode);
                        array_push($importedUris, $location);
                    }
                }
            }

            // Expand the WSDL imports
            foreach ($wsdlImports as $importNode) {
                $a = $importNode->attributes->getNamedItem("location");
                if ($a != null) {
                    $location = $a->textContent;
                    if ($location != null && in_array($location, $importedUris) == false) {
                        $importedDoc = WsdlFile::GetXmlDocumentFromUrl($location);
                        foreach ($importedDoc->documentElement->childNodes as $node) {
                            $clonedNode = $doc->importNode($node, true);
                            $importNode->parentNode->insertBefore($clonedNode, $importNode);
                            $continueExpanding = true;
                        }
                        $importNode->parentNode->removeChild($importNode);
                        array_push($importedUris, $location);
                    }
                }
            }

            // Recursively add nodes
            if ($continueExpanding) {
                WsdlFile::_expandImports($doc);
            }
        }
    }

    /**
    * Returns an absolute URL from a partial one.
    *
    * @param string $url The URL to resolve to an absolute URL.
    * @return string Returns an absolute URL from a partial one.
    */

    function GetAbsoluteUrl($url) {
        $result = "";
        if(strpos($url, "http") === false) {
            $result .= getDomain();
        }
        if(strpos($url, "/") == 0) {
            $result .= $_SERVER["REQUEST_URI"];
            $result = substr($result, 0, strrpos($result, "/") + 1);
        }
        $result .= $url;
        return $result;
    }
    
    /**
    * Returns a domain of the server
    *
    * @return string Returns the domain from a partial one.
    */
    
   	function getDomain() {
		$host = 'http';
		if(isset($_SERVER["HTTPS"]) && $_SERVER["HTTPS"] == "on") { $host .= "s"; }
		$host .= "://";
		if($_SERVER["SERVER_PORT"] != "80") {
			$host .= $_SERVER["SERVER_NAME"].":".$_SERVER["SERVER_PORT"];
		} else {
			$host .= $_SERVER["SERVER_NAME"];
		}
		return $host;
	}

    /**
    * Return a list of all files within a directory
    *
    * @param string $directory The directory to search
    * @param bool $recursive Go through child directories as well
    * @return array
    */
    function dirList($directory, $recursive = true) {
        // create an array to hold directory list
        $results = array();

        // create a handler for the directory
        $handler = opendir($directory);

        // keep going until all files in directory have been read
        while (false !== ($file = readdir($handler))) {
            // if $file isn't this directory or its parent, add it to the results array
            if ($file != '.' && $file != '..') {
                // if the file is a directory, add contents of that directory
                if(is_dir($directory."/".$file) && $recursive === true) {
                    $results[] = array($file => dirList($directory."/".$file));
                } else {
                    $results[] = $file;
                }
            }
        }

        // close the handler
        closedir($handler);

        // done!
        return $results;

    }

    /* creates a compressed zip file */    
    function flattenFilesInDirectory($source, &$paths) {
	    $handle = opendir($source);
		while($entry = readdir($handle)) {
			if($entry != "." && $entry != "..") {
				$path = $source . "/" . $entry;
				if(is_dir($path)) {
					flattenFilesInDirectory($path, $paths);
				} else {
					array_push($paths, $path);
				}
			}
		}
    }
    
    function createZip($files = array(), $destination = '', $overwrite = false, $baseDirectory = null) {

        //if the zip file already exists and overwrite is false, return false
        if(file_exists($destination) && !$overwrite) { return false; }

        // if files is a directory, then make the files the contents of the directory
        if(is_dir($files)) {
        	$paths = array();
        	flattenFilesInDirectory($files, $paths);
        	$files = $paths;
        }

        // vars
        $valid_files = array();
        // if files were passed in...
        if(is_array($files)) {
            // cycle through each file
            foreach($files as $file) {
	            // make sure the file exists
                if(file_exists($file)) {
                    $valid_files[] = $file;
                }
            }
        }

        // if we have good files...
        if(count($valid_files)) {
            // create the archive
            $zip = new ZipArchive();
            if($zip->open($destination, $overwrite ? ZIPARCHIVE::OVERWRITE : ZIPARCHIVE::CREATE) !== true) {
                return false;
            }

            // add the files
            foreach($valid_files as $file) {
                $zip->addFile($file, substr($file, strlen($baseDirectory)));
            }

            // close the zip -- done!
            $zip->close();

            // check to make sure the file exists
            return file_exists($destination);
        } else {
            return false;
        }

    }

    function lastIndexOf($haystack, $search) {
        $index = strpos(strrev($haystack), strrev($search));
        return strlen($haystack) - strlen($search) - $index;
    }

    function contains($haystack, $search) {
        if(strpos($haystack, $search) === false) {
            return false;
        }
        return true;
    }

    function startsWith($haystack, $search) {
        return (substr($haystack, 0, strlen($search)) == $search);
    }

    function endsWith($haystack, $search) {
        if(substr($haystack, strlen($search) * -1) == $search);
    }

?>