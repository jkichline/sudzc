<?php

  // Include assets
  $current_file_path = dirname(__FILE__);
  $assets_file_path = $current_file_path . DIRECTORY_SEPARATOR . 'assets';
  include($assets_file_path . DIRECTORY_SEPARATOR . 'includes' . DIRECTORY_SEPARATOR . 'settings.php');
  include($assets_file_path . DIRECTORY_SEPARATOR . 'includes' . DIRECTORY_SEPARATOR . 'logging.php');
  include($assets_file_path . DIRECTORY_SEPARATOR . 'includes' . DIRECTORY_SEPARATOR . 'hzip.php');

  include($assets_file_path . DIRECTORY_SEPARATOR . 'classes' . DIRECTORY_SEPARATOR . 'converter.class.php');

  date_default_timezone_set('UTC');

  class CLI
  {
    protected static $ACCEPTED = array(
        // switches
        0 => array(
            'help'   => 'Displays this help.',
            'debug'  => 'show debug output',
        ),
        // options
        1 => array(
            'namespace'   => 'The namespace (prefix) to be used.',
            'outputFile'  => 'The name of the output zip file.',
            'type'        => 'Code to generate: ObjCARCFiles, JavaScript, ActionScript',
            'wsdl'        => 'List of WSDL files or WSDL URL.'
        )
    );
    var $params = array();

    function __construct()
    {
      global $argc, $argv;

      // Parse params
      if ($argc > 1) {
        $paramSwitch = false;
        for ($i = 1; $i < $argc; $i++) {
          $arg      = $argv[$i];
          $isSwitch = preg_match('/^--/', $arg);

          if ($isSwitch) {
            $arg = preg_replace('/^--/', '', $arg);
          }

          if ($paramSwitch && $isSwitch) {
            LogError("[param] expected after '$paramSwitch' switch (" . self::$ACCEPTED[1][$paramSwitch] . ")");
          } else if (!$paramSwitch && !$isSwitch) {
            if (isset($GLOBALS['baseFilename']) and (!$GLOBALS['baseFilename'])) {
              $GLOBALS['baseFilename'] = $arg;
            } else {
              LogError("'$arg' is an invalid switch, use --help to display valid switches.");
            }
          } else if (!$paramSwitch && $isSwitch) {
            if (isset($this->params[$arg])) {
              LogError("'$arg' switch cannot occur more than once");
            }

            $this->params[$arg] = true;
            if (isset(self::$ACCEPTED[1][$arg])) {
              $paramSwitch = $arg;
            } else if (!isset(self::$ACCEPTED[0][$arg])) {
              LogError("there's no '$arg' switch, use --help to display all switches.");
            }
          }
          else if ($paramSwitch && !$isSwitch) {
            $this->params[$paramSwitch] = $arg;
            $paramSwitch = false;
          }
        }
      }

      // Final check
      foreach ($this->params as $k => $v) {
        if (isset(self::$ACCEPTED[1][$k]) && $v === true) {
          LogError("[param] expected after '$k' switch (" . self::$ACCEPTED[1][$k] . ")");
        }
      }
    }

    function getParam($name)
    {
      if (isset($this->params[$name])) {
        return $this->params[$name];
      } else {
        return "";
      }
    }

    function displayHelp()
    {
      LogInfo("You can use script with following switches:");
      foreach (self::$ACCEPTED[0] as $key => $value) {
        LogInfo(sprintf(" --%-22s%s", $key, $value));
      }

      foreach (self::$ACCEPTED[1] as $key => $value) {
        LogInfo(sprintf(" --%-10s%-12s%s", $key, " [param]", $value));
      }
    }
  }

  /**
   * Setup variables
   */
  $packageName = 'WS'; // The namespace to be used for the package, or package name for Javascript code
  $username = null;
  $password = null;
  $codeType = null; // The code type to generate. The value must match the main XSLT file in the src/ directory
  $outputDirectory = $tempDirectory. strftime("%F%T") . uniqid();  // The default temporary output directory
  $wsdls = null;  // List of WSDL files or WSDL URL

  // Initialize variables depending on command-line / web usage
  $php_type = php_sapi_name();
  if ($php_type == "cli") {
    // PHP script executed from command line
    $cli = new CLI();

    if ($cli->getParam('help')) {
      $cli->displayHelp();
      exit(0);
    }

    // Process command line options
    if ($cli->getParam('namespace')) {
      $packageName = $cli->getParam('namespace');
    }
    if ($cli->getParam('outputFile')) {
      $outputFile = $cli->getParam('outputFile');
    }
    if ($cli->getParam('type')) {
      $codeType = $cli->getParam('type');
    }
    if ($cli->getParam('wsdl')) {
      $wsdls = $cli->getParam('wsdl');
    }
  }
  else {
    // PHP script NOT executed from command line
    $packageName = null;
    if(isset($_REQUEST["shortns"])) {
      $packageName = $_REQUEST["shortns"];
    } else {
      $packageName = $_REQUEST["ns"];
    }

    if (isset($_REQUEST['username'])) {
      $username = $_REQUEST['username'];
    }
    if (isset($_REQUEST['password'])) {
      $password = $_REQUEST['password'];
    }

    if(isset($_REQUEST['type'])) {
      $codeType = $_REQUEST['type'];
    }

    // Add the WSDL to the converter
    if (isset($_REQUEST['wsdl']) && $_REQUEST['wsdl'] != "http://") {
      $wsdls = $_REQUEST['wsdl'];
    }

    // Add uploaded files
    foreach($_FILES as $name => $file) {
      if($file['size'] > 0) {
        if(strlen($wsdls) > 0) {
          $wsdls .= ";";
        }
        $wsdls .= $file['tmp_name'];
      }
    }
  }

  // Set the time limit to two minutes
  set_time_limit(360);

  // Default properties
  $mimeType = "application/zip";

  // Create the converter
  $converter = new Converter();

  if (!empty($username)) {
    $converter->Username($username);
  }
  if(!empty($password)) {
    $converter->Password($password);
  }

  $converter->Type($codeType);
  $converter->OutputDirectory($outputDirectory);
  $converter->WsdlPaths($wsdls);

  if (empty($codeType)) {
    displayError("A code type must be specified.");
    // NOTREACHED
  }

  // If we have no WSDL, just stop now
  if (count($converter->WsdlFiles()) == 0) {
    $error = "No WSDL files have been specified";
    if (count($converter->Errors()) > 0) {
      $error .= ": " . implode(", ", $converter->Errors());
    }

    displayError($error);
    // NOTREACHED
  }

  // Just output the WSDL if that is what is requested
  if ($mimeType == "input" && count($converter->WsdlFiles()) > 0) {
    header("Content-Type: text/xml");
    foreach($converter->WsdlFiles() as $file) {
      header("Content-Disposition: attachment;filename=\"". $file->Name() . ".wsdl\"");
      echo($file->Document->SaveXML());
      exit();
    }
  }

  // If we want to see text then return that
  if (strlen($mimeType) > 0 && $mimeType != "application/zip") {
    header("Content-Type: ". $mimeType);
    foreach($converter->WsdlFiles() as $file) {
      header("Content-Disposition: attachment;filename=\"". $file->Name() . ".sudzc\"");
      $result = $converter->ConvertToPackage($file);
      echo($result->SaveXML());
      exit();
    }
  }

  // Otherwise, save it as an archive
  try {
    $converter->CreateArchive($outputFile);
  } catch (Exception $ex) {
    displayError($ex->getMessage());
  }

  // Remove old ZIP files
  $converter->RemoveArchives(3600);
  exit();

  // Function to display an error
  function displayError($error) {
    if (php_sapi_name() == "cli") {
      echo($error."\n");
    } else {
      header("Location: /errors.php?message=". urlencode(str_replace("\n", " ", $error)));
    }

    exit();
  }
?>
