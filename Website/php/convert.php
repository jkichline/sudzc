<?php

	// Show all errors
//	error_reporting(E_ALL); 
//	ini_set( 'display_errors','1');

	// Set the time limit to two minutes
	set_time_limit(360);

	// Include files
	include($_SERVER['DOCUMENT_ROOT'] . '/assets/includes/settings.php');
	include($_SERVER['DOCUMENT_ROOT'] . '/assets/classes/converter.class.php');
	
	// Default properties
	$mimeType = "application/zip";
//	$mimeType = "text/plain";

	// Retrieve variables
	$packageName = null;
	if(isset($_REQUEST["shortns"])) {
		$packageName = $_REQUEST["shortns"];
	} else {
		$packageName = $_REQUEST["ns"];
	}
	
	// Create the converter
	$converter = new Converter();

	if(isset($_REQUEST['username'])) {
		$converter->Username($_REQUEST['username']);
	}
	if(isset($_REQUEST['password'])) {
		$converter->Password($_REQUEST['password']);
	}
	if(isset($_REQUEST['domain'])) {
		$converter->Domain($_REQUEST['domain']);
	}
	if(isset($_REQUEST['type'])) {
		$converter->Type($_REQUEST['type']);
	} else {
		$converter->Type("ObjCFiles");
	}
	
	// Set the output directory
	$converter->OutputDirectory($tempDirectory. date('YmdHis') . uniqid());

	// Add the WSDL to the converter
	$wsdls = "";
	if(isset($_REQUEST['wsdl']) && $_REQUEST['wsdl'] != "http://") {
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
   	
	// TODO: Should handle errors
    try {
	    $converter->WsdlPaths($wsdls);
    } catch(Exception $ex) {
        $error = $ex->getMessage();
        if(count($converter->Errors()) > 0) {
            $error .= ": ". implode(", ", $converter->Errors());
        }
        displayError($error);
    }
	
	// If we have no WSDL, just stop now
	if (count($converter->WsdlFiles()) == 0) {
		$error = "No WSDL files have been specified";
		if (count($converter->Errors()) > 0) {
			$error .= ": " . implode(", ", $converter->Errors());
		}
		displayError($error);
        exit();
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
        $converter->CreateArchive();
    } catch (Exception $ex) {
        displayError($ex->getMessage());
    }

    // Remove old ZIP files
    $converter->RemoveArchives(3600);
    exit();

	// Function to display an error
	function displayError($error) {
		header("Location: /errors.php?message=". urlencode(str_replace("\n", " ", $error)));
//		echo($error);
		exit();
	}

	echo("Loaded");
?>